extends Node2D

onready var puck: Puck = $YSort/Puck
onready var camera: Camera2D = $YSort/Puck/Camera2D

var team_a = []
var team_b = []



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
