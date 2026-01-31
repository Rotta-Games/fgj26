extends Node2D

@onready var player2_scene: PackedScene = preload("res://scenes/player/player.tscn")

var player2_instance: Node = null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("player2_start") and player2_instance == null:
		# create new Player2 instance and change player id to PLAYER_2 in the player_stats resource
		player2_instance = player2_scene.instantiate()
		player2_instance.player_stats.player_id = Types.PlayerId.PLAYER_2
		get_tree().get_current_scene().add_child(player2_instance)
	elif event.is_action_pressed("player2_start") and player2_instance != null:
		player2_instance.queue_free()
		player2_instance = null

