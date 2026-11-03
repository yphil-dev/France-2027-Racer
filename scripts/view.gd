extends Node3D

@export_group("Properties")
@export var target: Vehicle

@export_group("Camera Zoom")
## Final distance to pull back to. Zoom stops here forever.
@export var max_zoom: float = 30.0
## How fast to ease outward.
@export var zoom_speed: float = 8.0

@export_group("Camera Turn")
## Degrees to rotate around Y while zooming out. 0 = don't turn.
## Negative = turn left, positive = turn right.
@export var turn_degrees: float = 15.0

@onready var camera = $Camera

var _zoomed_out := false
var _start_z: float
var _start_yaw: float
var _target_yaw: float

func _ready() -> void:
	_start_z = camera.position.z
	_start_yaw = rotation.y
	_target_yaw = _start_yaw + deg_to_rad(turn_degrees)

func _physics_process(delta):
	# Zoom out exactly once, fast, then hard-stop at max_zoom.
	# The rig NEVER pans. Only camera.position.z and rotation.y are touched, once.
	if not _zoomed_out:
		camera.position.z = move_toward(camera.position.z, max_zoom, zoom_speed * delta)

		# Rotate on Y in lockstep with zoom progress.
		var t: float = clamp(inverse_lerp(_start_z, max_zoom, camera.position.z), 0.0, 1.0)
		rotation.y = lerp(_start_yaw, _target_yaw, t)

		if camera.position.z >= max_zoom:
			camera.position.z = max_zoom
			rotation.y = _target_yaw
			_zoomed_out = true
