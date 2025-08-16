extends Node2D

@onready var platformAnimation: AnimationPlayer = get_node("platform/AnimationPlayer")
@onready var handleAnimation: AnimationPlayer = get_node("handle/AnimationPlayer")

@onready var blocSheepStatic: StaticBody2D = get_node('platform/blocSheep')
@onready var blocSheepCollShape: CollisionShape2D = get_node('platform/blocSheep/blocSheep')

var pendingCarried = null

#enum PLATFORM_ANIM {UP="move_up",DOWN="move_down"}
#enum HANDLE_ANIM {UP="turn_up",DOWN="turn_down"}

var platformAnimList = {
	STATE.UP: "moving_up",
	STATE.DOWN: "moving_down",
}

var handleAnimList = {
	STATE.UP: "turn_up",
	STATE.DOWN: "turn_down",
}

enum STATE {UP, DOWN}

var state = STATE.DOWN
var isAnimationRunning = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	platformAnimation.play("RESET")
	handleAnimation.play("RESET")

	blocSheepCollShape.disabled = true
	
 
func turned_up():
	platformAnimation.play(platformAnimList[STATE.UP])

func turned_down():
	platformAnimation.play(platformAnimList[STATE.DOWN])

func action():
	if isAnimationRunning:
		return
	
	if pendingCarried:
		pendingCarried.be_carried()
		
	isAnimationRunning = true
	if state == STATE.UP:
		handleAnimation.play(handleAnimList[STATE.DOWN])
	elif state == STATE.DOWN:
		handleAnimation.play(handleAnimList[STATE.UP])
 

func _on_handle_area_body_entered(body: Node2D) -> void:
	if body is Player:
		if state == STATE.UP or state == STATE.DOWN:
			body.set_pending_action(self)

func _on_handle_area_body_exited(body: Node2D) -> void:
	if body is Player:
		body.reset_pending_action()
	pass # Replace with function body.
	
func switch_state():
	if state == STATE.UP:
		state = STATE.DOWN

		blocSheepCollShape.disabled = true

	else:
		state = STATE.UP

		blocSheepCollShape.disabled = false

	
	isAnimationRunning = false
	if pendingCarried:
		pendingCarried.walk_right()


func _on_carry_area_2d_body_entered(body: Node2D) -> void:
	if body is Sheep:
		pendingCarried = body
	pass # Replace with function body.


func _on_carry_area_2d_body_exited(body: Node2D) -> void:
	if body is Sheep:
		pendingCarried = null
	pass # Replace with function body.
