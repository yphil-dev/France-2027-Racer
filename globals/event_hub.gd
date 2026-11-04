extends Node

signal onLapCompleted(info: LapCompleteData)

func emitOnLapCompleted(info: LapCompleteData) -> void:
	onLapCompleted.emit(info)
