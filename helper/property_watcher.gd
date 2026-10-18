extends Label

export var object_to_watch: NodePath
export var property_to_watch: String

onready var obj = get_node(object_to_watch)

func _process(_delta: float) -> void:
	if not is_instance_valid(obj):
		return
	
	var property = obj[property_to_watch]
	if property is Vector2:
		property = "(%.2f, %.2f)" % [property.x, property.y]
	if property is Object:
		property = property.name
	text = str(property)
