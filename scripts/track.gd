extends Node3D

@export var target_laps: int = 1

var _verification_count: int = 0
var _verified: bool = false
var _laps_completed: int = 0

func _ready() -> void:
	print("START! Target laps set to: ", target_laps)

func _on_verif_body_entered(body: Node3D) -> void:
	if _verified:
		return

	if body is VehicleSphere:
		_verification_count += 1
		print("Verification step: %d/1" % _verification_count)

		# CHANGED TO 1: Validates instantly after passing your single checkpoint
		if _verification_count >= 1:
			_verified = true
			print("Lap verification complete! Head to the finish line.")

func _on_finish_body_entered(body: Node3D) -> void:
	if body is VehicleSphere:
		print("Finish entered by: ", body.name)

		if _verified:
			_laps_completed += 1
			print("Lap completed! Total laps: %d" % _laps_completed)

			body.lap_completed(_laps_completed)

			# Check for immediate race completion
			if _laps_completed >= target_laps:
				body.race_completed(_laps_completed)

			# Reset tracking variables ONLY if you decide to increase target_laps later
			_verification_count = 0
			_verified = false
		else:
			print("Passed finish line, but lap not verified yet!")
