class_name Vehicle extends Node3D

@export_category("Handling")
@export var max_forward_speed: float = 1.0
@export var max_reverse_speed: float = 0.5
@export var forward_acceleration: float = 6.0
@export var reverse_acceleration: float = 2.0
@export var braking: float = 8.0
@export var steering_strength: float = 4.0
@export var steering_response: float = 4.0
@export var minimum_steering_grip: float = 0.2
@export var drive_torque: float = 100.0
@export var air_input_decay: float = 2.0

@export_category("Driver")
@export var driver_id: String = "driver"
@export var driver_name: String = "Driver"
@export var car_number: int = 0
@export var portrait: Texture2D

@export_category("Appearance")
@export var car_color: Color = Color(1.0, 0.752941, 0.266667, 1.0)
@export var body_material: Material

@export_category("Race")
@export var driving_enabled: bool = false

# Nodes

# ─── KEY CHANGE: Explicitly typed as your new VehicleSphere class ───
@onready var sphere: VehicleSphere = $Sphere
@onready var raycast: RayCast3D = $Ground

# Vehicle elements

@onready var vehicle_model = $Container
@onready var vehicle_body = get_node_or_null("Container/Model/body")

# (Optional) wheels

@onready var wheel_fl = get_node_or_null("Container/Model/wheel-front-left")
@onready var wheel_fr = get_node_or_null("Container/Model/wheel-front-right")
@onready var wheel_bl = get_node_or_null("Container/Model/wheel-back-left")
@onready var wheel_br = get_node_or_null("Container/Model/wheel-back-right")

# Effects

@onready var trail_left = get_node_or_null("Container/TrailLeft")
@onready var trail_right = get_node_or_null("Container/TrailRight")

# Sounds

@onready var screech_sound: AudioStreamPlayer3D = $Container/ScreechSound
@onready var engine_sound: AudioStreamPlayer3D = $Container/EngineSound
@onready var impact_sound: AudioStreamPlayer3D = $Container/ImpactSound

# Verif

var _verification_count: int = 0
var _verified: bool = false

# Time


var input: Vector3
var normal: Vector3

var acceleration: float
var angular_speed: float
var linear_speed: float

var colliding: bool

var linear_velocity: Vector3
var prev_position: Vector3

var calculated_lean: float

# Public Functions

func get_vehicle_position() -> Vector3: return vehicle_model.global_position

func set_driving_enabled(enabled: bool) -> void:
	driving_enabled = enabled
	if not driving_enabled:
		input = Vector3.ZERO
		linear_speed = 0.0
		angular_speed = 0.0

# Functions

func _enter_tree() -> void:
	add_to_group("race_vehicles")

func _ready() -> void:
	sphere.car_name = driver_name
	sphere.car_number = car_number

	if vehicle_body is GeometryInstance3D and body_material != null:
		vehicle_body.material_override = body_material
		vehicle_body.set_instance_shader_parameter("car_color", car_color)

func _physics_process(delta):

	handle_input(delta)

	var direction = sign(linear_speed)
	if direction == 0: direction = sign(input.z) if abs(input.z) > 0.1 else 1

	var steering_grip = clamp(abs(linear_speed), minimum_steering_grip, 1.0)

	var target_angular = -input.x * steering_grip * steering_strength * direction
	angular_speed = lerp(angular_speed, target_angular, delta * steering_response)

	vehicle_model.rotate_y(angular_speed * delta)

	# Ground alignment

	if raycast.is_colliding():
		if !colliding:
			if vehicle_body != null: vehicle_body.position = Vector3(0, 0.1, 0) # Bounce
			input.z = 0

		normal = raycast.get_collision_normal()

		# Orient model to colliding normal

		if normal.dot(vehicle_model.global_basis.y) > 0.5:
			var xform = align_with_y(vehicle_model.global_transform, normal)
			vehicle_model.global_transform = vehicle_model.global_transform.interpolate_with(xform, 0.2).orthonormalized()

	colliding = raycast.is_colliding()

	var target_speed = input.z * (max_forward_speed if input.z >= 0.0 else max_reverse_speed)

	if (target_speed < 0 and linear_speed > 0.01):
		linear_speed = lerp(linear_speed, 0.0, delta * braking)
	else:
		if (target_speed < 0):
			linear_speed = lerp(linear_speed, target_speed, delta * reverse_acceleration)
		else:
			linear_speed = lerp(linear_speed, target_speed, delta * forward_acceleration)

	acceleration = lerpf(acceleration, linear_speed + (abs(sphere.angular_velocity.length() * linear_speed) / 100), delta * 1)

	# Match vehicle model to physics sphere

	vehicle_model.position = sphere.position - Vector3(0, 0.65, 0)
	raycast.position = sphere.position

	# Calculate vehicle model linear velocity

	linear_velocity = (vehicle_model.position - prev_position) / delta
	prev_position = vehicle_model.position

	effect_engine(delta)
	effect_body(delta)
	effect_wheels(delta)
	effect_trails()

# Override this in player/CPU subclasses to provide steering and throttle.
func get_control_input() -> Vector2:
	return Vector2.ZERO

# Apply controls when the vehicle is colliding with the ground.
func handle_input(delta):

	if not driving_enabled:
		input = Vector3.ZERO
		linear_speed = 0.0
		angular_speed = 0.0
		sphere.angular_velocity = Vector3.ZERO
		var locked_velocity := sphere.linear_velocity
		locked_velocity.x = 0.0
		locked_velocity.z = 0.0
		sphere.linear_velocity = locked_velocity
		return

	if raycast.is_colliding():
		var controls := get_control_input()
		input.x = controls.x
		input.z = controls.y
		sphere.angular_velocity += vehicle_model.get_global_transform().basis.x * (linear_speed * drive_torque) * delta
	else:
		# Gradually clear inputs in the air so physics calculation doesn't skyrocket
		input = input.lerp(Vector3.ZERO, delta * air_input_decay)

func effect_body(delta):

	calculated_lean = lerp_angle(calculated_lean, -input.x / 5 * linear_speed, delta * 5)

	# Slightly tilt (and move) body based on acceleration and steering

	if vehicle_body != null:

		vehicle_body.rotation.x = lerp_angle(vehicle_body.rotation.x, -(linear_speed - acceleration) / 6, delta * 10)
		vehicle_body.rotation.z = calculated_lean

		vehicle_body.position = vehicle_body.position.lerp(Vector3(0, 0.2, 0), delta * 5)

func effect_wheels(delta):

	# Rotate wheels based on acceleration

	for wheel in [wheel_fl, wheel_fr, wheel_bl, wheel_br]:
		if wheel != null:
			wheel.rotation.x += acceleration

	# Rotate front wheels based on steering direction

	if wheel_fl != null: wheel_fl.rotation.y = lerp_angle(wheel_fl.rotation.y, -input.x / 1.5, delta * 10)
	if wheel_fr != null: wheel_fr.rotation.y = lerp_angle(wheel_fr.rotation.y, -input.x / 1.5, delta * 10)

# Engine sounds

func effect_engine(delta):

	var speed_factor = clamp(abs(linear_speed), 0.0, 1.0)
	var throttle_factor = clamp(abs(input.z), 0.0, 1.0)

	var target_volume = remap(speed_factor + (throttle_factor * 0.5), 0.0, 1.5, -15.0, -5.0)
	engine_sound.volume_db = lerp(engine_sound.volume_db, target_volume, delta * 5.0)

	var target_pitch = remap(speed_factor, 0.0, 1.0, 0.5, 3)
	if throttle_factor > 0.1: target_pitch += 0.2

	engine_sound.pitch_scale = lerp(engine_sound.pitch_scale, target_pitch, delta * 2.0)

func effect_trails():
	if not raycast.is_colliding():
		# if trail_left != null: trail_left.emitting = false
		# if trail_right != null: trail_right.emitting = false
		screech_sound.volume_db = -80.0
		return

	var drift_intensity = abs(linear_speed - acceleration) + (abs(calculated_lean) * 2.0)
	var should_emit = drift_intensity > 0.25

	if trail_left != null: trail_left.emitting = should_emit
	if trail_right != null: trail_right.emitting = should_emit

	var target_volume = -80.0
	if should_emit: target_volume = remap(clamp(drift_intensity, 0.25, 2.0), 0.25, 2.0, -10.0, 0.0)

	screech_sound.pitch_scale = lerp(screech_sound.pitch_scale, clamp(abs(linear_speed), 1.0, 3.0), 0.1)
	screech_sound.volume_db = lerp(screech_sound.volume_db, target_volume, 10.0 * get_physics_process_delta_time())

# Align vehicle with normal

func align_with_y(xform, new_y):

	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform

# Detect collisions and play impact sound

func _on_sphere_body_entered(_body: Node) -> void:

	if vehicle_body == null: return

	if not impact_sound.playing:
		var impact_velocity := absf(linear_velocity.dot(vehicle_body.global_basis.z))
		impact_sound.volume_db = clampf(remap(impact_velocity, 0.0, 6.0, -20.0, 0.0), -20.0, 0.0)
		impact_sound.play()
