class_name GroundPhysics
extends PhysicsState


export var move_speed: float
export var acceleration: float
export var turn_speed: float
export var overshoot_speed: float

export var friction: float
export var set_facing: bool = true
export var air_name: String

export var idle_threshold: float


### Main logic

func do_movement(move_dir: int) -> void:
	var relative_vel: float = character.velocity.x * move_dir
	var factor: float
	
	# changing direction
	if relative_vel < 0:
		factor = turn_speed
	# accelerating to top speed
	elif relative_vel < move_speed:
		factor = acceleration
	# correcting down to top speed
	elif relative_vel > move_speed:
		factor = overshoot_speed
	
	character.velocity.x = move_toward(character.velocity.x, move_speed * move_dir, factor)
	
	if set_facing:
		character.facing_direction = move_dir


func do_friction() -> void:
	character.velocity.x = move_toward(character.velocity.x, 0, friction)


## runs every frame while active
func _update(_delta: float) -> void:
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
	
	## Animation
	var current_speed: float = abs(character.velocity.x)
	if current_speed > idle_threshold and not character.is_walled():
		anim_speed = 1
		if current_speed > move_speed:
			anim_speed = current_speed / move_speed
		animation = "walk"
	else:
		anim_speed = 1
		animation = "idle"
	
	## Coyote time
	character.container_override = self
	character.override_timer = 0.125


### Transitions

## runs this check every frame while inactive and 
## in the character's current pool of states
func _startup_check() -> bool:
	return character.is_grounded()


## runs this check every frame while active
## the string returned is the name of the state to change to
## return self.name for no change!
func _transition_check() -> String:
	if not character.is_grounded():
		return air_name
	return name
