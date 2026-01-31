extends Node2D

@onready var _block_container : Node2D = $Blocks
@onready var _spawn_point_container : Node2D = $SpawnPoints

var _current_camera_limit : int = 0
var _current_block : StageBlock

const MIN_SPAWN_DELAY_S : float = 0.5
const MAX_SPAWN_DELAY_S : float = 2.5
const CAMERA_SPAWN_OFFSET : int = 32

signal camera_right_limit_changed(right_limit: int)


func _ready() -> void:
	if _block_container.get_children().is_empty():
		printerr("No blocks defined in Stage")
		return
	var first_block = _block_container.get_children()[0]
	_set_block(first_block)
	
func _set_block(block: StageBlock) -> void:
	_current_block = block
	_current_camera_limit = block.global_position.x
	camera_right_limit_changed.emit(_current_camera_limit)
		
func _spawn_wave(wave: EnemyWave) -> void:
	if not wave.enemy_packs_left.is_empty():
		var pack = wave.enemy_packs_left.pop_front()
		_spawn_pack(pack, Types.Side.LEFT)
	if not wave.enemy_packs_right.is_empty():
		var pack = wave.enemy_packs_right.pop_front()
		_spawn_pack(pack, Types.Side.RIGHT)
			
func _spawn_pack(pack: EnemyPack, side: Types.Side) -> void:
	for enemy in pack.enemies:
		_spawn_enemy(enemy, side)
		var delay : float = randf_range(MIN_SPAWN_DELAY_S, MAX_SPAWN_DELAY_S)
		await get_tree().create_timer(delay).timeout
			
func _spawn_enemy(enemy_scene: PackedScene, side: Types.Side) -> void:
	var enemy = enemy_scene.instantiate()
	_current_block.add_child(enemy)
	var spawn_point = _get_random_spawn_point(side)
	enemy.global_position = spawn_point
	enemy.state = Types.EnemyState.SEEK
	enemy.dead.connect(_on_enemy_killed)

func _get_random_spawn_point(side: Types.Side) -> Vector2i:
	var rand_spawn = _spawn_point_container.get_children().pick_random()
	var canvas_transform = get_viewport().get_canvas_transform()
	var global_screen_left = -canvas_transform.origin.x
	var global_screen_right = global_screen_left + get_viewport_rect().size.x
	var spawn_point = Vector2i.ZERO
	spawn_point.y = rand_spawn.global_position.y
	match side:
		Types.Side.RIGHT:
			spawn_point.x = global_screen_right + CAMERA_SPAWN_OFFSET
		Types.Side.LEFT:
			spawn_point.x = global_screen_left - CAMERA_SPAWN_OFFSET
	return spawn_point
	
func _on_enemy_killed() -> void:
	print("ENEMY DEAD")
			
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == Key.KEY_ESCAPE:
			get_tree().quit()


func _on_sub_pixel_follow_camera_right_limit_reached() -> void:
	print("hep")
	if not _current_block.waves.is_empty():
		var wave = _current_block.waves.front()
		_spawn_wave(wave)
