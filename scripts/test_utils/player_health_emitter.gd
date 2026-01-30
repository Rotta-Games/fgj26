extends Node

const TRESHOLD = 0.02

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Generate a random float between 0.0 and 1.0
	if randf() < TRESHOLD:
		SignalBus.playerHealthState.emit({
			"player_id": Types.Player.PLAYER_1,
			"health": randi_range(1,100)
		})
		print("Signal emitted!")
