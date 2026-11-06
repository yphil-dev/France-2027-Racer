extends Node

var selected_driver_id: String = "soral"
var selected_laps: int = 2
var night_enabled: bool = false

func select_driver(driver_id: String) -> void:
	if not DriverRoster.has_driver(driver_id):
		push_error("Cannot select unknown driver_id: %s" % driver_id)
		return

	selected_driver_id = driver_id
