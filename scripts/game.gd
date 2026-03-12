extends Node3D

# Lane 0 = left (power-ups), lanes 1 & 2 = center/right (enemies)
const LANE_CENTERS: Array[float] = [-4.0, 0.0, 4.0]
const ENEMY_LANES: Array[int] = [1, 2]
const POWERUP_LANE: int = 0
const TRAVERSE_DISTANCE: float = 55.0  # z=-50 to z=5

var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")

const ET = preload("res://scripts/enemy.gd").EnemyType

var run_time: float = 0.0
var base_hp: int = 5
var scroll_speed: float = 4.0
var spawn_interval: float = 2.0
var powerup_interval: float = 4.0
var time_since_boss: float = 0.0
var difficulty_timer: float = 0.0
var enemies_per_spawn: int = 1
var enemy_ramp_timer: float = 0.0
var game_over_triggered: bool = false


func _ready() -> void:
	$Player.fire_bullet.connect(_on_player_fire)
	$Player.set_fire_rate(GameData.current_fire_rate)
	$SpawnTimer.wait_time = spawn_interval
	$SpawnTimer.start()
	$PowerupTimer.wait_time = powerup_interval
	$PowerupTimer.start()
	$HUD.update_score(0, 0, 0)
	$HUD.update_power(GameData.current_damage, GameData.current_fire_rate, GameData.current_projectiles)
	$Player.update_power_visual(GameData.current_damage, GameData.current_projectiles)


func _process(delta: float) -> void:
	if game_over_triggered:
		return
	run_time += delta
	difficulty_timer += delta
	time_since_boss += delta
	enemy_ramp_timer += delta

	# Slow scroll ramp
	scroll_speed = 4.0 + run_time * 0.06

	# HP and spawn rate ramp every 25s
	if difficulty_timer > 25.0:
		difficulty_timer = 0.0
		base_hp += 2
		spawn_interval = max(0.5, spawn_interval - 0.1)
		$SpawnTimer.wait_time = spawn_interval

	# Enemy count ramp every 35s
	if enemy_ramp_timer > 35.0:
		enemy_ramp_timer = 0.0
		enemies_per_spawn += 1


func _on_player_fire(muzzle_positions: Array[Vector3], weapon_type: String = "pulse_bolt") -> void:
	if game_over_triggered:
		return
	for muzzle_pos in muzzle_positions:
		var bullet: Area3D = bullet_scene.instantiate()
		bullet.position = muzzle_pos
		bullet.damage = GameData.current_damage
		bullet.projectile_type = weapon_type
		bullet.power_level = GameData.current_damage
		$Bullets.add_child(bullet)


## Calculate how much damage the player can deal during one full traversal.
func _calc_traversal_damage() -> float:
	var traversal_time: float = TRAVERSE_DISTANCE / scroll_speed
	return GameData.get_dps() * traversal_time


## Generate variable enemy HP around a base value.
func _roll_enemy_hp(base: int, variance: float) -> int:
	var low: float = base * (1.0 - variance)
	var high: float = base * (1.0 + variance)
	return max(1, randi_range(int(low), int(high)))


## Generate power-up HP: random between 1 and 50% of player's traversal damage.
func _roll_powerup_hp() -> int:
	var max_affordable: float = _calc_traversal_damage() * 0.5
	var hp: int = max(1, randi_range(1, max(1, int(max_affordable))))
	return hp


func _on_spawn_timer_timeout() -> void:
	if game_over_triggered:
		return

	for _n in range(enemies_per_spawn):
		var type: int
		var enemy_hp: int
		if time_since_boss >= 30.0:
			type = ET.BOSS
			enemy_hp = _roll_enemy_hp(base_hp * 10, 0.3)
			time_since_boss = 0.0
		else:
			type = ET.MINION
			enemy_hp = _roll_enemy_hp(base_hp, 0.4)

		var lane: int = ENEMY_LANES[randi_range(0, 1)]
		var x_jitter: float = randf_range(-0.8, 0.8)
		var z_jitter: float = randf_range(0.0, -5.0) if _n > 0 else 0.0

		var enemy: Area3D = enemy_scene.instantiate()
		enemy.position = Vector3(LANE_CENTERS[lane] + x_jitter, 0.5, -50.0 + z_jitter)
		enemy.setup(type, enemy_hp, scroll_speed)
		enemy.killed.connect(_on_enemy_killed)
		enemy.passed.connect(_on_enemy_passed)
		$Enemies.add_child(enemy)


func _on_powerup_timer_timeout() -> void:
	if game_over_triggered:
		return

	var available_types: Array[int] = [ET.POWERUP_FIRERATE, ET.POWERUP_DAMAGE]
	if not GameData.is_multishot_maxed():
		available_types.append(ET.POWERUP_MULTISHOT)
	if GameData.current_projectile_type != "laser_streak":
		available_types.append(ET.POWERUP_LASER)
	if GameData.current_projectile_type != "plasma_orb":
		available_types.append(ET.POWERUP_PLASMA)

	var type: int = available_types[randi_range(0, available_types.size() - 1)]
	var powerup_hp: int
	if type in [ET.POWERUP_LASER, ET.POWERUP_PLASMA]:
		powerup_hp = GameData.current_damage
	else:
		powerup_hp = _roll_powerup_hp()

	var powerup: Area3D = enemy_scene.instantiate()
	powerup.position = Vector3(LANE_CENTERS[POWERUP_LANE], 0.5, -50.0)
	powerup.setup(type, powerup_hp, scroll_speed)
	powerup.killed.connect(_on_enemy_killed)
	powerup.passed.connect(_on_enemy_passed)
	$Enemies.add_child(powerup)


func _on_enemy_killed(enemy: Area3D) -> void:
	# Reward scaling: how tough the powerup was relative to traversal damage
	var reward_ratio: float = 0.0
	var max_affordable: float = _calc_traversal_damage() * 0.5
	if max_affordable > 0.0:
		reward_ratio = clamp(float(enemy.max_hp) / max_affordable, 0.0, 1.0)

	match enemy.enemy_type:
		ET.MINION:
			GameData.add_minion_kill()
		ET.BOSS:
			GameData.add_boss_kill()
		ET.POWERUP_FIRERATE:
			var amount: float = lerp(0.02, 0.08, reward_ratio)
			GameData.apply_fire_rate_up(amount)
			$Player.set_fire_rate(GameData.current_fire_rate)
		ET.POWERUP_DAMAGE:
			var amount: int = max(1, int(lerp(1.0, 3.0, reward_ratio)))
			GameData.apply_damage_up(amount)
		ET.POWERUP_MULTISHOT:
			GameData.apply_multishot_up()
			$Player.set_ship_tier(GameData.current_projectiles)
		ET.POWERUP_LASER:
			GameData.set_projectile_type("laser_streak")
		ET.POWERUP_PLASMA:
			GameData.set_projectile_type("plasma_orb")

	if enemy.is_powerup():
		$Player.update_power_visual(GameData.current_damage, GameData.current_projectiles)
	$HUD.update_power(GameData.current_damage, GameData.current_fire_rate, GameData.current_projectiles)
	$HUD.update_score(GameData.score, GameData.minions_killed, GameData.bosses_killed)


func _on_enemy_passed(enemy: Area3D) -> void:
	if not enemy.is_powerup():
		_game_over()


func _game_over() -> void:
	if game_over_triggered:
		return
	game_over_triggered = true
	SaveManager.save_run(GameData.minions_killed, GameData.bosses_killed, GameData.score)
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/high_score.tscn"))
