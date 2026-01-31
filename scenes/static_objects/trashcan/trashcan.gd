extends StaticBody2D

@export var data: StaticObject

var health: int
var drop: PackedScene

func _ready() -> void:
	health = data.health
	drop = data.drop
	
func hurt(amount: int):
	health -= amount
	
	if (health <= 0):
		_destroy()

func _destroy() -> void:
	if drop:
		var drop_instance := drop.instantiate()
		if drop_instance is Node2D:
			drop_instance.global_position = global_position
		get_tree().current_scene.add_child(drop_instance)
	queue_free()
