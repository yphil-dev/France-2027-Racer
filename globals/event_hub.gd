extends Node

signal onLapCompleted(info: LapCompleteData)

func emitOnLapCompleted(info: LapCompleteData) -> void:
	print("ZOOB")
	onLapCompleted.emit(info)
