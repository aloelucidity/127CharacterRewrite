class_name JumpAction
extends ActionState


export(Array, float) var jump_powers
export var triple_jump_threshold: float
export var triple_jump_path: NodePath
export var air_path: NodePath
export var somersault_path: NodePath
export var max_jumps: int

var jump_sequence: int
var reset_timer: float
var pressed_buffer: float

var jump_released: bool = false
const HEIGHT_MULT: float = 0.7


### Main logic

## runs once when this state begins being active
func _on_enter() -> void:
	jump_released = false
	
	## triple jump
	if jump_sequence >= max_jumps - 1 and abs(character.velocity.x) > triple_jump_threshold:
		character.set_state("action", get_node(triple_jump_path))
		character.set_state("physics", get_node(somersault_path))
		reset_timer = 0
	## single and double jump
	else:
		jump_sequence = min(jump_sequence, max_jumps - 2)
		character.set_state("physics", get_node(air_path))
		character.velocity.y = min(-jump_powers[jump_sequence], character.velocity.y)
	
	jump_sequence += 1
	reset_timer = 0.175
	if jump_sequence >= max_jumps:
		jump_sequence = 0
		reset_timer = 0


## runs every frame while active
func _update(_delta: float):
	## jump height variation
	if not jump_released and not character.inputs[Character.input_names.jump][0]:
		jump_released = true
		character.velocity.y *= HEIGHT_MULT


## always runs no matter what, before any of the other functions
func _general_update(delta: float) -> void:
	var jump_just_pressed: bool = character.inputs[Character.input_names.jump][1]
	if jump_just_pressed:
		pressed_buffer = 0.075
	else:
		pressed_buffer -= delta
	
	if character.is_grounded():
		reset_timer -= delta
		reset_timer = max(reset_timer, 0)
		if reset_timer == 0:
			jump_sequence = 0


### Transitions

## runs this check every frame while inactive and 
## in the character's current pool of states
func _startup_check() -> bool:
	return pressed_buffer > 0 and character.velocity.y >= -3 and character.is_grounded()


## runs this check every frame while active
## the string returned is the name of the state to change to
## return self.name for no change!
func _transition_check() -> String:
	if character.velocity.y > 2 or character.physics is GroundPhysics:
		return ""
	return name
