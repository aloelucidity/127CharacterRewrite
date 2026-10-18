class_name State
extends Node

## Note that the way physics states relate to action states, is different than you may expect.
## Don't think of it as, say, "You can only be in the Jump action while using Ground physics"
## It's more like, "The Jump action can only start itself while using Ground physics"
## Any action can be paired with any physics. It's better for flexibility, that way.

export var priority: int = 0 ## note that states won't override others with the same priority by default
export var allow_priority_override: bool ## if this is set to true, other states with the same priority can override this one
export var gravity_factor: float = 1
export var override_size: bool
export var custom_size: Vector2

export var animation: String
export var anim_speed: float = 1
export var sprite_offset: Vector2
export var sprite_rot: float
export var sprite_scale := Vector2.ONE

export var anim_is_directional: bool
export var disable_snap: bool


# can't be type hinted because UGH cyclic dependency
var character
func _enter_tree() -> void:
	character = get_owner()


## runs this check every frame while inactive and 
## in the character's current pool of states
func _startup_check() -> bool:
	return false


## runs this check every frame while active
## the string returned is the name of the state to change to
## return self.name for no change!
func _transition_check() -> String:
	return name


## runs every frame while active
func _update(_delta: float) -> void:
	pass


## runs once when this state begins being active
func _on_enter() -> void:
	pass


## runs once when this state stops being active
func _on_exit() -> void:
	pass


## always runs no matter what, before any of the other functions
func _general_update(_delta: float) -> void:
	pass
