class_name CollisionHelper

const IS_COLLIDING: int = 0
const CONTACT_POINT: int = 1
const EDGE_NORMAL: int = 2
const RESOLUTION_OFFSET: int = 3


# Returns an array: [true/false, intersection_vector2]
static func get_line_intersection(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Array:
	var intersection = Geometry.segment_intersects_segment_2d(p0, p1, p2, p3)
	if intersection != null:
		return [true, intersection]
	return [false]


static func get_polygon_intersection(ray_start: Vector2, ray_end: Vector2, polygon: Array) -> Array:
	var intersecting: bool = false
	var closest_intersection_point: Vector2
	var closest_collision_normal: Vector2
	var closest_distance: float = INF
	
	var prev: Vector2 = polygon[0]
	for i in range(1, polygon.size()):
		var point: Vector2 = polygon[i]
		
		# Built-in Godot 3 segment intersection check
		var intersection = Geometry.segment_intersects_segment_2d(ray_start, ray_end, prev, point)
		
		if intersection != null:
			var edge: Vector2 = point - prev
			# Calculate normal vector (perpendicular to edge, normalized)
			var collision_normal = Vector2(edge.y, -edge.x).normalized()
			
			var distance: float = ray_start.distance_to(intersection)
			
			if not intersecting or distance < closest_distance:
				closest_distance = distance
				closest_intersection_point = intersection
				closest_collision_normal = collision_normal
				intersecting = true
		
		prev = point
		
	return [intersecting, closest_intersection_point, closest_collision_normal]
