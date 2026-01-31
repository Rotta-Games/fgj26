extends Node2D

@onready var player_scene: PackedScene = preload("res://scenes/player/player.tscn")

var player2_instance: Node = null
@onready var player1_instance: Node = $Player


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("player2_start") and player2_instance == null:
		# create new Player2 instance and change player id to PLAYER_2 in the player_stats resource
		player2_instance = player_scene.instantiate()
		player2_instance.player_stats.player_id = Types.PlayerId.PLAYER_2
		get_tree().get_current_scene().add_child(player2_instance)
		SignalBus.playerStartChange.emit(Types.PlayerId.PLAYER_2, true)
	elif event.is_action_pressed("player2_start") and player2_instance != null:
		player2_instance.queue_free()
		player2_instance = null

	if event.is_action_pressed("player1_start") and player1_instance == null:
		# create new Player1 instance and change player id to PLAYER_1 in the player_stats resource
		player1_instance = player_scene.instantiate()
		player1_instance.player_stats.player_id = Types.PlayerId.PLAYER_1
		get_tree().get_current_scene().add_child(player1_instance)
		SignalBus.playerStartChange.emit(Types.PlayerId.PLAYER_1, true)
