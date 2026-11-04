extends PanelContainer

class_name CarUI

@onready var accent: ColorRect = $Margin/HBox/Accent
@onready var portrait: TextureRect = $Margin/HBox/Portrait
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

func format_time(seconds: float) -> String:
	var safe_seconds := maxf(0.0, seconds)
	var minutes: int = int(safe_seconds / 60.0)
	var remaining := fmod(safe_seconds, 60.0)
	return "%02d:%05.2f" % [minutes, remaining]
