extends StaticBody2D

@onready var animation_player = $AnimationPlayer

@export var data: StaticObject

var health: int
var drop: PackedScene

func _ready() -> void:
	health = data.health
	drop = data.drop
	
func hurt(amount: int):
	animation_player.play("hurt")
	health -= amount
	
	if (health <= 0):
		_destroy()

func _destroy() -> void:
	animation_player.play("dead")
	if drop:
		var drop_instance := drop.instantiate()
		if drop_instance is Node2D:
			drop_instance.global_position = global_position
		get_tree().current_scene.add_child(drop_instance)
	await animation_player.animation_finished
	queue_free()
