extends Camera2D

onready var puck: Puck = $"/root/Node2D/YSort/Puck"

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

enum LookDirection {
	LEFT, CENTER, RIGHT
}

var look_direction = LookDirection.CENTER

# Called when the node enters the scene tree for the first time.
func _ready():
	print(puck)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if puck.holder != null:
		var direction = puck.holder.get_direction()
		
		if direction.x > 0.01:
			offset_h = 1
		elif direction.x < -0.01:
			offset_h = -1
	else:
		offset_h = 0
