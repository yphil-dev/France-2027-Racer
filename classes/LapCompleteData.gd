extends Object

class_name LapCompleteData

var car: VehicleSphere
var lap_number: int
var lap_time: float
var race_time: float

func _init(
	p_car: VehicleSphere,
	p_lap_number: int,
	p_lap_time: float,
	p_race_time: float
) -> void:
	car = p_car
	lap_number = p_lap_number
	lap_time = p_lap_time
	race_time = p_race_time

func _to_string() -> String:
	return "%s (%d) lap %d: %.2f, race: %.2f" % [
		car.car_name,
		car.car_number,
		lap_number,
		lap_time,
		race_time,
	]
