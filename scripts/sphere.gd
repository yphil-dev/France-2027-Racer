class_name VehicleSphere extends RigidBody3D

## You can add helper variables or custom tuning properties here later
@export var max_angular_velocity: float = 50.0

func _ready() -> void:
	# Ensure contact monitor is on if you still rely on _on_sphere_body_entered
	contact_monitor = true
	max_contacts_reported = 4


func lap_completed() -> void:
	print("Lap completed!")
