class_name TrackWaypoint
extends RefCounted

var index: int
var distance: float
var center: Vector3
var forward: Vector3
var left_edge: Vector3
var right_edge: Vector3
var left_valid: bool
var right_valid: bool

func is_valid() -> bool:
	return left_valid and right_valid

func get_lane_point(lane_offset: float) -> Vector3:
	var weight := clampf((lane_offset + 1.0) * 0.5, 0.0, 1.0)
	return left_edge.lerp(right_edge, weight)
