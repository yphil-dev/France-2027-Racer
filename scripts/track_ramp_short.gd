class_name TrackRampShort
extends Node3D

@export_node_path("GridMap") var grid_map_path: NodePath
@export var source_ramp_cell: Vector3i = Vector3i(-2, 0, -2)
@export_range(0.1, 0.9, 0.01) var length_scale: float = 0.5
@export_range(0.0, 30.0, 0.5) var ramp_angle_degrees: float = 0.0

func _ready() -> void:
	var grid_map := get_node_or_null(grid_map_path) as GridMap
	if grid_map == null:
		push_error("%s requires a valid GridMap path." % get_path())
		return

	var source_item := grid_map.get_cell_item(source_ramp_cell)
	if source_item < 0:
		push_error("%s found no ramp at %s." % [get_path(), source_ramp_cell])
		return

	var library := grid_map.mesh_library
	var source_mesh := library.get_item_mesh(source_item)
	if source_mesh == null:
		push_error("%s could not load the source ramp mesh." % get_path())
		return

	var ramp_transform := library.get_item_mesh_transform(source_item)
	var ramp_length := source_mesh.get_aabb().size.z
	var short_length := ramp_length * length_scale
	var high_direction := signf(ramp_transform.basis.z.y)
	if is_zero_approx(high_direction):
		push_error("%s source ramp has no slope." % get_path())
		return

	var center_offset := high_direction * (ramp_length + short_length) * 0.5
	var extension_transform := ramp_transform
	extension_transform.origin += ramp_transform.basis.z * center_offset

	var cell_transform := Transform3D(
		grid_map.get_cell_item_basis(source_ramp_cell),
		grid_map.map_to_local(source_ramp_cell)
	)
	var base_global_transform := (
		grid_map.global_transform * cell_transform * extension_transform
	)
	global_transform = _apply_ramp_angle(
		base_global_transform,
		short_length
	)

	var short_mesh := _create_short_mesh(source_mesh)
	_add_visual(short_mesh)
	_add_collision(short_mesh)

func _apply_ramp_angle(
	base_transform: Transform3D,
	short_length: float
) -> Transform3D:
	if ramp_angle_degrees <= 0.0:
		return base_transform

	var high_sign := signf(base_transform.basis.z.y)
	var high_local := Vector3(0.0, 0.0, high_sign * short_length * 0.5)
	var low_local := -high_local
	var low_edge := base_transform * low_local
	var current_angle := asin(absf(base_transform.basis.z.normalized().y))
	var extra_angle := deg_to_rad(ramp_angle_degrees) - current_angle
	var best_transform := base_transform
	var best_high_y := -INF

	for direction in [-1.0, 1.0]:
		var candidate_basis := (
			base_transform.basis
			* Basis(Vector3.RIGHT, extra_angle * direction)
		)
		var candidate := Transform3D(
			candidate_basis,
			low_edge - candidate_basis * low_local
		)
		var high_edge := candidate * high_local
		if high_edge.y > best_high_y:
			best_high_y = high_edge.y
			best_transform = candidate

	return best_transform

func _create_short_mesh(source_mesh: Mesh) -> ArrayMesh:
	var result := ArrayMesh.new()
	result.resource_name = "track-ramp-short"

	for surface_index in source_mesh.get_surface_count():
		var arrays := source_mesh.surface_get_arrays(surface_index)
		var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		for vertex_index in vertices.size():
			vertices[vertex_index].z *= length_scale
		arrays[Mesh.ARRAY_VERTEX] = vertices
		result.add_surface_from_arrays(
			source_mesh.surface_get_primitive_type(surface_index),
			arrays
		)
		result.surface_set_material(
			result.get_surface_count() - 1,
			source_mesh.surface_get_material(surface_index)
		)

	return result

func _add_visual(short_mesh: ArrayMesh) -> void:
	var visual := MeshInstance3D.new()
	visual.name = "Ramp"
	visual.mesh = short_mesh
	add_child(visual)

func _add_collision(short_mesh: ArrayMesh) -> void:
	var body := StaticBody3D.new()
	body.name = "RampCollision"
	add_child(body)

	var collision := CollisionShape3D.new()
	collision.name = "Ramp"
	collision.shape = short_mesh.create_trimesh_shape()
	body.add_child(collision)
