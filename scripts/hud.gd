extends CanvasLayer


func update_score(score: int, minions: int, bosses: int) -> void:
	$TopBar/ScoreLabel.text = "Score: %d" % score
	$TopBar/MinionsLabel.text = "Minions: %d" % minions
	$TopBar/BossesLabel.text = "Bosses: %d" % bosses


func update_power(damage: int, fire_rate: float, projectiles: int) -> void:
	# Damage bar
	var dmg_ratio: float = clamp(float(damage) / 15.0, 0.0, 1.0)
	$PowerPanel/VBox/DmgRow/DmgBarBG/DmgBarFill.size.x = max(4.0, 180.0 * dmg_ratio)
	$PowerPanel/VBox/DmgRow/DmgBarBG/DmgBarFill.color = Color(1.0, 0.3, 0.1).lerp(Color(1.0, 0.8, 0.2), dmg_ratio)
	$PowerPanel/VBox/DmgRow/DmgLabel.text = "DMG: %d" % damage

	# Fire rate bar
	var rate_ratio: float = clamp((0.4 - fire_rate) / 0.32, 0.0, 1.0)
	$PowerPanel/VBox/RateRow/RateBarBG/RateBarFill.size.x = max(4.0, 180.0 * rate_ratio)
	$PowerPanel/VBox/RateRow/RateBarBG/RateBarFill.color = Color(1.0, 0.8, 0.0).lerp(Color(1.0, 1.0, 0.5), rate_ratio)
	$PowerPanel/VBox/RateRow/RateLabel.text = "RATE: %.1f/s" % (1.0 / fire_rate)

	# Multishot bar
	var shot_ratio: float = clamp(float(projectiles) / 7.0, 0.0, 1.0)
	$PowerPanel/VBox/ShotRow/ShotBarBG/ShotBarFill.size.x = max(4.0, 180.0 * shot_ratio)
	$PowerPanel/VBox/ShotRow/ShotBarBG/ShotBarFill.color = Color(0.0, 0.5, 1.0).lerp(Color(0.4, 0.8, 1.0), shot_ratio)
	$PowerPanel/VBox/ShotRow/ShotLabel.text = "SHOTS: %d" % projectiles
