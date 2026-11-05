class_name RaceTrafficLight
extends Node3D

@onready var green_light: MeshInstance3D = $GreenLight
@onready var orange_light: MeshInstance3D = $OrangeLight
@onready var red_light: MeshInstance3D = $RedLight

func _ready() -> void:
	show_off()

func show_off() -> void:
	green_light.visible = false
	orange_light.visible = false
	red_light.visible = false

func set_orange_enabled(enabled: bool) -> void:
	green_light.visible = false
	orange_light.visible = enabled
	red_light.visible = false

func show_start() -> void:
	green_light.visible = true
	orange_light.visible = false
	red_light.visible = false

func set_red_enabled(enabled: bool) -> void:
	green_light.visible = false
	orange_light.visible = false
	red_light.visible = enabled
