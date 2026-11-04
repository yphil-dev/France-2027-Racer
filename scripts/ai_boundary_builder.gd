class_name AIBoundaryBuilder
extends Node3D

signal boundaries_ready

const AI_BOUNDARY_LAYER: int = 1 << 4

@export_range(0.1, 10.0, 0.1, "or_greater") var segment_spacing: float = 1.0
@export_range(0.01, 2.0, 0.01, "or_greater") var wall_thickness: float = 0.15
@export_range(0.1, 10.0, 0.1, "or_greater") var wall_height: float = 1.0

@onready var interior_wall: Path3D = $InteriorWall
@onready var exterior_wall: Path3D = $ExteriorWall

var is_ready: bool = false
var segment_count: int = 0

func _ready() -> void:
	segment_count = _build_wall(interior_wall, "GeneratedInteriorWall")
	segment_count += _build_wall(exterior_wall, "GeneratedExteriorWall")

	await get_tree().physics_frame
	is_ready = true
	boundaries_ready.emit()
	print("AI boundaries ready: %d segments" % segment_count)

func _build_wall(path: Path3D, wall_name: String) -> int:
	var curve := path.curve
	if curve == null or curve.point_count < 2:
		push_error("%s requires a Curve3D with at least two points." % path.get_path())
		return 0

	var curve_length := curve.get_baked_length()
	if curve_length <= 0.0:
		push_error("%s has no baked length." % path.get_path())
		return 0

	var sample_count := maxi(3, ceili(curve_length / segment_spacing))
	var points: Array[Vector3] = []
	points.resize(sample_count)

	for index in sample_count:
		var distance := curve_length * float(index) / float(sample_count)
		var path_point := curve.sample_baked(distance, true)
		points[index] = to_local(path.to_global(path_point))

	var body := StaticBody3D.new()
	body.name = wall_name
	body.collision_layer = AI_BOUNDARY_LAYER
	body.collision_mask = 0
	add_child(body)

	for index in sample_count:
		var start := points[index]
		var end := points[(index + 1) % sample_count]
		_add_segment(body, start, end, index)

	return sample_count

func _add_segment(body: StaticBody3D, start: Vector3, end: Vector3, index: int) -> void:
	var segment := end - start
	var length := segment.length()
	if length <= 0.001:
		return

	var forward := segment / length
	var right := Vector3.UP.cross(forward)
	if right.length_squared() <= 0.0001:
		right = Vector3.RIGHT
	else:
		right = right.normalized()
	var up := forward.cross(right).normalized()

	var shape := BoxShape3D.new()
	shape.size = Vector3(wall_thickness, wall_height, length + wall_thickness)

	var collision := CollisionShape3D.new()
	collision.name = "Segment%04d" % index
	collision.shape = shape
	collision.transform = Transform3D(
		Basis(right, up, forward),
		(start + end) * 0.5
	)
	body.add_child(collision)
