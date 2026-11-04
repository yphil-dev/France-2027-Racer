extends PanelContainer

class_name CarUI

@onready var margin: MarginContainer = $Margin
@onready var hbox: HBoxContainer = $Margin/HBox
@onready var accent: ColorRect = $Margin/HBox/Accent
@onready var portrait: TextureRect = $Margin/HBox/Portrait
@onready var info: VBoxContainer = $Margin/HBox/Info
@onready var header: HBoxContainer = $Margin/HBox/Info/Header
@onready var rank_label: Label = $Margin/HBox/Info/Header/RankLabel
@onready var name_label: Label = $Margin/HBox/Info/Header/NameLabel
@onready var time_label: Label = $Margin/HBox/Info/TimeLabel
@onready var status_label: Label = $Margin/HBox/Info/StatusLabel
@onready var best_label: Label = $Margin/HBox/Info/BestLabel

var race_state: CarRaceState

func setup(state: CarRaceState) -> void:
	race_state = state
	portrait.texture = state.vehicle.portrait
	accent.color = state.vehicle.car_color
	name_label.text = state.vehicle.driver_name
	update_state(state)
	show()

func update_state(state: CarRaceState) -> void:
	race_state = state
	rank_label.text = "%d." % state.rank
	name_label.text = state.vehicle.driver_name
	accent.color = state.vehicle.car_color

	if state.dnf:
		time_label.text = "--:--.--"
		status_label.text = "DNF"
	elif state.finished:
		time_label.text = format_time(state.finish_time)
		status_label.text = "WINNER" if state.winner else "FINISHED"
	else:
		time_label.text = format_time(state.current_time)
		status_label.text = "Lap %d / %d" % [state.laps_completed, state.target_laps]

	best_label.text = (
		"Best: %s" % format_time(state.best_lap_time)
		if state.best_lap_time >= 0.0
		else "Best: --"
	)

func show_final_result() -> void:
	custom_minimum_size = Vector2.ZERO
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	hbox.add_theme_constant_override("separation", 16)
	accent.custom_minimum_size = Vector2(12, 0)
	portrait.custom_minimum_size = Vector2(220, 0)
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 8)
	header.add_theme_constant_override("separation", 8)

	rank_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_font_size_override("font_size", 34)
	time_label.add_theme_font_size_override("font_size", 40)
	status_label.add_theme_font_size_override("font_size", 24)
	best_label.add_theme_font_size_override("font_size", 20)

func format_time(seconds: float) -> String:
	var safe_seconds := maxf(0.0, seconds)
	var minutes: int = int(safe_seconds / 60.0)
	var remaining := fmod(safe_seconds, 60.0)
	return "%02d:%05.2f" % [minutes, remaining]
