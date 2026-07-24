class_name ImpactDirector
extends Node


var shake_scale := 1.0
var flash_scale := 1.0
var rumble_scale := 1.0

var _camera: CameraTrauma
var _hit_stop: HitStop
var _sfx: ProceduralSfx
var _flash: ColorRect
var _flash_strength := 0.0


func configure(camera: CameraTrauma, hit_stop: HitStop) -> void:
	_camera = camera
	_hit_stop = hit_stop


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sfx = ProceduralSfx.new()
	add_child(_sfx)

	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 20
	add_child(flash_layer)
	_flash = ColorRect.new()
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1.0, 0.91, 0.72, 0.0)
	flash_layer.add_child(_flash)


func cast_committed(power: float) -> void:
	_sfx.play_release(power)


func heavy_impact(at: Vector2, direction: Vector2, packet: DamagePacket, charge: float) -> void:
	kat_combat_impact(at, direction, packet, charge)


func kat_combat_impact(at: Vector2, direction: Vector2, packet: DamagePacket, intensity: float) -> void:
	if is_instance_valid(_hit_stop):
		_hit_stop.request(packet.hit_stop_seconds)
	if is_instance_valid(_camera):
		_camera.intensity_scale = shake_scale
		_camera.add_trauma(packet.camera_trauma)

	var effect_scale := lerpf(0.86, 1.72, clampf(intensity, 0.0, 1.0))
	VfxCatalog.spawn_world(self, &"kat_impact", at, direction, effect_scale)
	var damage_label := FloatingDamageLabel.new()
	damage_label.configure(at, packet.health_damage, direction)
	add_child(damage_label)
	_flash_strength = maxf(_flash_strength, lerpf(0.04, 0.20, intensity) * flash_scale)
	_sfx.play_impact(intensity)
	_start_rumble(packet.rumble_strength)


func sniff_combat_impact(at: Vector2, direction: Vector2, packet: DamagePacket, intensity: float) -> void:
	if is_instance_valid(_hit_stop):
		_hit_stop.request(packet.hit_stop_seconds)
	if is_instance_valid(_camera):
		_camera.intensity_scale = shake_scale
		_camera.add_trauma(packet.camera_trauma)
	VfxCatalog.spawn_world(self, &"sniff_strike", at, direction, lerpf(0.54, 1.18, clampf(intensity, 0.0, 1.0)))
	var damage_label := FloatingDamageLabel.new()
	damage_label.configure(at, packet.health_damage, direction)
	add_child(damage_label)
	_flash.color = Color(0.70, 0.95, 1.0, _flash.color.a)
	_flash_strength = maxf(_flash_strength, lerpf(0.045, 0.22, intensity) * flash_scale)
	_sfx.play_cue(&"sniff_impact", intensity)
	_start_rumble(packet.rumble_strength)


func nad_combat_impact(at: Vector2, direction: Vector2, packet: DamagePacket, intensity: float) -> void:
	if is_instance_valid(_hit_stop):
		_hit_stop.request(packet.hit_stop_seconds)
	if is_instance_valid(_camera):
		_camera.intensity_scale = shake_scale
		_camera.add_trauma(packet.camera_trauma)
	play_mental_distortion(at, lerpf(42.0, 98.0, clampf(intensity, 0.0, 1.0)), intensity, &"impact")
	var damage_label := FloatingDamageLabel.new()
	damage_label.configure(at, packet.health_damage, direction)
	add_child(damage_label)
	_flash.color = Color(0.68, 1.0, 0.84, _flash.color.a)
	_flash_strength = maxf(_flash_strength, lerpf(0.035, 0.20, intensity) * flash_scale)
	_sfx.play_cue(&"nad_impact", intensity)
	_start_rumble(packet.rumble_strength)


func fin_combat_impact(at: Vector2, direction: Vector2, packet: DamagePacket, intensity: float) -> void:
	if is_instance_valid(_hit_stop):
		_hit_stop.request(packet.hit_stop_seconds)
	if is_instance_valid(_camera):
		_camera.intensity_scale = shake_scale
		_camera.add_trauma(packet.camera_trauma)
	var effect_id := &"fin_cut"
	var tint := Color("a7ead8")
	if packet.tags.has(&"crossbow") or packet.tags.has(&"bow") or packet.tags.has(&"projectile"):
		effect_id = &"fin_shot"
		tint = Color("f1cf69")
	if packet.tags.has(&"object"):
		effect_id = &"fin_tool"
		tint = Color("66d3bd")
	VfxCatalog.spawn_world(self, effect_id, at, direction, lerpf(0.66, 1.48, clampf(intensity, 0.0, 1.0)), tint)
	var damage_label := FloatingDamageLabel.new()
	damage_label.configure(at, packet.health_damage, direction)
	add_child(damage_label)
	_flash.color = Color(0.84, 0.96, 0.78, _flash.color.a)
	_flash_strength = maxf(_flash_strength, lerpf(0.035, 0.21, intensity) * flash_scale)
	_sfx.play_cue(&"fin_impact", intensity)
	_start_rumble(packet.rumble_strength)


func enemy_attack_impact(at: Vector2, direction: Vector2, packet: DamagePacket, intensity: float) -> void:
	if is_instance_valid(_camera):
		_camera.add_trauma(packet.camera_trauma * 0.72)
	VfxCatalog.spawn_world(self, &"kat_impact", at, -direction, lerpf(0.72, 1.15, intensity), Color(1.0, 0.42, 0.32, 0.92))
	_flash_strength = maxf(_flash_strength, 0.08 * intensity * flash_scale)
	_start_rumble(packet.rumble_strength * 0.72)


func play_effect(effect_id: StringName, at: Vector2, direction: Vector2, size_scale: float) -> void:
	if effect_id == &"nad_probe":
		play_mental_distortion(at, 72.0 * size_scale, 0.42, &"probe")
		return
	var effect := VfxCatalog.spawn_world(self, effect_id, at, direction, size_scale)
	match effect_id:
		&"fin_cut":
			effect.modulate = Color("a9ead9")
		&"fin_shot":
			effect.modulate = Color("f1cd66")
		&"fin_shadow":
			effect.modulate = Color("589b94")
		&"fin_tool":
			effect.modulate = Color("62d2ba")
		&"fin_smoke":
			effect.modulate = Color(0.28, 0.54, 0.42, 0.72)
		&"fin_step":
			effect.modulate = Color("70d4c0")
		&"fin_switch":
			effect.modulate = Color("dce98c")
	if effect_id == &"sniff_blessing":
		effect.z_index = 11
	if effect_id == &"kat_communion":
		if is_instance_valid(_camera):
			_camera.add_trauma(0.88)
		_flash_strength = maxf(_flash_strength, 0.28 * flash_scale)
		_start_rumble(1.0)


func play_lightning_arc(from: Vector2, to: Vector2, power: float) -> void:
	var arc := LightningArc.new()
	add_child(arc)
	arc.configure(from, to, power)


func play_mind_link(from: Vector2, to: Vector2, power: float) -> void:
	var link := MindLink.new()
	add_child(link)
	link.configure(from, to, power)


func play_mental_distortion(at: Vector2, radius: float, power: float, kind: StringName) -> void:
	var distortion := MentalDistortion.new()
	add_child(distortion)
	distortion.configure(at, radius, power, kind)
	if kind == &"conduit":
		if is_instance_valid(_camera):
			_camera.add_trauma(1.0)
		_flash.color = Color(0.72, 1.0, 0.78, _flash.color.a)
		_flash_strength = maxf(_flash_strength, 0.30 * flash_scale)
		_start_rumble(1.0)
	elif kind == &"anchor_detonate" or kind == &"mantle":
		if is_instance_valid(_camera):
			_camera.add_trauma(lerpf(0.18, 0.48, power))
		_flash_strength = maxf(_flash_strength, lerpf(0.04, 0.13, power) * flash_scale)
		_start_rumble(lerpf(0.22, 0.58, power))


func play_thunder_burst(at: Vector2, radius: float, power: float, ultimate: bool) -> void:
	var burst := ThunderBurst.new()
	add_child(burst)
	burst.configure(at, radius, power, ultimate)
	var effect_id := &"sniff_annihilation" if ultimate else &"sniff_surge"
	var sheet_scale := radius / (150.0 if ultimate else 78.0)
	VfxCatalog.spawn_world(self, effect_id, at, Vector2.RIGHT, sheet_scale)
	if is_instance_valid(_camera):
		_camera.add_trauma(0.96 if ultimate else lerpf(0.28, 0.68, power))
	_flash.color = Color(0.83, 0.97, 1.0, _flash.color.a)
	_flash_strength = maxf(_flash_strength, (0.32 if ultimate else lerpf(0.08, 0.18, power)) * flash_scale)
	_start_rumble(1.0 if ultimate else lerpf(0.34, 0.82, power))


func play_audio(cue: StringName, power: float) -> void:
	_sfx.play_cue(cue, power)


func play_guard_impact(at: Vector2, direction: Vector2, perfect: bool, power: float) -> void:
	var strength := clampf(power / 38.0, 0.25, 1.0)
	VfxCatalog.spawn_world(self, &"kat_impact", at, direction, 1.15 + strength * 0.45, Color(0.92, 0.72, 1.0, 1.0))
	VfxCatalog.spawn_world(self, &"kat_absorb", at, direction, 0.92 + strength * 0.28)
	if is_instance_valid(_hit_stop):
		_hit_stop.request(0.055 if perfect else 0.032)
	if is_instance_valid(_camera):
		_camera.add_trauma(0.38 if perfect else 0.20)
	_flash_strength = maxf(_flash_strength, (0.17 if perfect else 0.08) * flash_scale)
	_start_rumble(0.72 if perfect else 0.38)


func _process(delta: float) -> void:
	_flash_strength = move_toward(_flash_strength, 0.0, delta * 3.8)
	if is_instance_valid(_flash):
		_flash.color.a = _flash_strength


func _start_rumble(strength: float) -> void:
	if rumble_scale <= 0.0:
		return
	var scaled := clampf(strength * rumble_scale, 0.0, 1.0)
	for device: int in Input.get_connected_joypads():
		Input.start_joy_vibration(device, scaled * 0.62, scaled, 0.13)