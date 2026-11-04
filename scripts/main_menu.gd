extends Control

const TRACK_SCENES: Array[String] = [
	"res://scenes/tracks/paris.tscn",
	"res://scenes/tracks/marseille.tscn",
	"res://scenes/tracks/limoges.tscn",
	"res://scenes/tracks/lyon.tscn",
]

const SELECTED_SCALE := Vector2(1.02, 1.02)
const NORMAL_SCALE := Vector2.ONE
const SELECTED_SHADE := Color(0, 0, 0, 0.04)
const NORMAL_SHADE := Color(0, 0, 0, 0.28)
const SELECTED_LABEL_COLOR := Color(1, 0.88, 0.2, 1)
const NORMAL_LABEL_COLOR := Color.WHITE

@onready var preview_viewport: SubViewport = $PreviewViewport
@onready var transition: ColorRect = $Transition
@onready var buttons: Array[Button] = [
	$TrackGrid/Paris,
	$TrackGrid/Marseille,
	$TrackGrid/Limoges,
	$TrackGrid/Lyon,
]
@onready var previews: Array[TextureRect] = [
	$TrackGrid/Paris/Preview,
	$TrackGrid/Marseille/Preview,
	$TrackGrid/Limoges/Preview,
	$TrackGrid/Lyon/Preview,
]
@onready var shades: Array[ColorRect] = [
	$TrackGrid/Paris/Shade,
	$TrackGrid/Marseille/Shade,
	$TrackGrid/Limoges/Shade,
	$TrackGrid/Lyon/Shade,
]
@onready var city_labels: Array[Label] = [
	$TrackGrid/Paris/CityLabel,
	$TrackGrid/Marseille/CityLabel,
	$TrackGrid/Limoges/CityLabel,
	$TrackGrid/Lyon/CityLabel,
]
@onready var loading_labels: Array[Label] = [
	$TrackGrid/Paris/LoadingLabel,
	$TrackGrid/Marseille/LoadingLabel,
	$TrackGrid/Limoges/LoadingLabel,
	$TrackGrid/Lyon/LoadingLabel,
]

var _button_tweens: Dictionary = {}
var _selected_index: int = 0
var _launching: bool = false

func _ready() -> void:
	for index in buttons.size():
		buttons[index].pressed.connect(_launch_track.bind(index))
		buttons[index].focus_entered.connect(_select_button.bind(index))
		buttons[index].mouse_entered.connect(_hover_button.bind(index))
		buttons[index].resized.connect(_update_button_pivot.bind(index))
		buttons[index].mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	_initialize_selection.call_deferred()
	_generate_previews.call_deferred()

func _initialize_selection() -> void:
	await get_tree().process_frame
	for index in buttons.size():
		_update_button_pivot(index)
	_select_button(0)
	buttons[0].grab_focus()

func _hover_button(index: int) -> void:
	if _launching:
		return
	buttons[index].grab_focus()

func _select_button(index: int) -> void:
	if _launching:
		return

	_selected_index = index
	for button_index in buttons.size():
		_animate_button(button_index, button_index == _selected_index)

func _animate_button(index: int, selected: bool) -> void:
	var previous_tween := _button_tweens.get(index) as Tween
	if previous_tween != null and previous_tween.is_valid():
		previous_tween.kill()

	var button := buttons[index]
	button.z_index = 1 if selected else 0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		button,
		"scale",
		SELECTED_SCALE if selected else NORMAL_SCALE,
		0.14
	)
	tween.tween_property(
		shades[index],
		"color",
		SELECTED_SHADE if selected else NORMAL_SHADE,
		0.14
	)
	tween.tween_property(
		city_labels[index],
		"modulate",
		SELECTED_LABEL_COLOR if selected else NORMAL_LABEL_COLOR,
		0.14
	)
	_button_tweens[index] = tween

func _update_button_pivot(index: int) -> void:
	buttons[index].pivot_offset = buttons[index].size * 0.5

func _generate_previews() -> void:
	await get_tree().process_frame
	if DisplayServer.get_name() == "headless":
		for label in loading_labels:
			label.text = "PREVIEW REQUIRES DISPLAY"
		return

	for index in TRACK_SCENES.size():
		await _capture_preview(TRACK_SCENES[index], previews[index], loading_labels[index])

func _capture_preview(
	scene_path: String,
	preview: TextureRect,
	loading_label: Label
) -> void:
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		loading_label.text = "PREVIEW UNAVAILABLE"
		return

	var track := packed_scene.instantiate()
	track.process_mode = Node.PROCESS_MODE_DISABLED

	var track_ui := track.get_node_or_null("UI") as CanvasLayer
	if track_ui != null:
		track_ui.hide()

	var waypoint_generator := track.get_node_or_null("PATH/WaypointGenerator")
	if waypoint_generator != null:
		waypoint_generator.set("show_debug_lines", false)

	preview_viewport.add_child(track)
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

	await get_tree().process_frame
	await get_tree().process_frame

	var image := preview_viewport.get_texture().get_image()
	if not image.is_empty():
		preview.texture = ImageTexture.create_from_image(image)
		loading_label.hide()
	else:
		loading_label.text = "PREVIEW UNAVAILABLE"

	preview_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	track.queue_free()
	await get_tree().process_frame

func _launch_track(index: int) -> void:
	if _launching:
		return

	_launching = true
	_selected_index = index
	for button in buttons:
		button.disabled = true

	loading_labels[index].text = "STARTING..."
	loading_labels[index].show()
	transition.mouse_filter = Control.MOUSE_FILTER_STOP

	var button := buttons[index]
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(button, "scale", Vector2(0.97, 0.97), 0.08)
	tween.tween_property(button, "scale", Vector2(1.04, 1.04), 0.1)
	tween.parallel().tween_property(transition, "color", Color.BLACK, 0.24)
	await tween.finished

	var scene_path := TRACK_SCENES[index]
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Could not open track scene %s: error %d" % [scene_path, error])
		_launching = false
		transition.color = Color(0, 0, 0, 0)
		transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
		loading_labels[index].hide()
		for menu_button in buttons:
			menu_button.disabled = false
		buttons[index].grab_focus()
