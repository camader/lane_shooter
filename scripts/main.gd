extends Control


func _ready() -> void:
	$VBoxContainer/NewRunButton.pressed.connect(_on_new_run)
	$VBoxContainer/HighScoreButton.pressed.connect(_on_high_score)
	$VBoxContainer/ExitButton.pressed.connect(_on_exit)


func _on_new_run() -> void:
	GameData.reset_run()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_high_score() -> void:
	get_tree().change_scene_to_file("res://scenes/high_score.tscn")


func _on_exit() -> void:
	get_tree().quit()
