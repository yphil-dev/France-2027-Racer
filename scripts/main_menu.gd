extends Control

const TRACK_SCENES: Array[String] = [
	"res://scenes/tracks/paris.tscn",
	"res://scenes/tracks/marseille.tscn",
	"res://scenes/tracks/limoges.tscn",
	"res://scenes/tracks/lyon.tscn",
]

@onready var preview_viewport: SubViewport = $PreviewViewport
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
@onready var loading_labels: Array[Label] = [
	$TrackGrid/Paris/LoadingLabel,
	$TrackGrid/Marseille/LoadingLabel,
	$TrackGrid/Limoges/LoadingLabel,
	$TrackGrid/Lyon/LoadingLabel,
]

func _ready() -> void:
	for index in buttons.size():
		buttons[index].pressed.connect(_open_track.bind(TRACK_SCENES[index]))

	_generate_previews.call_deferred()

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

func _open_track(scene_path: String) -> void:
	for button in buttons:
		button.disabled = true

	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Could not open track scene %s: error %d" % [scene_path, error])
		for button in buttons:
			button.disabled = false
