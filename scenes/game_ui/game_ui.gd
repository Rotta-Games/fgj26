extends Node

@onready var player1_progressbar = $MarginContainer/Control/Player1UIHBoxContainer/TextureProgressBar
@onready var player1_score_text = $MarginContainer/Control/Player1UIHBoxContainer/Score


# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.playerHealthState.connect(_on_player_health_state_emitted)
	SignalBus.playerScoreState.connect(_on_player_score_state_emitted)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	pass
	
func _on_player_health_state_emitted(data) -> void:
	if data["player_id"] == 1:
		player1_progressbar.value = data["health"]

func _on_player_score_state_emitted(data) -> void:
	if data["player_id"] == 1:
		player1_score_text.text = str(data["score"])
	
