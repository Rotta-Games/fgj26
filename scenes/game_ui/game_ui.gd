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
@onready var shimmer_timer = $ShimmerTimer
# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.playerHealthState.connect(_on_player_health_state_emitted)
	SignalBus.playerScoreState.connect(_on_player_score_state_emitted)
	SignalBus.playerStartChange.connect(_on_player_start_change_emitted)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	pass
	
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
	blink_anim_player.play("shimmer")
	shimmer_timer.wait_time = randf_range(2.0, 5.0)
