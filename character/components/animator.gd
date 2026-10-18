class_name CharacterAnimator
extends AnimatedSprite


onready var base_offset: Vector2 = position
onready var character: Character = owner
var cur_anim: String


func _update(_delta: float) -> void:
	var new_anim: String
	
	var anim_speed: float = 1
	var sprite_offset: Vector2
	var sprite_rot: float
	var sprite_scale := Vector2.ONE
	var is_directional: bool
	
	if is_instance_valid(character.action):
		new_anim = character.action.animation
		anim_speed = character.action.anim_speed
		is_directional = character.action.anim_is_directional
		sprite_offset = character.action.sprite_offset
		sprite_rot = character.action.sprite_rot
		sprite_scale = character.action.sprite_scale
	
	if is_instance_valid(character.physics):
		if new_anim == "":
			new_anim = character.physics.animation
			anim_speed = character.physics.anim_speed
			sprite_offset = character.physics.sprite_offset
			is_directional = character.physics.anim_is_directional
		
		sprite_rot += character.physics.sprite_rot
		sprite_scale *= character.physics.sprite_scale
	
	position = base_offset + sprite_offset
	rotation = sprite_rot * character.facing_direction
	scale = sprite_scale * Vector2(character.facing_direction, 1)
	speed_scale = anim_speed
	
	if is_directional:
		new_anim = "%s_%s" % [new_anim, "right" if character.facing_direction > 0 else "left"]
	if cur_anim != new_anim:
		cur_anim = new_anim
		play(new_anim)
