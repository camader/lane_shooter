extends Area3D

signal fire_bullet(muzzle_positions: Array[Vector3], weapon_type: String)

const MOVE_SPEED: float = 12.0
const MIN_X: float = -5.5
const MAX_X: float = 5.5

# Ship model scenes indexed by tier (projectile count 1-5)
const SHIP_PATHS: Array[String] = [
	"res://assets/models/ships/ship_tier1_viper.glb",
	"res://assets/models/ships/ship_tier2_falcon.glb",
	"res://assets/models/ships/ship_tier3_corsair.glb",
	"res://assets/models/ships/ship_tier4_valkyrie.glb",
	"res://assets/models/ships/ship_tier5_sovereign.glb",
]

# Weapon model scenes
const WEAPON_PATHS: Dictionary = {
	"pulse_cannon": "res://assets/models/weapons/pulse_cannon.glb",
	"laser_repeater": "res://assets/models/weapons/laser_repeater.glb",
	"plasma_cannon": "res://assets/models/weapons/plasma_cannon.glb",
}

var direction: float = 0.0
var current_tier: int = 0  # 0-indexed, corresponds to projectile count - 1
var current_weapon: String = "pulse_cannon"
var _ship_node: Node3D = null
var _weapon_nodes: Array[Node3D] = []
var _muzzle_nodes: Array[Node3D] = []


func _ready() -> void:
	_load_ship(0)


func _process(delta: float) -> void:
	direction = 0.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction = -1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction = 1.0

	position.x += direction * MOVE_SPEED * delta
	position.x = clamp(position.x, MIN_X, MAX_X)

	# Tilt into turns
	var target_roll: float = direction * -0.2
	rotation.z = lerp(rotation.z, target_roll, delta * 8.0)


func _on_fire_timer_timeout() -> void:
	var positions: Array[Vector3] = get_muzzle_positions()
	fire_bullet.emit(positions, GameData.current_projectile_type)


func set_fire_rate(rate: float) -> void:
	$FireTimer.wait_time = rate


func update_power_visual(damage: int, projectiles: int = 1) -> void:
	if projectiles > 1:
		$StrengthLabel.text = "%d x%d" % [damage, projectiles]
	else:
		$StrengthLabel.text = str(damage)

	var intensity: float = min(damage, 10) / 10.0
	var color: Color = Color(0.2, 0.9, 0.2).lerp(Color(1.0, 0.9, 0.3), intensity)
	$StrengthLabel.modulate = color


## Get world-space positions of all muzzle points on equipped weapons.
## Falls back to evenly-spaced positions in front of the player if no muzzles found.
func get_muzzle_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []

	for muzzle in _muzzle_nodes:
		if is_instance_valid(muzzle):
			positions.append(muzzle.global_position)

	# Fallback: if no muzzle nodes, generate positions the old way
	if positions.is_empty():
		var count: int = GameData.current_projectiles
		var spacing: float = 0.5
		var total_width: float = spacing * (count - 1)
		var start_x: float = global_position.x - total_width / 2.0
		for i in range(count):
			var bx: float = start_x + i * spacing
			positions.append(Vector3(bx, 0.5, global_position.z - 1.0))

	return positions


## Upgrade ship tier based on projectile count (1-5)
func set_ship_tier(projectile_count: int) -> void:
	var new_tier: int = clampi(projectile_count - 1, 0, SHIP_PATHS.size() - 1)
	if new_tier != current_tier:
		_load_ship(new_tier)


## Change the weapon type on all hardpoints
func set_weapon_type(weapon_name: String) -> void:
	if weapon_name in WEAPON_PATHS and weapon_name != current_weapon:
		current_weapon = weapon_name
		_attach_weapons()


func _load_ship(tier: int) -> void:
	current_tier = tier

	# Remove existing ship model
	if _ship_node:
		_ship_node.queue_free()
		_ship_node = null
	_weapon_nodes.clear()
	_muzzle_nodes.clear()

	# Load the GLB scene
	var ship_scene: PackedScene = load(SHIP_PATHS[tier])
	if not ship_scene:
		push_warning("Failed to load ship model: " + SHIP_PATHS[tier])
		return

	_ship_node = ship_scene.instantiate()
	_ship_node.name = "ShipModel"

	# Scale ships to game size — keep consistent, don't grow too much per tier
	var ship_scale: float = 1.5 + tier * 0.15
	_ship_node.scale = Vector3(ship_scale, ship_scale, ship_scale)

	$ShipMount.add_child(_ship_node)

	# Attach weapons to hardpoints
	_attach_weapons()

	# Play upgrade flash effect
	if tier > 0:
		_play_upgrade_effect()


func _attach_weapons() -> void:
	# Clear existing weapon instances and muzzle references
	for w in _weapon_nodes:
		if is_instance_valid(w):
			w.queue_free()
	_weapon_nodes.clear()
	_muzzle_nodes.clear()

	if not _ship_node:
		return

	var weapon_scene: PackedScene = load(WEAPON_PATHS[current_weapon])
	if not weapon_scene:
		push_warning("Failed to load weapon: " + WEAPON_PATHS[current_weapon])
		return

	# Find all hardpoint empties in the ship model
	var hardpoints: Array[Node3D] = []
	_find_nodes_by_prefix(_ship_node, "Hardpoint", hardpoints)

	# Sort by name so Hardpoint_1 comes first
	hardpoints.sort_custom(func(a: Node3D, b: Node3D): return a.name < b.name)

	for hp in hardpoints:
		var weapon_inst: Node3D = weapon_scene.instantiate()
		weapon_inst.name = "Weapon"
		hp.add_child(weapon_inst)
		_weapon_nodes.append(weapon_inst)

		# Find the Muzzle empty inside this weapon instance
		var muzzles: Array[Node3D] = []
		_find_nodes_by_prefix(weapon_inst, "Muzzle", muzzles)
		_muzzle_nodes.append_array(muzzles)


func _find_nodes_by_prefix(node: Node, prefix: String, result: Array[Node3D]) -> void:
	if node.name.begins_with(prefix):
		result.append(node as Node3D)
	for child in node.get_children():
		_find_nodes_by_prefix(child, prefix, result)


func _play_upgrade_effect() -> void:
	var light: OmniLight3D = $PlayerLight
	var original_energy: float = light.light_energy
	light.light_energy = 5.0
	light.light_color = Color(0.0, 0.9, 1.0)
	var tween := create_tween()
	tween.tween_property(light, "light_energy", original_energy, 0.5)
	tween.parallel().tween_property(light, "light_color", Color(0.3, 0.9, 0.4), 0.5)
