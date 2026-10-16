class_name CharacterCollision
extends Node2D


export var draw_debug: bool
onready var character: Character = owner

var ceiling_rays: Array
var ceiling_rays_open: Array

var floor_rays: Array
var floor_rays_open: Array

var left_rays: Array
var left_rays_open: Array

var right_rays: Array
var right_rays_open: Array

## cached after every update
var ceiling_info: Array = [false]
var floor_info: Array = [false]
var left_info: Array = [false]
var right_info: Array = [false]
var found_transform = null
var last_transform = null
##

const FLOOR_THRESHOLD: float = 0.5


func edge_from_normal(normal: Vector2) -> Vector2:
	# if edge is a floor
	if normal.y <= -FLOOR_THRESHOLD:
		return Vector2.UP
	# if edge is a ceiling
	elif normal.y >= FLOOR_THRESHOLD:
		return Vector2.DOWN
	else:
		# pointing right or left?
		if normal.x > 0:
			return Vector2.RIGHT
		else:
			return Vector2.LEFT



func update_collision(delta: float) -> void:
	var space_state: Physics2DDirectSpaceState = get_world_2d().direct_space_state
	
	## PLATFORM TRANSFORMS
	handle_platform_transforms()
	
	## RAY CHECKS
	# snapping further when going down on a slope
	var slope_offset: float = 0.0
	if floor_info[CollisionHelper.IS_COLLIDING] and character.velocity.x != 0:
		slope_offset = abs(character.velocity.x) * delta * (1.0 - floor_info[CollisionHelper.EDGE_NORMAL].y)
	
	# you only want to collide if the face is pointing away
	left_info = ray_array_check(delta, space_state, Vector2.RIGHT, left_rays)
	right_info = ray_array_check(delta, space_state, Vector2.LEFT, right_rays)
	ceiling_info = ray_array_check(delta, space_state, Vector2.DOWN, ceiling_rays)
	floor_info = ray_array_check(delta, space_state, Vector2.UP, floor_rays, Vector2(0, slope_offset))
	
	## APPLY VELOCITY
	character.position += character.velocity * delta
	
	## RESOLVE RAYS
	resolve_ray(delta, left_info, Vector2(-1, 0))
	resolve_ray(delta, right_info, Vector2(1, 0))
	resolve_ray(delta, ceiling_info, Vector2(0, -1))
	resolve_ray(delta, floor_info, Vector2(0, 1))
	
	if draw_debug:
		update() # redraw


func handle_platform_transforms() -> void:
	if found_transform != null:
		var pos_transform := Transform2D(0, character.position)
		pos_transform = pos_transform * found_transform
		character.position = pos_transform.origin
		
		if last_transform == null:
			var vel_transform := Transform2D(0, character.velocity)
			vel_transform = vel_transform * found_transform.affine_inverse()
			character.velocity = vel_transform.origin
		
	elif last_transform != null:
		var empty_transform := Transform2D(0, Vector2.ZERO)
		empty_transform = empty_transform * last_transform
		
		character.velocity = character.velocity + empty_transform.origin
		
	last_transform = found_transform
	found_transform = null


func resolve_ray(delta: float, intersect_info: Array, ray_direction: Vector2) -> void:
	if not intersect_info[CollisionHelper.IS_COLLIDING]: return
	
	var dir_absolute: Vector2 = ray_direction.abs() 
	var dir_inverted := Vector2.ONE - dir_absolute
	
	var preserved_velocity: Vector2 = dir_inverted * character.velocity
	var clamped_velocity: Vector2 = dir_absolute * character.velocity
	
	# lets not stop the player if theyre moving towards where the ray is pointing
	if (ray_direction.x != 0 and sign(clamped_velocity.x) == -sign(ray_direction.x)) \
	or (ray_direction.y != 0 and sign(clamped_velocity.y) == -sign(ray_direction.y)):
		intersect_info[CollisionHelper.IS_COLLIDING] = false
	else:
		clamped_velocity = Vector2.ZERO
	
	character.velocity = preserved_velocity + clamped_velocity
	
	var edge_normal: Vector2 = intersect_info[CollisionHelper.EDGE_NORMAL]
	var contact_point: Vector2 = intersect_info[CollisionHelper.CONTACT_POINT]
	var resolution_offset: Vector2 = intersect_info[CollisionHelper.RESOLUTION_OFFSET]
	
	var movement_delta: Vector2 = character.velocity * delta
	var slope_offset := Vector2.ZERO
	
	if edge_normal.x != 0.0:
		slope_offset.x = - (edge_normal.y / edge_normal.x) * movement_delta.y
	if edge_normal.y != 0.0:
		slope_offset.y = - (edge_normal.x / edge_normal.y) * movement_delta.x
	
	# basicallyy this is made in such a way that only one axis is affected
	# while the other axis stays the same
	var old_pos: Vector2 = dir_inverted * character.position
	var new_pos: Vector2 = dir_absolute * ((contact_point - resolution_offset) + slope_offset)
	character.position = old_pos + new_pos


func ray_array_check(delta: float, space_state: Physics2DDirectSpaceState, expected_normal: Vector2, ray_array: Array, extend := Vector2.ZERO) -> Array:
	var intersection: Array = [false]
	var intersecting: bool = false
	var closest_distance: float = 0.0
	
	for ray in ray_array:
		var ray_intersection: Array = ray_check(delta, space_state, expected_normal, ray[0], ray[1] + extend, ray[2])
		if ray_intersection[CollisionHelper.IS_COLLIDING]:
			# will count the ray with the least distance to its
			# start point on the axis it's pointing to
			var difference := Vector2(
				ray_intersection[CollisionHelper.CONTACT_POINT].x - ray[0].x,
				ray_intersection[CollisionHelper.CONTACT_POINT].y - ray[0].y
			)
			difference *= ray[4].abs()
			
			var distance: float = difference.length()
			if not intersecting or distance < closest_distance:
				intersecting = true
				closest_distance = distance
				intersection = ray_intersection
	return intersection


## the original version of this used custom logic
# luckily here we can use built in godot methods for this 
func ray_check(delta: float, space_state: Physics2DDirectSpaceState, expected_normal: Vector2, point: Vector2, cast_to: Vector2, origin: Vector2) -> Array:
	var from: Vector2 = point + character.position
	var to: Vector2 = cast_to + character.position + (character.velocity * delta)
	
	var exclude: Array = [character]
	while true:
		var result = space_state.intersect_ray(from, to, exclude, character.collision_mask)
		if result.empty():
			break
		
		if expected_normal == Vector2.ZERO or edge_from_normal(result.normal).is_equal_approx(expected_normal):
			return [
				true,
				result.position,
				result.normal,
				origin
			]
		
		exclude.append(result.collider)
		
	return [false]


func _draw() -> void:
	if not draw_debug: return
	
	var ray_arrays: Array = [
		[ceiling_rays, ceiling_info],
		[floor_rays, floor_info],
		[left_rays, left_info],
		[right_rays, right_info]
	]
	var colors: Array = [
		Color.limegreen,
		Color.royalblue,
		Color.indianred,
		Color.darkorange
	]
	
	var i: int = 0
	for dir_params in ray_arrays:
		var ray_array: Array = dir_params[0]
		var info: Array = dir_params[1]
		for ray in ray_array:
			draw_line(ray[0], ray[1], colors[i] if not info[CollisionHelper.IS_COLLIDING] else Color.red)
		
		i += 1
