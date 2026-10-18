class_name TripleJumpAction
extends ActionState


export var launch_power: float
export var jump_power: float

var jump_released: bool = false
const HEIGHT_MULT: float = 0.7


### Main logic

## runs once when this state begins being active
func _on_enter() -> void:
	jump_released = false
	character.velocity.x += launch_power * character.facing_direction
	character.velocity.y = min(-jump_power, character.velocity.y)


## runs every frame while active
func _update(_delta: float):
	## jump height variation
	if not jump_released and not character.inputs[Character.input_names.jump][0]:
		jump_released = true
		character.velocity.y *= HEIGHT_MULT


### Transitions

## runs this check every frame while active
## the string returned is the name of the state to change to
## return self.name for no change!
func _transition_check() -> String:
	if character.velocity.y > 2 or character.physics is GroundPhysics:
		return ""
	return name
