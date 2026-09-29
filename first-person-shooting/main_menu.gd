extends Control

@onready var play_button = $CenterContainer/VBoxContainer/PlayButton
@onready var quit_button = $CenterContainer/VBoxContainer/QuitButton


func _ready():
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_play_pressed():
	get_tree().change_scene_to_file("res://main.tscn")


func _on_quit_pressed():
	get_tree().quit()
