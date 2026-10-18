class_name StateLink
extends Node

export var link_to_path: NodePath
var link_to: ActionState

func _enter_tree():
	link_to = get_node(link_to_path)
