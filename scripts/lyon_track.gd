extends "res://scripts/track.gd"

enum TimeOfDay { DAY, NIGHT }

@export var time_of_day: TimeOfDay = TimeOfDay.NIGHT

func _ready() -> void:
	super._ready()
	if time_of_day == TimeOfDay.NIGHT:
		_apply_night_lighting()

func _apply_night_lighting() -> void:
	var world_environment := get_node("Environment") as WorldEnvironment
	var night_environment := world_environment.environment.duplicate() as Environment
	night_environment.background_mode = Environment.BG_COLOR
	night_environment.background_color = Color(0.012, 0.014, 0.02)
	night_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	night_environment.ambient_light_color = Color(0.36, 0.37, 0.40)
	night_environment.ambient_light_energy = 0.22
	world_environment.environment = night_environment

	var moonlight := get_node("Sun") as DirectionalLight3D
	moonlight.light_color = Color(0.82, 0.84, 0.9)
	moonlight.light_energy = 0.18
