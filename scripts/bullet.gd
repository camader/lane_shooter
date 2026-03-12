extends Area3D

var speed: float = 25.0
var damage: int = 1
var projectile_type: String = "pulse_bolt"
var power_level: int = 1
var _penetrations_left: int = 0

const PROJECTILE_PATHS: Dictionary = {
	"pulse_bolt": "res://assets/models/projectiles/pulse_bolt.glb",
	"laser_streak": "res://assets/models/projectiles/laser_streak.glb",
	"plasma_orb": "res://assets/models/projectiles/plasma_orb.glb",
}

const PROJECTILE_COLORS: Dictionary = {
	"pulse_bolt": Color(0, 0.9, 1, 1),
	"laser_streak": Color(1, 0.95, 0.7, 1),
	"plasma_orb": Color(0.2, 1, 0.3, 1),
}

const PLASMA_AOE_RADIUS: float = 2.0
const LASER_MAX_PENETRATIONS: int = 3


func _ready() -> void:
	var path: String = PROJECTILE_PATHS.get(projectile_type, PROJECTILE_PATHS["pulse_bolt"])
	var scene: PackedScene = load(path)
	if scene:
		var model: Node3D = scene.instantiate()
		$ProjectileMount.add_child(model)

	var color: Color = PROJECTILE_COLORS.get(projectile_type, PROJECTILE_COLORS["pulse_bolt"])
	$BulletLight.light_color = color

	# Scale projectile by 1% per power level above 1
	var scale_factor: float = 1.0 + (power_level - 1) * 0.01
	$ProjectileMount.scale = Vector3(scale_factor, scale_factor, scale_factor)

	# Laser streak can penetrate through enemies
	if projectile_type == "laser_streak":
		_penetrations_left = LASER_MAX_PENETRATIONS


func _physics_process(delta: float) -> void:
	position.z -= speed * delta
	if position.z < -55.0:
		queue_free()


func _on_area_entered(area: Area3D) -> void:
	if not area.has_method("take_damage"):
		return

	match projectile_type:
		"plasma_orb":
			_plasma_explode()
			queue_free()
		"laser_streak":
			area.take_damage(damage)
			_penetrations_left -= 1
			if _penetrations_left <= 0:
				queue_free()
		_:
			area.take_damage(damage)
			queue_free()


func _plasma_explode() -> void:
	var enemies_node: Node = get_tree().current_scene.get_node_or_null("Enemies")
	if not enemies_node:
		return

	for enemy in enemies_node.get_children():
		if enemy is Area3D and enemy.has_method("take_damage"):
			var dist: float = global_position.distance_to(enemy.global_position)
			if dist <= PLASMA_AOE_RADIUS:
				enemy.take_damage(damage)
