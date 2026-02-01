extends Node2D

@onready var _block_container : Node2D = $Blocks
@onready var _spawn_point_container : Node2D = $SpawnPoints
@onready var _enemy_container : Node2D = $Enemies

@onready var _boss_scene : PackedScene = preload("res://scenes/boss/boss.tscn")

var _current_camera_limit : int = 0
var _current_block : StageBlock
var _enemies_alive : int = 0
var _spawn_in_progress : bool = false

const MIN_SPAWN_DELAY_S : float = 0.3
const MAX_SPAWN_DELAY_S : float = 1.5
const CAMERA_SPAWN_OFFSET : int = 32


signal camera_right_limit_changed(right_limit: int)


func _ready() -> void:
	if _block_container.get_children().is_empty():
		printerr("No blocks defined in Stage")
		return
	var first_block = _block_container.get_child(0)
	_set_block(first_block)
	
func _set_block(block: StageBlock) -> void:
	_current_block = block
	_current_camera_limit = block.global_position.x
	camera_right_limit_changed.emit(_current_camera_limit)

		
func _spawn_wave(wave: EnemyWave) -> void:
	var coinflip = randi_range(0, 1)
	var first_wave = wave.enemies_left
	var first_side = Types.Side.LEFT
	var second_wave = wave.enemies_right
	var second_side = Types.Side.RIGHT
	if coinflip == 0:
		first_wave = wave.enemies_right
		first_side = Types.Side.RIGHT
		second_wave = wave.enemies_left
		second_side = Types.Side.LEFT
		
	_spawn_in_progress = true
	for enemy in first_wave:
		var delay : float = randf_range(MIN_SPAWN_DELAY_S, MAX_SPAWN_DELAY_S)
		await get_tree().create_timer(delay).timeout
		_spawn_enemy(enemy, first_side)
	for enemy in second_wave:
		var delay : float = randf_range(MIN_SPAWN_DELAY_S, MAX_SPAWN_DELAY_S)
		await get_tree().create_timer(delay).timeout
		_spawn_enemy(enemy, second_side)
	_spawn_in_progress = false

func _spawn_enemy(enemy_scene: PackedScene, side: Types.Side) -> void:
	var enemy = enemy_scene.instantiate()
	_enemy_container.add_child(enemy)
	var spawn_point = _get_random_spawn_point(side)
	enemy.init_spawn(spawn_point)
	_enemies_alive += 1
	print("enemies alive " + str(_enemies_alive))
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
	_enemies_alive = max(0, _enemies_alive - 1)

	print("ENEMY DEAD: enemies remaining " + str(_enemies_alive) + ", spawn in progress? " + str(_spawn_in_progress))
	if _spawn_in_progress:
		return
	if _enemies_alive == 0:
		if _has_more_waves():
			print("MORE WAVES!")
			var wave = _current_block.waves.pop_front()
			_spawn_wave(wave)
			return
		print("NEXT BLOCK")
		_block_container.remove_child(_current_block)
		_current_block.queue_free()
		_current_block = null
		if _block_container.get_children().is_empty():
			var boss = _boss_scene.instantiate()
			# get random spawn point location for boss
			var spawn_point = _get_random_spawn_point(Types.Side.RIGHT)
			_enemy_container.add_child(boss)
			boss.position = spawn_point
			boss.dead.connect(_finish_stage)
			return
		
		var next_block = _block_container.get_child(0)
		_set_block(next_block)
			
func _finish_stage() -> void:
	print("TODO: FINISH STAGE")
		
func _has_more_waves() -> bool:
	return not _current_block.waves.is_empty()


func _on_sub_pixel_follow_camera_checkpoint_reached() -> void:
	if _has_more_waves():
		var wave = _current_block.waves.pop_front()
		_spawn_wave(wave)
