class_name RaceGridSpawner
extends RefCounted

const PLAYER_CAR_SCENE: PackedScene = preload("res://scenes/player_car.tscn")
const CPU_CAR_SCENE: PackedScene = preload("res://scenes/cpu_car.tscn")

const PLAYER_SLOT := "GridSlot2"
const CPU_SLOTS: Array[String] = ["GridSlot1", "GridSlot3", "GridSlot4"]

static func spawn(track: Node3D, selected_driver_id: String) -> Node3D:
	if not DriverRoster.has_driver(selected_driver_id):
		push_error("Unknown selected driver %s; using Soral." % selected_driver_id)
		selected_driver_id = "soral"

	var existing_cars := track.get_node_or_null("CARS") as Node3D
	if existing_cars != null:
		push_error("%s already contains a CARS node." % track.name)
		return existing_cars

	var grid := track.get_node("START_GRID") as Node3D
	var cars := Node3D.new()
	cars.name = "CARS"
	track.add_child(cars)

	var player := PLAYER_CAR_SCENE.instantiate() as PlayerCar
	player.name = "PlayerCar"
	player.driver_id = selected_driver_id
	player.transform = _spawn_transform(track, grid.get_node(PLAYER_SLOT) as Marker3D)
	cars.add_child(player)

	var cpu_driver_ids: Array[String] = []
	for driver_id in DriverRoster.DRIVER_IDS:
		if driver_id != selected_driver_id:
			cpu_driver_ids.append(driver_id)

	for index in CPU_SLOTS.size():
		var cpu := CPU_CAR_SCENE.instantiate() as CpuCar
		cpu.name = "CpuCar%d" % (index + 1)
		cpu.driver_id = cpu_driver_ids[index]
		cpu.waypoint_generator_path = NodePath("../../PATH/WaypointGenerator")
		cpu.configure_behavior(CpuBehaviorRoster.BEHAVIOR_IDS[index])
		cpu.transform = _spawn_transform(
			track,
			grid.get_node(CPU_SLOTS[index]) as Marker3D
		)
		cars.add_child(cpu)

	return cars

static func _spawn_transform(track: Node3D, marker: Marker3D) -> Transform3D:
	return track.global_transform.affine_inverse() * marker.global_transform
