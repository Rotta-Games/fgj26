extends Node

@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready():
	add_child(music_player)
	music_player.bus = "Music"
	process_mode = Node.PROCESS_MODE_ALWAYS

func play_music(stream: AudioStream):
	if music_player.stream == stream and music_player.playing:
		return
	
	music_player.stream = stream
	music_player.play()

func stop_music():
	music_player.stop()
