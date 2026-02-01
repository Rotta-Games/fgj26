extends Node

var menu_music = preload("res://assets/music/ggj26-140bpm-d-minor-main-loop-1.mp3")
var boss_music = preload("res://assets/music/fgj-boss-80bpm-c-minor.mp3")
var current_state: Types.MusicState = Types.MusicState.MAIN_MUSIC
@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready():
	add_child(music_player)
	music_player.bus = "Music"
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	SignalBus.musicState.connect(_change_music_state)
	
	play_music(menu_music)

func play_music(stream: AudioStream):
	if music_player.stream == stream and music_player.playing:
		return
	
	music_player.stream = stream
	music_player.play()

func stop_music():
	music_player.stop()

func _change_music_state(new_state: Types.MusicState):
	if (new_state == Types.MusicState.MAIN_MUSIC and current_state != Types.MusicState.MAIN_MUSIC):
		play_music(menu_music)
	elif (new_state == Types.MusicState.BOSS_MUSIC and current_state != Types.MusicState.BOSS_MUSIC):
		play_music(boss_music)
