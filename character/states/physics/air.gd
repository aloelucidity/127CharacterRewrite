class_name AirPhysics
extends PhysicsState


export var move_speed: float
export var acceleration: float
export var overshoot_speed: float

export var friction: float
export var overshoot_friction: float
export var set_facing: bool = true

export var ground_name: String


### Main logic

func do_movement(move_dir: int) -> void:
	var relative_vel: float = character.velocity.x * move_dir
	var factor: float
	
	# accelerating to top speed
	if relative_vel < move_speed:
		factor = acceleration
	# correcting down to top speed
	elif relative_vel > move_speed:
		factor = overshoot_speed
	
	character.velocity.x = move_toward(character.velocity.x, move_speed * move_dir, factor)
	
	if set_facing:
		character.facing_direction = move_dir


func do_friction() -> void:
	var working_friction: float = friction
	if abs(character.velocity.x) > move_speed:
		working_friction = overshoot_friction
	
	character.velocity.x = move_toward(character.velocity.x, 0, working_friction)


## runs every frame while active
func _update() -> void:
	## Gravity
	var total_gravity: float = character.get_gravity_sum()
	character.velocity.y += total_gravity
	
	## Movement
	var move_dir: int = 0
	if character.inputs[Character.input_names.left][0]: 
		move_dir -= 1
	if character.inputs[Character.input_names.right][0]: 
		move_dir += 1
	
	if move_dir != 0:
		do_movement(move_dir)
	else:
		do_friction()


### Transitions

## runs this check every frame while inactive and 
## in the character's current pool of states
func _startup_check() -> bool:
	return not character.is_grounded()

## runs this check every frame while active
## the string returned is the name of the state to change to
## return self.name for no change!
func _transition_check() -> String:
	if character.is_grounded():
		return ground_name
	return name
