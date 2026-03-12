extends Area3D

enum EnemyType { MINION, BOSS, POWERUP_FIRERATE, POWERUP_DAMAGE, POWERUP_MULTISHOT, POWERUP_LASER, POWERUP_PLASMA }

signal killed(enemy: Area3D)
signal passed(enemy: Area3D)

var enemy_type: EnemyType = EnemyType.MINION
var hp: int = 3
var max_hp: int = 3
var scroll_speed: float = 4.0

var _original_color: Color
var _spin_speed: float = 0.0
var _bob_speed: float = 0.0
var _bob_amount: float = 0.0


func is_powerup() -> bool:
	return enemy_type in [EnemyType.POWERUP_FIRERATE, EnemyType.POWERUP_DAMAGE, EnemyType.POWERUP_MULTISHOT, EnemyType.POWERUP_LASER, EnemyType.POWERUP_PLASMA]


## Setup with explicit HP. Caller is responsible for calculating HP.
func setup(type: EnemyType, assigned_hp: int, speed: float) -> void:
	enemy_type = type
	scroll_speed = speed
	hp = max(1, assigned_hp)

	for child in $Body.get_children():
		child.queue_free()

	match type:
		EnemyType.MINION:
			_setup_minion()
		EnemyType.BOSS:
			_setup_boss()
		EnemyType.POWERUP_FIRERATE:
			_setup_powerup_firerate()
		EnemyType.POWERUP_DAMAGE:
			_setup_powerup_damage()
		EnemyType.POWERUP_MULTISHOT:
			_setup_powerup_multishot()
		EnemyType.POWERUP_LASER:
			_setup_powerup_laser()
		EnemyType.POWERUP_PLASMA:
			_setup_powerup_plasma()

	max_hp = hp
	_update_hp_display()


func _setup_minion() -> void:
	_original_color = Color(0.85, 0.15, 0.1)
	_spin_speed = 1.0
	_bob_speed = 2.0
	_bob_amount = 0.1

	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.45
	body_mesh.height = 0.9
	body_mesh.radial_segments = 8
	body_mesh.rings = 4
	var body_inst := MeshInstance3D.new()
	body_inst.mesh = body_mesh
	body_inst.set_surface_override_material(0, _make_material(_original_color, 0.5, 0.4))
	$Body.add_child(body_inst)

	for i in range(6):
		var spike := MeshInstance3D.new()
		var spike_mesh := PrismMesh.new()
		spike_mesh.size = Vector3(0.15, 0.4, 0.15)
		spike.mesh = spike_mesh
		spike.set_surface_override_material(0, _make_material(Color(0.7, 0.1, 0.05), 0.6, 0.3))
		var angle: float = i * TAU / 6.0
		spike.position = Vector3(cos(angle) * 0.4, 0.0, sin(angle) * 0.4)
		spike.rotation.z = -cos(angle) * 0.8
		spike.rotation.x = sin(angle) * 0.8
		$Body.add_child(spike)

	var eye := MeshInstance3D.new()
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.12
	eye_mesh.height = 0.24
	eye.mesh = eye_mesh
	eye.position = Vector3(0, 0.15, 0.38)
	var eye_mat := _make_material(Color(1, 0.9, 0.0), 0.0, 0.2)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1, 0.8, 0.0)
	eye_mat.emission_energy_multiplier = 2.0
	eye.set_surface_override_material(0, eye_mat)
	$Body.add_child(eye)

	$CollisionShape.shape.size = Vector3(3.0, 1.0, 1.5)
	$EnemyLight.light_color = Color(0.9, 0.2, 0.1)
	$EnemyLight.light_energy = 0.4
	_set_bar_position(0.8)


func _setup_boss() -> void:
	_original_color = Color(0.6, 0.0, 0.05)
	_spin_speed = 0.5
	_bob_speed = 1.0
	_bob_amount = 0.15

	var core := MeshInstance3D.new()
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.8
	core_mesh.height = 1.6
	core_mesh.radial_segments = 24
	core_mesh.rings = 12
	core.mesh = core_mesh
	core.set_surface_override_material(0, _make_material(_original_color, 0.8, 0.2))
	$Body.add_child(core)

	for i in range(3):
		var ring := MeshInstance3D.new()
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.7
		ring_mesh.outer_radius = 0.95
		ring_mesh.rings = 16
		ring_mesh.ring_segments = 8
		ring.mesh = ring_mesh
		var ring_mat := _make_material(Color(0.4, 0.0, 0.0), 0.9, 0.15)
		ring_mat.emission_enabled = true
		ring_mat.emission = Color(0.4, 0.0, 0.0)
		ring_mat.emission_energy_multiplier = 0.5
		ring.set_surface_override_material(0, ring_mat)
		ring.rotation.x = i * TAU / 3.0
		$Body.add_child(ring)

	var eye := MeshInstance3D.new()
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.25
	eye_mesh.height = 0.5
	eye.mesh = eye_mesh
	eye.position = Vector3(0, 0, 0.7)
	var eye_mat := _make_material(Color(1.0, 0.2, 0.0), 0.0, 0.1)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.3, 0.0)
	eye_mat.emission_energy_multiplier = 3.0
	eye.set_surface_override_material(0, eye_mat)
	$Body.add_child(eye)

	$CollisionShape.shape.size = Vector3(3.5, 2.0, 2.0)
	$EnemyLight.light_color = Color(0.8, 0.1, 0.0)
	$EnemyLight.light_energy = 1.0
	$EnemyLight.omni_range = 4.0
	_set_bar_position(1.4)


func _setup_powerup_firerate() -> void:
	_original_color = Color(1.0, 0.75, 0.0)
	_spin_speed = 4.0
	_bob_speed = 3.0
	_bob_amount = 0.2

	var bolt := MeshInstance3D.new()
	var bolt_mesh := PrismMesh.new()
	bolt_mesh.size = Vector3(0.3, 0.8, 0.3)
	bolt.mesh = bolt_mesh
	var bolt_mat := _make_emissive_material(Color(1.0, 0.8, 0.0), Color(1.0, 0.7, 0.0), 3.0)
	bolt_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bolt_mat.albedo_color.a = 0.85
	bolt.set_surface_override_material(0, bolt_mat)
	$Body.add_child(bolt)

	var bolt2 := MeshInstance3D.new()
	var bolt2_mesh := PrismMesh.new()
	bolt2_mesh.size = Vector3(0.3, 0.6, 0.3)
	bolt2.mesh = bolt2_mesh
	bolt2.position = Vector3(0.1, -0.2, 0)
	bolt2.rotation.z = PI
	bolt2.set_surface_override_material(0, bolt_mat.duplicate())
	$Body.add_child(bolt2)

	for i in range(4):
		var spark := MeshInstance3D.new()
		var spark_mesh := SphereMesh.new()
		spark_mesh.radius = 0.08
		spark_mesh.height = 0.16
		spark.mesh = spark_mesh
		var angle: float = i * TAU / 4.0
		spark.position = Vector3(cos(angle) * 0.35, sin(angle) * 0.35, 0)
		spark.set_surface_override_material(0, _make_emissive_material(Color(1.0, 1.0, 0.5), Color(1.0, 0.9, 0.3), 4.0))
		$Body.add_child(spark)

	$CollisionShape.shape.size = Vector3(1.5, 1.5, 1.0)
	$EnemyLight.light_color = Color(1.0, 0.8, 0.0)
	$EnemyLight.light_energy = 0.8
	$EnemyLight.omni_range = 3.0
	_set_bar_position(1.0)


func _setup_powerup_damage() -> void:
	_original_color = Color(1.0, 0.3, 0.1)
	_spin_speed = 2.0
	_bob_speed = 2.5
	_bob_amount = 0.15

	var blade := MeshInstance3D.new()
	var blade_mesh := PrismMesh.new()
	blade_mesh.size = Vector3(0.25, 1.0, 0.25)
	blade.mesh = blade_mesh
	var blade_mat := _make_emissive_material(Color(1.0, 0.3, 0.1), Color(1.0, 0.2, 0.0), 2.5)
	blade_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blade_mat.albedo_color.a = 0.85
	blade.set_surface_override_material(0, blade_mat)
	$Body.add_child(blade)

	var guard := MeshInstance3D.new()
	var guard_mesh := BoxMesh.new()
	guard_mesh.size = Vector3(0.6, 0.08, 0.08)
	guard.mesh = guard_mesh
	guard.position.y = -0.25
	guard.set_surface_override_material(0, _make_material(Color(0.8, 0.6, 0.1), 0.9, 0.15))
	$Body.add_child(guard)

	var orb := MeshInstance3D.new()
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.15
	orb_mesh.height = 0.3
	orb.mesh = orb_mesh
	orb.set_surface_override_material(0, _make_emissive_material(Color(1.0, 0.5, 0.0), Color(1.0, 0.3, 0.0), 4.0))
	$Body.add_child(orb)

	$CollisionShape.shape.size = Vector3(1.5, 1.5, 1.0)
	$EnemyLight.light_color = Color(1.0, 0.3, 0.0)
	$EnemyLight.light_energy = 0.8
	$EnemyLight.omni_range = 3.0
	_set_bar_position(1.0)


func _setup_powerup_multishot() -> void:
	_original_color = Color(0.0, 0.5, 1.0)
	_spin_speed = 3.0
	_bob_speed = 3.0
	_bob_amount = 0.2

	for i in range(3):
		var crystal := MeshInstance3D.new()
		var crystal_mesh := PrismMesh.new()
		crystal_mesh.size = Vector3(0.2, 0.6, 0.2)
		crystal.mesh = crystal_mesh
		var x_offset: float = (i - 1) * 0.25
		crystal.position = Vector3(x_offset, 0.05, 0)
		crystal.rotation.z = (i - 1) * 0.3
		var crystal_mat := _make_emissive_material(Color(0.0, 0.5, 1.0), Color(0.0, 0.4, 0.9), 2.5)
		crystal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		crystal_mat.albedo_color.a = 0.8
		crystal.set_surface_override_material(0, crystal_mat)
		$Body.add_child(crystal)

	for i in range(3):
		var crystal := MeshInstance3D.new()
		var crystal_mesh := PrismMesh.new()
		crystal_mesh.size = Vector3(0.2, 0.5, 0.2)
		crystal.mesh = crystal_mesh
		var x_offset: float = (i - 1) * 0.25
		crystal.position = Vector3(x_offset, -0.05, 0)
		crystal.rotation.z = PI + (i - 1) * 0.3
		var crystal_mat := _make_emissive_material(Color(0.1, 0.6, 1.0), Color(0.0, 0.5, 0.9), 2.0)
		crystal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		crystal_mat.albedo_color.a = 0.7
		crystal.set_surface_override_material(0, crystal_mat)
		$Body.add_child(crystal)

	var orb := MeshInstance3D.new()
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.15
	orb_mesh.height = 0.3
	orb.mesh = orb_mesh
	orb.set_surface_override_material(0, _make_emissive_material(Color(0.4, 0.8, 1.0), Color(0.2, 0.6, 1.0), 4.0))
	$Body.add_child(orb)

	$CollisionShape.shape.size = Vector3(1.5, 1.5, 1.0)
	$EnemyLight.light_color = Color(0.0, 0.5, 1.0)
	$EnemyLight.light_energy = 0.8
	$EnemyLight.omni_range = 3.0
	_set_bar_position(1.0)


func _setup_powerup_laser() -> void:
	_original_color = Color(1.0, 0.95, 0.7)
	_spin_speed = 0.0
	_bob_speed = 3.5
	_bob_amount = 0.2

	# Thin bright beam core — elongated cylinder like the laser streak projectile
	var beam := MeshInstance3D.new()
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.04
	beam_mesh.bottom_radius = 0.04
	beam_mesh.height = 0.8
	beam.mesh = beam_mesh
	var beam_mat := _make_emissive_material(Color(1.0, 0.95, 0.7), Color(1.0, 0.9, 0.5), 6.0)
	beam.set_surface_override_material(0, beam_mat)
	$Body.add_child(beam)

	# Outer glow cylinder
	var glow := MeshInstance3D.new()
	var glow_mesh := CylinderMesh.new()
	glow_mesh.top_radius = 0.08
	glow_mesh.bottom_radius = 0.08
	glow_mesh.height = 0.85
	glow.mesh = glow_mesh
	var glow_mat := _make_emissive_material(Color(1.0, 0.95, 0.7), Color(1.0, 0.85, 0.4), 3.0)
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.albedo_color.a = 0.25
	glow.set_surface_override_material(0, glow_mat)
	$Body.add_child(glow)

	# Bright tip sphere
	var tip := MeshInstance3D.new()
	var tip_mesh := SphereMesh.new()
	tip_mesh.radius = 0.07
	tip_mesh.height = 0.14
	tip.mesh = tip_mesh
	tip.position.y = 0.4
	tip.set_surface_override_material(0, _make_emissive_material(Color(1.0, 1.0, 0.9), Color(1.0, 1.0, 0.8), 8.0))
	$Body.add_child(tip)

	$CollisionShape.shape.size = Vector3(1.5, 1.5, 1.0)
	$EnemyLight.light_color = Color(1.0, 0.95, 0.7)
	$EnemyLight.light_energy = 0.8
	$EnemyLight.omni_range = 3.0
	_set_bar_position(1.0)


func _setup_powerup_plasma() -> void:
	_original_color = Color(0.2, 1.0, 0.3)
	_spin_speed = 2.0
	_bob_speed = 2.5
	_bob_amount = 0.2

	# Inner glowing core sphere — like the plasma orb projectile
	var core := MeshInstance3D.new()
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.2
	core_mesh.height = 0.4
	core.mesh = core_mesh
	core.set_surface_override_material(0, _make_emissive_material(Color(0.2, 1.0, 0.3), Color(0.1, 0.9, 0.2), 6.0))
	$Body.add_child(core)

	# Translucent outer sphere
	var shell := MeshInstance3D.new()
	var shell_mesh := SphereMesh.new()
	shell_mesh.radius = 0.35
	shell_mesh.height = 0.7
	shell.mesh = shell_mesh
	var shell_mat := _make_emissive_material(Color(0.2, 1.0, 0.3), Color(0.1, 0.8, 0.2), 3.0)
	shell_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shell_mat.albedo_color.a = 0.2
	shell.set_surface_override_material(0, shell_mat)
	$Body.add_child(shell)

	# Small orbiting energy wisps
	for i in range(4):
		var wisp := MeshInstance3D.new()
		var wisp_mesh := SphereMesh.new()
		wisp_mesh.radius = 0.06
		wisp_mesh.height = 0.12
		wisp.mesh = wisp_mesh
		var angle: float = i * TAU / 4.0
		wisp.position = Vector3(cos(angle) * 0.3, sin(angle) * 0.15, sin(angle) * 0.3)
		wisp.set_surface_override_material(0, _make_emissive_material(Color(0.4, 1.0, 0.5), Color(0.3, 0.9, 0.4), 4.0))
		$Body.add_child(wisp)

	$CollisionShape.shape.size = Vector3(1.5, 1.5, 1.0)
	$EnemyLight.light_color = Color(0.2, 1.0, 0.3)
	$EnemyLight.light_energy = 0.8
	$EnemyLight.omni_range = 3.0
	_set_bar_position(1.0)


func _make_material(color: Color, metallic_val: float, roughness_val: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic_val
	mat.roughness = roughness_val
	return mat


func _make_emissive_material(color: Color, emission_color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.3
	mat.roughness = 0.15
	mat.emission_enabled = true
	mat.emission = emission_color
	mat.emission_energy_multiplier = energy
	return mat


func _set_bar_position(height: float) -> void:
	$HPLabel.position.y = height


func _process(delta: float) -> void:
	position.z += scroll_speed * delta

	if _spin_speed > 0.0:
		$Body.rotation.y += _spin_speed * delta
	if _bob_amount > 0.0:
		$Body.position.y = sin(Time.get_ticks_msec() * 0.001 * _bob_speed) * _bob_amount

	if position.z > 5.0:
		passed.emit(self)
		queue_free()


func take_damage(amount: int) -> void:
	hp -= amount
	_update_hp_display()
	_flash_body()
	if hp <= 0:
		killed.emit(self)
		queue_free()


func _flash_body() -> void:
	for child in $Body.get_children():
		if child is MeshInstance3D:
			var mat: StandardMaterial3D = child.get_surface_override_material(0)
			if mat:
				var saved_color: Color = mat.albedo_color
				mat.albedo_color = Color.WHITE
				var tween := create_tween()
				tween.tween_property(mat, "albedo_color", saved_color, 0.12)


func _update_hp_display() -> void:
	$HPLabel.text = str(hp)
	var ratio: float = float(hp) / float(max_hp)

	# Color the label based on HP ratio: green -> yellow -> red
	var color: Color
	if ratio > 0.5:
		color = Color(0.0, 0.9, 0.0).lerp(Color(1.0, 0.9, 0.0), (1.0 - ratio) * 2.0)
	else:
		color = Color(1.0, 0.9, 0.0).lerp(Color(0.9, 0.0, 0.0), (0.5 - ratio) * 2.0)
	$HPLabel.modulate = color
