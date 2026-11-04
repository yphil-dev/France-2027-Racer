extends Control

class_name GameUI

@onready var list: VBoxContainer = $MarginContainer/VBoxContainer

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

	_on_standings_updated(initial_standings)

func _on_standings_updated(current_standings: Array) -> void:
	for index in current_standings.size():
		var state := current_standings[index] as CarRaceState
		var card := _cards_by_vehicle.get(state.vehicle) as CarUI
		if card == null:
			continue

		card.update_state(state)
		list.move_child(card, index)
