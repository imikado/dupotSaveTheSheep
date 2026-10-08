extends RefCounted
class_name Fx

## Small visual feedback helpers (particles, flashes, camera shake, popups).
## All effects are fire-and-forget and free themselves.

const COLOR_WATER := Color(0.45, 0.8, 1.0)
const COLOR_DUST := Color(0.75, 0.68, 0.6)
const COLOR_SMOKE := Color(0.55, 0.55, 0.6)
const COLOR_HEAL := Color(1.0, 0.85, 0.3)

const FONT := preload("res://src/UI/Controls/Shared/Pixeled.ttf")


static func burst(parent: Node, at: Vector2, color: Color, amount := 8, speed := 40.0, spread := 180.0, direction := Vector2.UP, lifetime := 0.4, gravity := 120.0) -> void:
	if !is_instance_valid(parent) or !parent.is_inside_tree():
		return
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = amount
	particles.lifetime = lifetime
	particles.direction = direction
	particles.spread = spread
	particles.initial_velocity_min = speed * 0.5
	particles.initial_velocity_max = speed
	particles.gravity = Vector2(0, gravity)
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	particles.color = color
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 1))
	ramp.set_color(1, Color(1, 1, 1, 0))
	particles.color_ramp = ramp
	particles.z_index = 20
	particles.z_as_relative = false
	parent.add_child(particles)
	particles.global_position = at
	particles.finished.connect(particles.queue_free)
	particles.emitting = true


static func dust(parent: Node, at: Vector2) -> void:
	burst(parent, at, COLOR_DUST, 6, 30.0, 70.0, Vector2.UP, 0.35, 60.0)


static func splash(parent: Node, at: Vector2) -> void:
	burst(parent, at, COLOR_WATER, 10, 60.0, 180.0, Vector2.UP, 0.4, 200.0)


static func smoke(parent: Node, at: Vector2) -> void:
	burst(parent, at, COLOR_SMOKE, 16, 35.0, 180.0, Vector2.UP, 0.7, -20.0)


static func sparkle(parent: Node, at: Vector2, color: Color) -> void:
	burst(parent, at, color, 10, 45.0, 180.0, Vector2.UP, 0.5, 40.0)


static func flash(target: CanvasItem, color := Color(2.5, 2.5, 2.5)) -> void:
	if !is_instance_valid(target) or !target.is_inside_tree():
		return
	var tween := target.create_tween()
	target.modulate = color
	tween.tween_property(target, "modulate", Color.WHITE, 0.15)


static func popup_text(parent: Node, at: Vector2, text: String, color := Color.WHITE) -> void:
	if !is_instance_valid(parent) or !parent.is_inside_tree():
		return
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.z_index = 30
	label.z_as_relative = false
	parent.add_child(label)
	label.global_position = at - Vector2(8, 8)
	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 20, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


## Shakes the camera of the viewport [param node] is rendered in.
static func shake(node: Node, strength := 3.0, duration := 0.25) -> void:
	if !is_instance_valid(node) or !node.is_inside_tree():
		return
	var camera := node.get_viewport().get_camera_2d()
	if camera == null:
		return
	if !camera.has_meta("fx_base_offset"):
		camera.set_meta("fx_base_offset", camera.offset)
	if camera.has_meta("fx_shake_tween"):
		var previous: Tween = camera.get_meta("fx_shake_tween")
		if previous and previous.is_valid():
			previous.kill()
	var base_offset: Vector2 = camera.get_meta("fx_base_offset")
	var tween := camera.create_tween()
	var steps := maxi(int(duration / 0.03), 1)
	for i in steps:
		var amount := strength * (1.0 - float(i) / steps)
		tween.tween_property(camera, "offset", base_offset + Vector2(randf_range(-amount, amount), randf_range(-amount, amount)), 0.03)
	tween.tween_property(camera, "offset", base_offset, 0.03)
	camera.set_meta("fx_shake_tween", tween)
