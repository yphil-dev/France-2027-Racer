extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print ("START!")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Add these variables at the top of your script if you haven't already
var _verification_count: int = 0
var _verified: bool = false

func _on_verif_body_entered(body: Node3D) -> void:
	# Ignore checking if we are already verified
	if _verified:
		return

	# Only count it if the entering object is actually our Vehicle class
	if body is VehicleSphere:
		_verification_count += 1
		print("Verification step: %d/3" % _verification_count)

		if _verification_count >= 2: _verified = true


func _on_finish_body_entered(body: Node3D) -> void:
	print ("Plop!")
	print(body.name)
	if body is VehicleSphere and _verified: body.race_completed()
