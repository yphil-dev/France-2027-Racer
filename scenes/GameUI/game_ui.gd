extends Control

class_name GameUI

@onready var live_container: MarginContainer = $MarginContainer
@onready var list: VBoxContainer = $MarginContainer/VBoxContainer

const RESULT_GAP: float = 4.0
const RESULT_TWEEN_DURATION: float = 0.8

var _cards_by_vehicle: Dictionary = {}

func setup(controller: RaceController, initial_standings: Array[CarRaceState]) -> void:
	_cards_by_vehicle.clear()

	var card_nodes := list.get_children()
	for index in initial_standings.size():
		if index >= card_nodes.size():
			break

		var state := initial_standings[index]
		var card := card_nodes[index] as CarUI
		card.setup(state)
		_cards_by_vehicle[state.vehicle] = card

	if not controller.standings_updated.is_connected(_on_standings_updated):
		controller.standings_updated.connect(_on_standings_updated)
	if not controller.race_finished.is_connected(_on_race_finished):
		controller.race_finished.connect(_on_race_finished)

	_on_standings_updated(initial_standings)

func _on_standings_updated(current_standings: Array) -> void:
	for index in current_standings.size():
		var state := current_standings[index] as CarRaceState
		var card := _cards_by_vehicle.get(state.vehicle) as CarUI
		if card == null:
			continue

		card.update_state(state)
		list.move_child(card, index)

func _on_race_finished(final_standings: Array) -> void:
	var quadrant_size := Vector2(
		(size.x - RESULT_GAP) * 0.5,
		(size.y - RESULT_GAP) * 0.5
	)

	for index in final_standings.size():
		var state := final_standings[index] as CarRaceState
		var card := _cards_by_vehicle.get(state.vehicle) as CarUI
		if card == null:
			continue

		var start_position: Vector2 = card.global_position - global_position
		var start_size := card.size
		var column := index % 2
		var row := int(index / 2)
		var target_position := Vector2(
			column * (quadrant_size.x + RESULT_GAP),
			row * (quadrant_size.y + RESULT_GAP)
		)

		card.update_state(state)
		card.reparent(self, false)
		card.position = start_position
		card.size = start_size
		card.show()

		var tween := card.create_tween()
		tween.set_trans(Tween.TRANS_QUART)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_parallel(true)
		tween.tween_property(card, "position", target_position, RESULT_TWEEN_DURATION)
		tween.tween_property(card, "size", quadrant_size, RESULT_TWEEN_DURATION)
		tween.chain().tween_callback(card.show_final_result)

	live_container.hide()
