extends Node

@onready var player: AudioStreamPlayer2D = $AudioStreamPlayer2D


const SILENT_DB: float = -80.0
const TARGET_DB: float = -12.0  # adjust to taste

var _fade_tween: Tween

func _ready() -> void:
	player.volume_db = SILENT_DB

func fade_in(duration: float = 0.2) -> void:
	_kill_fade()
	if not player.playing:
		player.play()
	_fade_tween = create_tween()
	_fade_tween.tween_property(player, "volume_db", TARGET_DB, duration)

func fade_out_and_stop(duration: float = 1.0) -> void:
	_kill_fade()
	_fade_tween = create_tween()
	_fade_tween.tween_property(player, "volume_db", SILENT_DB, duration)
	_fade_tween.tween_callback(player.stop)

func _kill_fade() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
