class_name PlayerCar
extends Vehicle

func get_control_input() -> Vector2:
	return Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("back", "forward")
	)
