class_name DriverRoster
extends RefCounted

const DRIVER_IDS: Array[String] = ["soral", "lepen", "glux", "melenchon"]

const PROFILES: Dictionary = {
	"soral": {
		"display_name": "A. Soral",
		"car_number": 0,
		"portrait": preload("res://sprites/Soral.jpg"),
		"car_color": Color(0, 0, 0, 1), # Pure Vibrant Black
	},
	"lepen": {
		"display_name": "M. Le Pen",
		"car_number": 1,
		"portrait": preload("res://sprites/Lepen.jpg"),
		"car_color": Color(0, 0.25, 1, 1), # Vivid Neon Blue
	},
	"glux": {
		"display_name": "A. Glucksman",
		"car_number": 2,
		"portrait": preload("res://sprites/Glux.jpg"),
		"car_color": Color(1, 0.078, 0.576, 1), # Hot Vibrant Pink
	},
	"melenchon": {
		"display_name": "JL. Mélenchon",
		"car_number": 3,
		"portrait": preload("res://sprites/Melenchon.jpg"),
		"car_color": Color(0.5, 0, 1, 1), # Saturated Royal Purple
	},
}

static func has_driver(driver_id: String) -> bool:
	return PROFILES.has(driver_id)

static func get_profile(driver_id: String) -> Dictionary:
	if PROFILES.has(driver_id):
		return PROFILES[driver_id]

	push_error("Unknown driver_id: %s" % driver_id)
	return {}
