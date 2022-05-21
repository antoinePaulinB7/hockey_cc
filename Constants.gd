extends Node2D

var COLLISION_LAYERS = {}

func _ready():
	for i in range(1, 21):
		var name = ProjectSettings.get_setting("layer_names/2d_physics/layer_%d" % i)

		if name:
			COLLISION_LAYERS[name] = i - 1

	print_debug(COLLISION_LAYERS)

func reparent(child: Node, new_parent: Node):
	var old_parent = child.get_parent()
	old_parent.remove_child(child)
	new_parent.add_child(child)
