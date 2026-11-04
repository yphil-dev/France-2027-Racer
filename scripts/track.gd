extends Node3D

@export var target_laps: int = 1

var _verified_by_car: Dictionary = {}
var _laps_by_car: Dictionary = {}
var _race_finished: bool = false
var _winner: VehicleSphere

func _ready() -> void:
	print("START! Target laps set to: ", target_laps)

func _on_verif_body_entered(body: Node3D) -> void:
	if _race_finished or not body is VehicleSphere:
		return

	var car := body as VehicleSphere
	if _verified_by_car.get(car, false):
		return

	_verified_by_car[car] = true
	print("Lap verification complete for %s! Head to the finish line." % car.car_name)

func _on_finish_body_entered(body: Node3D) -> void:
	if _race_finished or not body is VehicleSphere:
		return

	var car := body as VehicleSphere
	print("Finish entered by: ", car.car_name)

	if not _verified_by_car.get(car, false):
		print("%s passed the finish line, but the lap was not verified!" % car.car_name)
		return

	var laps_completed := int(_laps_by_car.get(car, 0)) + 1
	_laps_by_car[car] = laps_completed
	_verified_by_car[car] = false
	print("Lap completed by %s! Total laps: %d" % [car.car_name, laps_completed])

	car.lap_completed(laps_completed)

	if laps_completed >= target_laps:
		_race_finished = true
		_winner = car
		car.race_completed(laps_completed)
