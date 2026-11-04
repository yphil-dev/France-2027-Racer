class_name CpuCar
extends Vehicle

@export_category("CPU Driving")
@export_node_path("AIWaypointGenerator") var waypoint_generator_path: NodePath = ^"../PATH/WaypointGenerator"
@export_range(1, 10, 1) var waypoint_look_ahead: int = 2
@export_range(-1.0, 1.0, 0.05) var lane_offset: float = 0.0
@export_range(0.1, 5.0, 0.05) var cpu_steering_gain: float = 1.5
@export_range(0.0, 1.0, 0.05) var cruise_throttle: float = 0.85
@export_range(0.0, 1.0, 0.05) var corner_throttle: float = 0.5
@export_range(0.1, 3.14, 0.05) var full_corner_angle: float = 0.8

var waypoint_generator: AIWaypointGenerator
var _current_waypoint_index: int = -1
var _can_drive: bool = false

func _ready() -> void:
	super._ready()

	waypoint_generator = get_node_or_null(waypoint_generator_path) as AIWaypointGenerator
	if waypoint_generator == null:
		push_error("%s cannot find its AIWaypointGenerator at %s." % [name, waypoint_generator_path])
		return

	if not waypoint_generator.is_ready:
		await waypoint_generator.waypoints_ready

	if waypoint_generator.waypoints.is_empty():
		push_error("%s cannot drive because no AI waypoints were generated." % name)
		return

	_current_waypoint_index = _find_nearest_waypoint()
	_can_drive = true
	print("CPU car %s ready at waypoint %d" % [sphere.car_name, _current_waypoint_index])

func get_control_input() -> Vector2:
	if not _can_drive:
		return Vector2.ZERO

	_advance_waypoint()

	var waypoint_count := waypoint_generator.waypoints.size()
	var target_index := (_current_waypoint_index + waypoint_look_ahead) % waypoint_count
	var target := waypoint_generator.waypoints[target_index].get_lane_point(lane_offset)

	var target_direction := target - sphere.global_position
	target_direction.y = 0.0
	if target_direction.length_squared() <= 0.0001:
		return Vector2(0.0, corner_throttle)
	target_direction = target_direction.normalized()

	var current_forward: Vector3 = vehicle_model.global_basis.z
	current_forward.y = 0.0
	current_forward = current_forward.normalized()

	var angle: float = current_forward.signed_angle_to(target_direction, Vector3.UP)
	var steering := clampf(-angle * cpu_steering_gain, -1.0, 1.0)
	var corner_amount := clampf(absf(angle) / full_corner_angle, 0.0, 1.0)
	var throttle := lerpf(cruise_throttle, corner_throttle, corner_amount)

	return Vector2(steering, throttle)

func _find_nearest_waypoint() -> int:
	var nearest_index := 0
	var nearest_distance := INF

	for index in waypoint_generator.waypoints.size():
		var distance := sphere.global_position.distance_squared_to(
			waypoint_generator.waypoints[index].center
		)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = index

	return nearest_index

func _advance_waypoint() -> void:
	var waypoint_count := waypoint_generator.waypoints.size()

	for step in waypoint_count:
		var next_index := (_current_waypoint_index + 1) % waypoint_count
		var current_distance := sphere.global_position.distance_squared_to(
			waypoint_generator.waypoints[_current_waypoint_index].center
		)
		var next_distance := sphere.global_position.distance_squared_to(
			waypoint_generator.waypoints[next_index].center
		)

		if next_distance >= current_distance:
			break

		_current_waypoint_index = next_index
