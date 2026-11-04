extends Node

class_name RaceController

signal race_started
signal standings_updated(standings: Array)
signal car_finished(state: CarRaceState)
signal race_finished(standings: Array)

@export_range(0.1, 2.0, 0.1) var blink_interval: float = 0.5
@export_range(1.0, 60.0, 1.0) var classification_window: float = 15.0
@export_range(0.05, 1.0, 0.05) var standings_update_interval: float = 0.1
@export_node_path("RaceTrafficLight") var traffic_light_path: NodePath
@export_node_path("AudioStreamPlayer3D") var start_audio_path: NodePath

@onready var traffic_light: RaceTrafficLight = get_node(traffic_light_path)
@onready var start_audio: AudioStreamPlayer3D = get_node(start_audio_path)
@onready var cars: Node3D = get_node("../CARS")
@onready var game_ui: GameUI = get_node("../UI/GameUI")
@onready var track_path: Path3D = get_node("../PATH/TrackPath")
@onready var player_spawn: Marker3D = get_node("../START_GRID/PlayerSpawn")
@onready var race_track = get_parent()

var standings: Array[CarRaceState] = []
var race_elapsed: float = 0.0
var classification_time_remaining: float = 0.0

var _states_by_car: Dictionary = {}
var _winner: CarRaceState
var _race_running: bool = false
var _classification_active: bool = false
var _standings_accumulator: float = 0.0
var _path_length: float = 0.0
var _start_offset: float = 0.0
var _orange_enabled: bool = true
var _blink_timer: Timer

func _ready() -> void:
	race_track.connect("lap_completed", _on_track_lap_completed)
	race_track.connect("car_finished", _on_track_car_finished)

	await get_tree().process_frame
	_setup_race_states()
	game_ui.setup(self, standings)
	_set_vehicles_enabled(false)

	_blink_timer = Timer.new()
	_blink_timer.wait_time = blink_interval
	_blink_timer.timeout.connect(_toggle_orange)
	add_child(_blink_timer)

	_orange_enabled = true
	traffic_light.set_orange_enabled(_orange_enabled)
	_blink_timer.start()
	start_audio.play()

	await start_audio.finished

	_blink_timer.stop()
	traffic_light.show_start()
	_start_race()

func _process(delta: float) -> void:
	if not _race_running:
		return

	race_elapsed += delta
	for value in _states_by_car.values():
		var state := value as CarRaceState
		if not state.finished and not state.dnf:
			state.current_time = race_elapsed
			_update_state_progress(state)

	_standings_accumulator += delta
	if _standings_accumulator >= standings_update_interval:
		_standings_accumulator = 0.0
		_update_standings()

	if _classification_active:
		classification_time_remaining = maxf(0.0, classification_time_remaining - delta)
		if classification_time_remaining <= 0.0:
			_finalize_race()

func _setup_race_states() -> void:
	_states_by_car.clear()
	standings.clear()
	var target_laps := int(race_track.get("target_laps"))

	for child in cars.get_children():
		if child is Vehicle:
			var state := CarRaceState.new(child as Vehicle, target_laps)
			_states_by_car[state.car] = state
			standings.append(state)

	_path_length = track_path.curve.get_baked_length()
	_start_offset = track_path.curve.get_closest_offset(
		track_path.to_local(player_spawn.global_position)
	)
	_update_standings(true)

func _start_race() -> void:
	race_elapsed = 0.0
	classification_time_remaining = 0.0
	_classification_active = false
	_race_running = true
	_standings_accumulator = 0.0

	for state in standings:
		state.current_time = 0.0
		_update_state_progress(state)

	_update_standings(true)
	_set_vehicles_enabled(true)
	race_started.emit()
	print("Race started!")

func _on_track_lap_completed(car: VehicleSphere, lap_number: int) -> void:
	if not _race_running or not _states_by_car.has(car):
		return

	var state := _states_by_car[car] as CarRaceState
	state.record_lap(lap_number, race_elapsed)
	_update_state_progress(state)
	car.lap_completed(lap_number, state.last_lap_time, race_elapsed)
	_update_standings(true)

func _on_track_car_finished(car: VehicleSphere, lap_number: int) -> void:
	if not _race_running or not _states_by_car.has(car):
		return

	var state := _states_by_car[car] as CarRaceState
	if state.finished:
		return

	state.record_finish(race_elapsed)
	_update_state_progress(state)
	state.vehicle.set_driving_enabled(false)
	car.race_completed(lap_number, race_elapsed)
	car_finished.emit(state)

	if _winner == null:
		_winner = state
		state.winner = true
		_classification_active = true
		classification_time_remaining = classification_window
		print("Winner: %s. Classification closes in %.0f seconds." % [
			state.vehicle.driver_name,
			classification_window,
		])

	_update_standings(true)
	if _all_cars_finished():
		_finalize_race()

func _update_state_progress(state: CarRaceState) -> void:
	if _path_length <= 0.0:
		return

	var local_position := track_path.to_local(state.car.global_position)
	var curve_offset := track_path.curve.get_closest_offset(local_position)
	state.track_progress = fposmod(curve_offset - _start_offset, _path_length)
	state.total_progress = state.laps_completed * _path_length + state.track_progress

func _update_standings(force_emit: bool = false) -> void:
	standings.sort_custom(_is_state_ahead)
	for index in standings.size():
		standings[index].rank = index + 1

	if force_emit or _race_running:
		standings_updated.emit(standings.duplicate())

func _is_state_ahead(a: CarRaceState, b: CarRaceState) -> bool:
	if a.finished and b.finished:
		return a.finish_time < b.finish_time
	if a.finished != b.finished:
		return a.finished
	if a.dnf != b.dnf:
		return not a.dnf
	if a.laps_completed != b.laps_completed:
		return a.laps_completed > b.laps_completed
	return a.total_progress > b.total_progress

func _all_cars_finished() -> bool:
	for state in standings:
		if not state.finished:
			return false
	return true

func _finalize_race() -> void:
	if not _race_running:
		return

	_race_running = false
	_classification_active = false
	classification_time_remaining = 0.0

	for state in standings:
		if not state.finished:
			state.mark_dnf(race_elapsed)
		state.vehicle.set_driving_enabled(false)

	_update_standings(true)
	race_finished.emit(standings.duplicate())

func _toggle_orange() -> void:
	_orange_enabled = not _orange_enabled
	traffic_light.set_orange_enabled(_orange_enabled)

func _set_vehicles_enabled(enabled: bool) -> void:
	for node in get_tree().get_nodes_in_group("race_vehicles"):
		if node is Vehicle:
			node.set_driving_enabled(enabled)
