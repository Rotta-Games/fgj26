extends Control

@onready var title: Sprite2D = $Title
@onready var title_text: Sprite2D = $TitleText

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HelpCont.visible = false
	$VBoxContainer/start_button.grab_focus()
	_bounce_logo()

func _bounce_logo() -> void:
	var title_target_y = title.position.y
	var text_target_y = title_text.position.y

	# Start above screen
	title.position.y = -50
	title_text.position.y = -54

	# Bounce in
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(title, "position:y", title_target_y, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(title_text, "position:y", text_target_y, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT).set_delay(0.1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_quit_button_button_up() -> void:
	if OS.get_name() != "Web":
		get_tree().quit()

	var quit_button = $VBoxContainer/quit_button
	quit_button.text += ":D"



func _on_start_button_button_up() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_help_button_button_up() -> void:
	$HelpCont.visible = !$HelpCont.visible

