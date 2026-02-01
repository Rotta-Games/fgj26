extends Node

@onready var player1_progressbar = $MarginContainer/Control/Player1Data/TextureProgressBar
@onready var player1_score_text = $MarginContainer/Control/Player1Data/Score
@onready var player2_progressbar = $MarginContainer/Control/Player2Data/TextureProgressBar
@onready var player2_score_text = $MarginContainer/Control/Player2Data/Score
@onready var player1_data_container = $MarginContainer/Control/Player1Data
@onready var player1_start_text = $MarginContainer/Control/Player1Start
@onready var player2_data_container = $MarginContainer/Control/Player2Data
@onready var player2_start_text = $MarginContainer/Control/Player2Start
@onready var blink_anim_player = $BlinkAnimationPlayer
@onready var shimmer_anim_player = $ShimmerAnimationPlayer
@onready var shimmer_timer = $ShimmerTimer
@onready var pause_menu = $PauseMenu
@onready var boss_health_bar = $MarginContainer/Control/BossHealthBar
@onready var boss_progressbar = $MarginContainer/Control/BossHealthBar/TextureProgressBar

# Game State :D
var is_paused: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.playerHealthState.connect(_on_player_health_state_emitted)
	SignalBus.playerScoreState.connect(_on_player_score_state_emitted)
	SignalBus.playerStartChange.connect(_on_player_start_change_emitted)
	SignalBus.gamePausedChange.connect(_on_game_pause_changed)
	SignalBus.bossHealthState.connect(_on_boss_health_state_emitted)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == Key.KEY_ESCAPE:
			SignalBus.gamePausedChange.emit(!is_paused)
	
func _on_player_health_state_emitted(data) -> void:
	if data["player_id"] == 1:
		player1_progressbar.value = data["health"]
	elif data["player_id"] == 2:
		player2_progressbar.value = data["health"]

func _on_player_score_state_emitted(data) -> void:
	if data["player_id"] == 1:
		player1_score_text.text = str(data["score"])
	elif data["player_id"] == 2:
		player2_score_text.text = str(data["score"])
	
func _on_player_start_change_emitted(player: Types.PlayerId, is_in_game: bool) -> void:
	if player == 1:
		player1_data_container.visible = is_in_game
		player1_start_text.visible = !is_in_game
	elif player == 2:
		player2_data_container.visible = is_in_game
		player2_start_text.visible = !is_in_game

func _on_shimmer_timer_timeout() -> void:
	shimmer_anim_player.play("shimmer")
	shimmer_timer.wait_time = randf_range(2.0, 5.0)

func _on_boss_health_state_emitted(data: Dictionary) -> void:
	boss_health_bar.visible = data.get("visible", false)
	var max_health = data.get("max_health", 100)
	var health = data.get("health", 0)
	boss_progressbar.max_value = max_health
	boss_progressbar.value = health

func _on_game_pause_changed(is_game_paused: bool) -> void:
	is_paused = is_game_paused
	pause_menu.visible = is_paused
	
	if (pause_menu.visible):
		$PauseMenu/ResumeButton.grab_focus()
		
	get_tree().paused = is_paused

func _on_resume_button_pressed():
	SignalBus.gamePausedChange.emit(false)


func _on_quit_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
