extends Node

@onready var bgm_player: AudioStreamPlayer = $BGMPlayer


func play_music(path: String):
	if bgm_player.playing and bgm_player.stream.resource_path == path:
		return
	bgm_player.stream = load(path)
	bgm_player.play()
