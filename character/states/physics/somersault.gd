extends AirPhysics


export var air_name: String


### Transitions

## runs this check every frame while inactive and 
## in the character's current pool of states
func _startup_check() -> bool:
	return false

## runs this check every frame while active
## the string returned is the name of the state to change to
## return self.name for no change!
func _transition_check() -> String:
	if character.velocity.y > 0:
		return air_name
	return ._transition_check()
