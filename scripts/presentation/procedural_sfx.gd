class_name ProceduralSfx
extends Node


const MIX_RATE := 44100

var _release_stream: AudioStreamWAV
var _impact_stream: AudioStreamWAV
var _magic_stream: AudioStreamWAV
var _guard_stream: AudioStreamWAV
var _electric_stream: AudioStreamWAV
var _thunder_stream: AudioStreamWAV


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_release_stream = _build_release_stream()
	_impact_stream = _build_impact_stream()
	_magic_stream = _build_magic_stream()
	_guard_stream = _build_guard_stream()
	_electric_stream = _build_electric_stream()
	_thunder_stream = _build_thunder_stream()


func play_release(power: float) -> void:
	_play_one_shot(_release_stream, lerpf(-9.0, -3.5, clampf(power, 0.0, 1.0)), 0.94 + power * 0.08)


func play_impact(power: float) -> void:
	_play_one_shot(_impact_stream, lerpf(-7.0, -1.5, clampf(power, 0.0, 1.0)), 0.88 + power * 0.08)


func play_cue(cue: StringName, power: float) -> void:
	var strength := clampf(power, 0.0, 1.0)
	match cue:
		&"kat_swing":
			_play_one_shot(_release_stream, lerpf(-11.0, -5.0, strength), 1.12 + strength * 0.22)
		&"kat_slam_charge":
			_play_one_shot(_release_stream, lerpf(-8.0, -3.0, strength), 0.72 + strength * 0.10)
		&"kat_guard_raise":
			_play_one_shot(_guard_stream, -9.0, 0.92)
		&"kat_guard":
			_play_one_shot(_guard_stream, lerpf(-7.0, -2.5, strength), 0.86)
		&"kat_perfect_guard":
			_play_one_shot(_guard_stream, -1.5, 1.26)
			_play_one_shot(_magic_stream, -7.0, 1.34)
		&"kat_march":
			_play_one_shot(_release_stream, -5.0, 0.76)
			_play_one_shot(_guard_stream, -8.0, 0.72)
		&"kat_summon":
			_play_one_shot(_magic_stream, -4.5, 1.08)
		&"kat_halo":
			_play_one_shot(_magic_stream, -3.0, 0.74)
		&"kat_drain":
			_play_one_shot(_magic_stream, lerpf(-12.0, -6.0, strength), 1.20)
		&"kat_ultimate_charge":
			_play_one_shot(_magic_stream, -1.5, 0.52)
			_play_one_shot(_release_stream, -8.0, 0.48)
		&"kat_ultimate":
			_play_one_shot(_impact_stream, 0.0, 0.61)
			_play_one_shot(_magic_stream, -1.0, 0.58)
		&"kat_hurt":
			_play_one_shot(_impact_stream, lerpf(-13.0, -7.0, strength), 1.18)
		&"sniff_dart_charge":
			_play_one_shot(_electric_stream, -12.0, 1.28 + strength * 0.20)
		&"sniff_dart":
			_play_one_shot(_electric_stream, lerpf(-9.0, -4.5, strength), 1.42 + strength * 0.16)
			_play_one_shot(_release_stream, -13.0, 1.35)
		&"sniff_chain":
			_play_one_shot(_electric_stream, lerpf(-10.0, -5.0, strength), 1.66)
		&"sniff_impact":
			_play_one_shot(_electric_stream, lerpf(-13.0, -7.0, strength), 0.92)
		&"sniff_dash_charge":
			_play_one_shot(_magic_stream, -12.0, 1.18)
		&"sniff_dash":
			_play_one_shot(_electric_stream, lerpf(-7.5, -2.5, strength), 0.74 + strength * 0.18)
			_play_one_shot(_release_stream, -7.0, 1.32)
		&"sniff_blessing":
			_play_one_shot(_magic_stream, -4.0, 1.36)
			_play_one_shot(_electric_stream, -7.0, 1.52)
		&"sniff_crowned":
			_play_one_shot(_magic_stream, -1.5, 1.62)
			_play_one_shot(_electric_stream, -5.0, 1.78)
		&"sniff_surge_charge":
			_play_one_shot(_magic_stream, lerpf(-10.0, -4.0, strength), 0.62)
		&"sniff_surge":
			_play_one_shot(_thunder_stream, lerpf(-5.0, 0.0, strength), 1.14)
			_play_one_shot(_electric_stream, -3.0, 0.72)
		&"sniff_step":
			_play_one_shot(_electric_stream, -6.0, 1.82)
		&"sniff_ultimate_charge":
			_play_one_shot(_magic_stream, -1.0, 0.42)
			_play_one_shot(_electric_stream, -7.0, 0.46)
		&"sniff_ultimate":
			_play_one_shot(_thunder_stream, 0.0, 0.72)
			_play_one_shot(_impact_stream, -1.0, 0.54)
			_play_one_shot(_magic_stream, -3.0, 0.58)
		&"sniff_phase":
			_play_one_shot(_electric_stream, -9.0, 1.92)
		&"sniff_hurt":
			_play_one_shot(_impact_stream, lerpf(-14.0, -8.0, strength), 1.36)
		&"enemy_windup":
			_play_one_shot(_magic_stream, -13.0, 0.82 + strength * 0.12)
		&"enemy_swing":
			_play_one_shot(_release_stream, -9.0, 0.84 + strength * 0.10)
		&"enemy_break":
			_play_one_shot(_guard_stream, -4.0, 0.66)
		&"enemy_defeat":
			_play_one_shot(_magic_stream, -5.0, 0.58)
		_:
			_play_one_shot(_release_stream, -10.0, 1.0)


func _play_one_shot(stream: AudioStreamWAV, volume_db: float, pitch_scale: float) -> void:
	var player := AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _build_release_stream() -> AudioStreamWAV:
	var duration := 0.22
	var sample_count := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index: int in sample_count:
		var time := float(index) / float(MIX_RATE)
		var progress := time / duration
		var envelope := sin(PI * clampf(progress, 0.0, 1.0)) * (1.0 - progress * 0.35)
		var phase := TAU * (150.0 * time + 460.0 * time * time)
		var sample := sin(phase) * 0.52 + sin(phase * 0.49) * 0.18
		data.encode_s16(index * 2, int(clampf(sample * envelope, -1.0, 1.0) * 32767.0))
	return _make_stream(data)


func _build_impact_stream() -> AudioStreamWAV:
	var duration := 0.34
	var sample_count := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index: int in sample_count:
		var time := float(index) / float(MIX_RATE)
		var progress := time / duration
		var envelope := pow(1.0 - clampf(progress, 0.0, 1.0), 2.4)
		var bass := sin(TAU * (72.0 - progress * 24.0) * time) * 0.68
		var crack := sin(float(index) * 12.9898) * exp(-time * 34.0) * 0.24
		var body := sin(TAU * 154.0 * time) * exp(-time * 11.0) * 0.22
		var sample := (bass + crack + body) * envelope
		data.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _make_stream(data)


func _build_magic_stream() -> AudioStreamWAV:
	var duration := 0.46
	var sample_count := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index: int in sample_count:
		var time := float(index) / float(MIX_RATE)
		var progress := time / duration
		var envelope := sin(PI * clampf(progress, 0.0, 1.0)) * pow(1.0 - progress, 0.45)
		var rising_phase := TAU * (92.0 * time + 270.0 * time * time)
		var shimmer := sin(rising_phase) * 0.44 + sin(rising_phase * 2.01) * 0.16 + sin(rising_phase * 3.97) * 0.08
		var sample := shimmer * envelope
		data.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _make_stream(data)


func _build_guard_stream() -> AudioStreamWAV:
	var duration := 0.28
	var sample_count := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index: int in sample_count:
		var time := float(index) / float(MIX_RATE)
		var envelope := exp(-time * 13.0)
		var metal := sin(TAU * 620.0 * time) * 0.34 + sin(TAU * 943.0 * time) * 0.20
		var body := sin(TAU * 116.0 * time) * 0.38
		var sample := (metal + body) * envelope
		data.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _make_stream(data)


func _build_electric_stream() -> AudioStreamWAV:
	var duration := 0.20
	var sample_count := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index: int in sample_count:
		var time := float(index) / float(MIX_RATE)
		var progress := time / duration
		var envelope := pow(1.0 - clampf(progress, 0.0, 1.0), 1.45)
		var crackle := sin(float(index) * 8.731 + sin(float(index) * 0.113) * 4.0) * 0.34
		var spark := sin(TAU * (720.0 + sin(time * 91.0) * 260.0) * time) * 0.38
		var body := sin(TAU * 182.0 * time) * 0.20
		var sample := (crackle + spark + body) * envelope
		data.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _make_stream(data)


func _build_thunder_stream() -> AudioStreamWAV:
	var duration := 0.66
	var sample_count := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index: int in sample_count:
		var time := float(index) / float(MIX_RATE)
		var progress := time / duration
		var envelope := pow(1.0 - clampf(progress, 0.0, 1.0), 1.8)
		var sub := sin(TAU * (54.0 - progress * 18.0) * time) * 0.72
		var body := sin(TAU * 104.0 * time) * exp(-time * 5.2) * 0.34
		var crack := sin(float(index) * 14.193) * exp(-time * 28.0) * 0.31
		var sample := (sub + body + crack) * envelope
		data.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	return _make_stream(data)


func _make_stream(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream