extends Node

class_name RaceController

func _enter_tree() -> void:
	EventHub.onLapCompleted.connect(onLapCompleted)

func onLapCompleted(info: LapCompleteData) -> void:
	print("RaceController onLapCompleted:", info)
