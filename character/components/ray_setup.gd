extends Node2D

const CEILING_NORMAL := Vector2(0, -1)
const FLOOR_NORMAL := Vector2(0, 1)
const LEFT_NORMAL := Vector2(-1, 0)
const RIGHT_NORMAL := Vector2(1, 0)

export var head_height: float
export var body_width: float

export var ceiling_casts: int
export var floor_casts: int
export var horizontal_casts: int

export var ceiling_corner_width: float
export var floor_corner_width: float
export var corner_height: float

var collision: CharacterCollision


func _enter_tree() -> void:
	#Engine.time_scale = 0.1
	collision = get_parent()
	call_deferred("setup_rays")


func setup_rays() -> void:
	collision.ceiling_rays = ray_setup(
		CEILING_NORMAL, Vector2(0, -head_height), corner_height,
		ceiling_casts, body_width - ceiling_corner_width)
	
	collision.floor_rays = ray_setup(
		FLOOR_NORMAL, Vector2.ZERO, corner_height,
		floor_casts, body_width - floor_corner_width)
	
	collision.left_rays = ray_setup(
		LEFT_NORMAL, Vector2(-body_width, -head_height/2), body_width,
		horizontal_casts, (head_height / 2) - corner_height)
	
	collision.right_rays = ray_setup(
		RIGHT_NORMAL, Vector2(body_width, -head_height/2), body_width,
		horizontal_casts, (head_height / 2) - corner_height)


func ray_setup(direction: Vector2, origin: Vector2, sink: float, casts: int, side_length: float) -> Array:
	var ray_array: Array = []
	var extend: float = 0
	
	origin *= 1.0
	sink *= 1.0
	side_length *= 1.0
	
	# adds a raycast in the middle for odd numbers
	if casts % 2 != 0:
		ray_array.append(dir_to_points(
			direction,
			origin,
			sink,
			extend
		))
		casts -= 1
	
	# distributes rays equally
	for cast in range(casts):
		var step: float = float(cast) / (float(casts) - 1)
		var offset: float = lerp(-side_length, side_length, step)
		
		# fill zeroes with the new offset position
		var dir_inverted := Vector2.ONE - direction.abs()
		var shift: Vector2 = (dir_inverted * offset)
		ray_array.append(dir_to_points(
			direction,
			origin + shift,
			sink,
			extend
		))
	
	return ray_array


func dir_to_points(direction: Vector2, origin: Vector2, sink: float, extend: float) -> Array:
	var point: Vector2 = origin
	point -= direction * sink
	
	var cast_to: Vector2 = origin
	cast_to += direction * extend
	
	return [point, cast_to, origin, direction]
