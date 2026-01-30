extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.playerHealthState.connect(_on_player_health_state_emitted)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	pass
	
func _on_player_health_state_emitted(data) -> void:
	print(data)
	
