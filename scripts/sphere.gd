class_name VehicleSphere extends RigidBody3D

@export var max_angular_velocity: float = 50.0

# Car
@onready var car_name: String = "Soral"
@onready var car_number: int = 0

var _lap_time: float = 0.0

func _ready() -> void:
	# Ensure contact monitor is on if you still rely on _on_sphere_body_entered
	contact_monitor = true
	max_contacts_reported = 4

func _process(delta: float) -> void:
	_lap_time += delta

func race_completed(numLaps) -> void:
	print("Race completed! %s laps" % numLaps)

func lap_completed(numLap) -> void:
	var lcd: LapCompleteData = LapCompleteData.new(self, _lap_time)
	print("Lap %d completed!" % numLap)
	print("Lap completed! ", lcd)
	EventHub.emitOnLapCompleted(lcd)
