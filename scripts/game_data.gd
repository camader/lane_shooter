extends Node

const MAX_PROJECTILES: int = 5
const MIN_FIRE_RATE: float = 0.08

var minions_killed: int = 0
var bosses_killed: int = 0
var score: int = 0
var current_damage: int = 1
var current_fire_rate: float = 0.5
var current_projectiles: int = 1
var current_projectile_type: String = "pulse_bolt"


func reset_run() -> void:
	minions_killed = 0
	bosses_killed = 0
	score = 0
	current_damage = 1
	current_fire_rate = 0.5
	current_projectiles = 1
	current_projectile_type = "pulse_bolt"


func add_minion_kill() -> void:
	minions_killed += 1
	_recalc_score()


func add_boss_kill() -> void:
	bosses_killed += 1
	_recalc_score()


func apply_fire_rate_up(amount: float) -> void:
	current_fire_rate = max(MIN_FIRE_RATE, current_fire_rate - amount)


func apply_damage_up(amount: int) -> void:
	current_damage += amount


func apply_multishot_up() -> void:
	current_projectiles = min(MAX_PROJECTILES, current_projectiles + 1)


func is_multishot_maxed() -> bool:
	return current_projectiles >= MAX_PROJECTILES


func get_dps() -> float:
	return float(current_damage * current_projectiles) / current_fire_rate


func set_projectile_type(type: String) -> void:
	current_projectile_type = type


func _recalc_score() -> void:
	score = minions_killed + 10 * bosses_killed
