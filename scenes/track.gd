extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print ("START!")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_verif_body_entered(body: Node3D) -> void:
	print ("Ploop!")
	print(body.name)


func _on_finish_body_entered(body: Node3D) -> void:
	print ("Plop!")
	print(body.name)
	if body is VehicleSphere: body.lap_completed()
	
