class_name TrackCrossing
extends Node3D

@export_node_path("GridMap") var grid_map_path: NodePath
@export var source_cell: Vector3i = Vector3i(-1, 0, -2)
@export_range(0.1, 2.0, 0.05) var end_guardrail_length: float = 1.0
@export_range(-1.0, -0.01, 0.01) var lowered_wall_top: float = -0.2

const WALL_VERTEX_MIN_HEIGHT: float = 0.11
const TILE_HALF_LENGTH: float = 5.0
const GUARDRAIL_X: float = 4.75
const GUARDRAIL_WIDTH: float = 0.4
const GUARDRAIL_HEIGHT: float = 0.75

func _ready() -> void:
	var grid_map := get_node_or_null(grid_map_path) as GridMap
	if grid_map == null:
		push_error("%s requires a valid GridMap path." % get_path())
		return

	var source_item := grid_map.get_cell_item(source_cell)
	if source_item < 0:
		push_error("%s found no GridMap item at %s." % [get_path(), source_cell])
		return

	var source_mesh := grid_map.mesh_library.get_item_mesh(source_item)
	if source_mesh == null:
		push_error("%s could not load the source tile mesh." % get_path())
		return

	var cell_transform := Transform3D(
		grid_map.get_cell_item_basis(source_cell),
		grid_map.map_to_local(source_cell)
	)
	global_transform = grid_map.global_transform * cell_transform
	grid_map.set_cell_item(source_cell, GridMap.INVALID_CELL_ITEM)

	var crossing_mesh := _create_crossing_mesh(source_mesh)
	_add_road(crossing_mesh)
	_add_end_guardrails()

func _create_crossing_mesh(source_mesh: Mesh) -> ArrayMesh:
	var result := ArrayMesh.new()
	result.resource_name = "track-crossing"

	for surface_index in source_mesh.get_surface_count():
		var arrays := source_mesh.surface_get_arrays(surface_index)
		var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		for vertex_index in vertices.size():
			if vertices[vertex_index].y > WALL_VERTEX_MIN_HEIGHT:
				vertices[vertex_index].y = lowered_wall_top
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

func _add_road(crossing_mesh: ArrayMesh) -> void:
	var road_visual := MeshInstance3D.new()
	road_visual.name = "Road"
	road_visual.mesh = crossing_mesh
	add_child(road_visual)

	var road_body := StaticBody3D.new()
	road_body.name = "RoadCollision"
	add_child(road_body)

	var road_collision := CollisionShape3D.new()
	road_collision.name = "Road"
	road_collision.shape = crossing_mesh.create_trimesh_shape()
	road_body.add_child(road_collision)

func _add_end_guardrails() -> void:
	var guardrail_material := StandardMaterial3D.new()
	guardrail_material.albedo_color = Color(0.92, 0.94, 0.97, 1.0)
	guardrail_material.roughness = 0.72

	var guardrail_body := StaticBody3D.new()
	guardrail_body.name = "GuardrailCollision"
	add_child(guardrail_body)

	var end_center := TILE_HALF_LENGTH - end_guardrail_length * 0.5
	for side in [-1.0, 1.0]:
		for end in [-1.0, 1.0]:
			var position := Vector3(
				GUARDRAIL_X * side,
				GUARDRAIL_HEIGHT * 0.5,
				end_center * end
			)

			var mesh := BoxMesh.new()
			mesh.size = Vector3(
				GUARDRAIL_WIDTH,
				GUARDRAIL_HEIGHT,
				end_guardrail_length
			)
			mesh.material = guardrail_material

			var visual := MeshInstance3D.new()
			visual.name = "Guardrail_%s_%s" % [
				"Left" if side < 0.0 else "Right",
				"Start" if end < 0.0 else "End"
			]
			visual.position = position
			visual.mesh = mesh
			add_child(visual)

			var shape := BoxShape3D.new()
			shape.size = mesh.size

			var collision := CollisionShape3D.new()
			collision.name = visual.name
			collision.position = position
			collision.shape = shape
			guardrail_body.add_child(collision)
