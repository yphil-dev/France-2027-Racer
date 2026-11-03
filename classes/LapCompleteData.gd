extends Object

class_name LapCompleteData

var lapTime: float
var car: Vehicle

func _initp_car(p_car: Vehicle, lt : float) -> void:
	car = p_car
	lapTime = lt

func _to_string() -> String:
	return "LapCompleteData %s (%d) lap: %.2f" % [
		car.car_name, car.car_number, lapTime
	]
