extends Area2D

const TUMBLEWEED = 2

var hit := false

@onready var _sprite: Sprite2D = $BonusObstacles

func _ready():
	_sprite.frame = randi() % _sprite.hframes

# The tumbleweed rolls towards the bike
func _process(delta):
	if _sprite.frame == TUMBLEWEED and !hit:
		_sprite.rotation -= delta * 6.0

func _on_body_entered(body):
	if hit or !(body is PlayerOnMotorBike) or body.is_invincible():
		return
	hit = true
	GlobalEvents.motorbike_hit_obstacle.emit()
	_knock_away()

# The bike sends the obstacle flying instead of driving through it
func _knock_away():
	set_deferred("monitoring", false)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(90, -60), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", 4.0, 0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.2)
	tween.chain().tween_callback(queue_free)
