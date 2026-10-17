extends StaticBody2D


func _draw():
	for child in get_children():
		if child is CollisionPolygon2D:
			var new_poly: PoolVector2Array = child.polygon
			for index in range(new_poly.size()):
				new_poly[index] += child.global_position
			draw_polygon(new_poly, [Color.white])
		else:
			var segment: SegmentShape2D = child.shape
			var a: Vector2 = child.transform.xform(segment.a)
			var b: Vector2 = child.transform.xform(segment.b)
			draw_line(a, b, Color.white)
