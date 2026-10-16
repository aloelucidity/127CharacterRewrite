extends StaticBody2D


func _draw():
	for child in get_children():
		var new_poly: PoolVector2Array = child.polygon
		for index in range(new_poly.size()):
			new_poly[index] += child.global_position
		draw_polygon(new_poly, [Color.white])
