class_name SniffLightningDart
extends Area2D


const SPEED := 1040.0
const LIFETIME := 0.82

var _owner: SniffPlayer
var _direction := Vector2.RIGHT
var _blessing_snapshot := 0
var _remaining := LIFETIME
var _visual_time := 0.0
var _resolved := false


func configure(owner: SniffPlayer, direction: Vector2, blessing_snapshot: int) -> void:
	_owner = owner
	_direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	_blessing_snapshot = clampi(blessing_snapshot, 0, SniffPlayer.MAX_BLESSING)
	rotation = _direction.angle()


func _ready() -> void:
	collision_layer = 8
	collision_mask = 16
	monitoring = true
	monitorable = false
	z_index = 18

	var collision_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 11.0
	collision_shape.shape = circle
	add_child(collision_shape)
	area_entered.connect(_on_area_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	global_position += _direction * SPEED * delta
	_remaining -= delta
	_visual_time += delta
	queue_redraw()
	if _remaining <= 0.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _resolved:
		return
	var target := area.get_parent() as Node2D
	if not is_instance_valid(target) or not target.is_in_group(&"enemies"):
		return
	_resolved = true
	set_deferred(&"monitoring", false)
	if is_instance_valid(_owner):
		_owner.on_lightning_dart_hit(target, global_position, _direction, _blessing_snapshot)
	queue_free()


func _draw() -> void:
	var pulse := 0.82 + sin(_visual_time * 48.0) * 0.18
	draw_circle(Vector2.ZERO, 15.0, Color(0.10, 0.82, 1.0, 0.16 * pulse))
	draw_circle(Vector2.ZERO, 7.0, Color(0.98, 0.91, 0.35, 0.95))
	var points := PackedVector2Array([
		Vector2(-33.0, 0.0),
		Vector2(-24.0, -5.0),
		Vector2(-15.0, 4.0),
		Vector2(-6.0, -3.0),
		Vector2(5.0, 2.0),
		Vector2(15.0, 0.0),
	])
	draw_polyline(points, Color(0.10, 0.72, 1.0, 0.32), 8.0, true)
	draw_polyline(points, Color(0.91, 0.98, 1.0, 0.95), 2.0, true)