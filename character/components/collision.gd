class_name CharacterCollision
extends Node2D


const FLOOR_THRESHOLD: float = 0.7
const GROUND_GRACE: float = 0.5
# defined in pixels
const MAX_STEP_DISTANCE: float = 5.0

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
var ceiling_info: Dictionary = {"is_colliding": false}
var floor_info: Dictionary = {"is_colliding": false}
var left_info: Dictionary = {"is_colliding": false}
var right_info: Dictionary = {"is_colliding": false}
var found_transform = null
var last_transform = null
##


func edge_from_normal(normal: Vector2) -> Vector2:
	# if edge is horizontal
	if abs(normal.y) < FLOOR_THRESHOLD:
		# pointing right or left?
		if normal.x > 0:
			return Vector2.RIGHT
		else:
			return Vector2.LEFT
	else:
		# pointing down or up?
		if normal.y > 0:
			return Vector2.DOWN
		else:
			return Vector2.UP


func update_collision(delta: float) -> void:
	if delta <= 0.0:
		return
	
	var space_state: Physics2DDirectSpaceState = get_world_2d().direct_space_state
	
	## PLATFORM TRANSFORMS
	handle_platform_transforms()
	
	## SUBSTEPS
	var current_speed: float = character.velocity.length()
	var total_distance: float = current_speed * delta
	var steps: int = max(1, int(ceil(total_distance / MAX_STEP_DISTANCE)))
	var sub_delta: float = delta / float(steps)
	
	for i in range(steps):
		update_step(sub_delta, space_state)
	
	if draw_debug:
		update() # redraw


func update_step(delta: float, space_state: Physics2DDirectSpaceState) -> void:
	## RAY CHECKS
	# snapping further when going down on a slope
	var slope_offset: float = GROUND_GRACE
	if floor_info["is_colliding"] and character.velocity.x != 0:
		slope_offset = abs(character.velocity.x) * delta * (1.0 - floor_info["edge_normal"].y)
		slope_offset = max(GROUND_GRACE, slope_offset)
	
	# you only want to collide if the face is pointing away
	left_info = ray_array_check(delta, space_state, Vector2.RIGHT, left_rays)
	right_info = ray_array_check(delta, space_state, Vector2.LEFT, right_rays)
	ceiling_info = ray_array_check(delta, space_state, Vector2.DOWN, ceiling_rays)
	floor_info = ray_array_check(delta, space_state, Vector2.UP, floor_rays, Vector2(0, slope_offset))
	
	## APPLY VELOCITY
	character.position += character.velocity * delta
	
	## RESOLVE RAYS
	var resolved_position := character.position
	var resolved_velocity := character.velocity
	
	resolved_velocity = resolve_velocity(delta, left_info, resolved_velocity, Vector2.LEFT)
	resolved_velocity = resolve_velocity(delta, right_info, resolved_velocity, Vector2.RIGHT)
	resolved_velocity = resolve_velocity(delta, ceiling_info, resolved_velocity, Vector2.UP)
	resolved_velocity = resolve_velocity(delta, floor_info, resolved_velocity, Vector2.DOWN)
	
	character.velocity = resolved_velocity
	
	resolved_position = resolve_position(delta, left_info, resolved_position, Vector2.LEFT)
	resolved_position = resolve_position(delta, right_info, resolved_position, Vector2.RIGHT)
	resolved_position = resolve_position(delta, ceiling_info, resolved_position, Vector2.UP)
	resolved_position = resolve_position(delta, floor_info, resolved_position, Vector2.DOWN)
	
	character.position = resolved_position


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


func resolve_velocity(delta: float, intersect_info: Dictionary, current_velocity: Vector2, ray_direction: Vector2) -> Vector2:
	if not intersect_info["is_colliding"]: 
		return current_velocity
	
	var dir_absolute: Vector2 = ray_direction.abs() 
	var dir_inverted := Vector2.ONE - dir_absolute
	var preserved_velocity: Vector2 = dir_inverted * current_velocity
	
	# lets not stop the player if theyre moving away from the normal already
	intersect_info["ignore_mask"] = Vector2.ZERO
	var normal: Vector2 = intersect_info["edge_normal"]
	var moves_with_normal: bool = false
	if current_velocity.length_squared() > 0.001:
		var velocity_dir: Vector2 = current_velocity.normalized()
		moves_with_normal = velocity_dir.dot(normal) > 0.707
	
	if ray_direction.x != 0 and moves_with_normal:
		intersect_info["ignore_mask"].x = 1
		return current_velocity
	
	if ray_direction.y != 0 and moves_with_normal:
		intersect_info["ignore_mask"].y = 1
		return current_velocity
	
	return preserved_velocity


func resolve_position(delta: float, intersect_info: Dictionary, current_position: Vector2, ray_direction: Vector2) -> Vector2:
	if not intersect_info["is_colliding"] or intersect_info.get("ignore_mask", Vector2.ZERO) * ray_direction != Vector2.ZERO:
		return current_position
	
	var dir_absolute: Vector2 = ray_direction.abs() 
	var dir_inverted := Vector2.ONE - dir_absolute
	
	var edge_normal: Vector2 = intersect_info["edge_normal"]
	var contact_point: Vector2 = intersect_info["contact_point"]
	var resolution_offset: Vector2 = intersect_info["resolution_offset"]
	
	# project the movement delta onto the tangent to slide along slopes
	var tangent: Vector2 = Vector2(-edge_normal.y, edge_normal.x)
	var movement_delta: Vector2 = character.velocity * delta
	var slope_offset: Vector2 = tangent * movement_delta.dot(tangent)

	# this block prevents you from teleporting towards the direction of your ray
	# instead, only teleporting away from it. makes it feel more responsive...
	var target_pos: Vector2 = (contact_point - resolution_offset) + slope_offset
	if ray_direction.x > 0:
		target_pos.x = min(target_pos.x, current_position.x)
	elif ray_direction.x < 0:
		target_pos.x = max(target_pos.x, current_position.x)
		
	if ray_direction.y > 0:
		# well, okay, we can go down a liiittle bit. but only as much as the slope offset times 2 :3
		var max_allowed_y: float = current_position.y + max(0.0, slope_offset.y * 2)
		target_pos.y = min(target_pos.y, max_allowed_y)
	elif ray_direction.y < 0:
		target_pos.y = max(target_pos.y, current_position.y)

	var old_pos: Vector2 = dir_inverted * current_position
	var new_pos: Vector2 = dir_absolute * target_pos
	
	return old_pos + new_pos


func ray_array_check(delta: float, space_state: Physics2DDirectSpaceState, expected_normal: Vector2, ray_array: Array, extend := Vector2.ZERO) -> Dictionary:
	var intersection: Dictionary = {"is_colliding": false}
	var intersecting: bool = false
	var closest_distance: float = 0.0
	
	for ray in ray_array:
		var ray_intersection: Dictionary = ray_check(delta, space_state, expected_normal, ray[0], ray[1] + extend, ray[2], ray[3])
		if ray_intersection["is_colliding"]:
			# will count the ray with the least distance to its
			# start point on the axis it's pointing to
			var difference := Vector2(
				ray_intersection["contact_point"].x - ray[0].x,
				ray_intersection["contact_point"].y - ray[0].y
			)
			difference *= ray[4].abs()
			
			var distance: float = difference.length()
			if not intersecting or distance < closest_distance:
				intersecting = true
				closest_distance = distance
				intersection = ray_intersection
	
	return intersection


# uses predictive collision! the direction of the raycast is affected by
# the terrain's move transform as well as the character's velocity
# so basically, it detects what collision *would* happen after both 
# the character and the terrain get moved
func ray_check(delta: float, space_state: Physics2DDirectSpaceState, expected_normal: Vector2, point: Vector2, cast_to: Vector2, origin: Vector2, point_open: Vector2 = Vector2.INF) -> Dictionary:
	# defaults that are other params isnt supported in godot 3
	# this is my workaround
	if point_open == Vector2.INF:
		point_open = point
	
	var global_point: Vector2 = point + character.global_position
	var global_point_open: Vector2 = point_open + character.global_position
	var global_cast_to: Vector2 = cast_to + character.global_position
	
	#var predict_mask: Vector2 = expected_normal.abs()
	# predict_mask == Vector2.ZERO:
	#	predict_mask = Vector2(1, 1)
	
	#global_cast_to += character.velocity * predict_mask * delta
	
	# use the built in raycasts first to find collider to work with
	var hit_result: Dictionary = space_state.intersect_ray(global_point, global_cast_to, [character], character.collision_mask)
	if hit_result.empty():
		return {"is_colliding": false}
	
	var working_point: Vector2
	var working_cast_to: Vector2
	var cast_to_transform: Transform2D
	
	var shape_index: int = hit_result.shape
	var owner_id: int = hit_result.collider.shape_find_owner(shape_index)
	var collision_shape: Node2D = hit_result.collider.shape_owner_get_owner(owner_id)
	var is_closed: bool = true
	
	var polygon: PoolVector2Array
	if collision_shape is CollisionPolygon2D:
		polygon = collision_shape.polygon
	elif collision_shape is CollisionShape2D:
		var shape: Shape2D = collision_shape.shape
		if shape is SegmentShape2D:
			polygon = PoolVector2Array([shape.a, shape.b])
			is_closed = false
		else:
			push_error("unsupported collision shape found! add support, thanks :]")
	else:
		push_error("what exactly did we collide with...?")
	
	for i in range(polygon.size()):
		polygon[i] = collision_shape.global_transform.xform(polygon[i])
	
	# dont change length of the checks if you're moving with the terrain
#		if found_transform == null:
#			cast_to_transform = Transform2D(0, 
#				Vector2(global_cast_to.x, global_cast_to.y))
#			cast_to_transform *= polygon.motion_transform
#			working_cast_to = Vector2(cast_to_transform.origin.x, cast_to_transform.origin.y)
#		else:
	working_cast_to = global_cast_to
	working_point = global_point if is_closed else global_point_open
	
	var count: int = polygon.size()
	var edge_count: int = count if is_closed else count - 1
	for index in range(edge_count):
		var vertex: Vector2 = polygon[(index + 1) % count]
		var prev: Vector2 = polygon[index]
		var diff: Vector2 = vertex - prev
		var normal: Vector2 = Vector2(diff.y, -diff.x).normalized()
		
		var edge: PoolVector2Array = ([
			prev,
			vertex,
			normal
		])
		
		if expected_normal != Vector2.ZERO and not edge_from_normal(normal).is_equal_approx(expected_normal):
			continue
		
		var line_intersection: Array = CollisionHelper.get_line_intersection(
			Vector2(working_point.x, working_point.y),
			Vector2(working_cast_to.x, working_cast_to.y),
			Vector2(edge[0].x, edge[0].y),
			Vector2(edge[1].x, edge[1].y))
		
		if line_intersection[0]:
			#if found_transform == null:
			#	found_transform = polygon.motion_transform
			
			var intersection: Dictionary = {
				"is_colliding": true,
				"contact_point": line_intersection[1],
				"edge_normal": edge[2],
				"resolution_offset": origin
			}
			return intersection
	return {"is_colliding": false}


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
		var info: Dictionary = dir_params[1]
		for ray in ray_array:
			var colliding: bool = info["is_colliding"]
			draw_line(ray[0], ray[1], colors[i] if not colliding else Color.red, 1.0 if not colliding else 2.0)
		
		i += 1
