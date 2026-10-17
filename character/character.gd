class_name Character
extends KinematicBody2D


const move_speed: float = 216.0
const acceleration: float = 16.0
const deceleration: float = 30.0
const friction: float = 27.0

const aerial_acceleration: float = 16.0
const aerial_friction: float = 2.3
const max_aerial_velocity: float = 640.0

const GRAVITY: float = 7.82

onready var collision = $"%Collision"

var velocity: Vector2
var facing_direction: int


func is_grounded() -> bool:
	return collision.floor_info[0]


func _physics_process(delta: float):
	var x_axis: float = Input.get_axis("ui_left", "ui_right")
	var move_direction: int = int(sign(x_axis))
	
	# Horizontal physics
	if move_direction != 0:
		if is_grounded():
			# Accelerate/decelerate
			if velocity.x * move_direction < 0: #why. just why. you already have the move direction, dingus.
				velocity.x += deceleration * move_direction
			elif velocity.x * move_direction < move_speed:
				velocity.x += acceleration * move_direction
			elif velocity.x * move_direction > move_speed:
				velocity.x -= 3.5 * move_direction
			facing_direction = move_direction
		else:
			if velocity.x * move_direction < move_speed:
				velocity.x += aerial_acceleration * move_direction
			elif velocity.x * move_direction > move_speed:
				velocity.x -= 0.25 * move_direction
			facing_direction = move_direction
	
	else:
		if abs(velocity.x) > 0:
			if abs(velocity.x) > 15:
				var new_velocity
				if is_grounded():
					velocity.x -= sign(velocity.x) * friction
				else:
					new_velocity = sign(velocity.x) * aerial_friction * (2 if abs(velocity.x) > move_speed else 1)
					velocity.x -= new_velocity
			else:
				velocity.x = 0
	
	if not is_grounded():
		velocity.y += GRAVITY * 2
	velocity.y = min(velocity.y, max_aerial_velocity)
	
	if Input.is_action_just_pressed("ui_accept"):
		velocity.y = -400
	
	collision.update_collision(delta)
