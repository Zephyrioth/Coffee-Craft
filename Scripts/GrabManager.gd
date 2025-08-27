extends Node

# GrabManager.gd
var current_dragged_object: Node = null

func is_dragging() -> bool:
	return current_dragged_object != null
