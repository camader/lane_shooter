extends Control


func _ready() -> void:
	$StatsContainer/BestScoreLabel.text = "Best Score: %d" % SaveManager.high_score
	$StatsContainer/BestMinionsLabel.text = "Best Minions Killed: %d" % SaveManager.high_minions
	$StatsContainer/BestBossesLabel.text = "Best Bosses Killed: %d" % SaveManager.high_bosses
	$StatsContainer/Separator.text = "---"
	$StatsContainer/LastScoreLabel.text = "Last Score: %d" % SaveManager.last_score
	$StatsContainer/LastMinionsLabel.text = "Last Minions Killed: %d" % SaveManager.last_minions
	$StatsContainer/LastBossesLabel.text = "Last Bosses Killed: %d" % SaveManager.last_bosses
	$BackButton.pressed.connect(_on_back)


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
