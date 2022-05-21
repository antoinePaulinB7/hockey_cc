extends RigidBody2D
class_name Player

export(bool) var lefty = true

onready var sprite: Sprite = $Sprite
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var flipper: AnimationPlayer = $Flipper
onready var puck_area: Area2D = $PuckArea
onready var puck_collider: CollisionShape2D = $PuckArea/PuckCollider

enum PlayerState {
	IDLE, SKATING, CHARGING, SHOOTING, FALLEN, KO
}

enum Flip {
	LEFT, NOTHING, RIGHT
}

enum Facing {
	RIGHT, LEFT
}

var player_state = PlayerState.IDLE
var flip = Flip.NOTHING
var facing = Facing.RIGHT

var direction: Vector2 = Vector2.ZERO
var looking_left: bool = false
var puck: RigidBody2D = null

# Called when the node enters the scene tree for the first time.
func _ready():
	if !lefty:
		sprite.scale.x = -1
	
#	self.collision_layer = pow(2, Constants.COLLISION_LAYERS["Player"] - 1)
#	self.collision_mask = pow(2, Constants.COLLISION_LAYERS["Player"] - 1)
#
#	print_debug(self.collision_layer)
#	print_debug(self.collision_mask)
#
#	print_debug(self.collision_layer & int(pow(2, Constants.COLLISION_LAYERS["Puck"] - 1)))
#	print_debug(self.collision_mask & int(pow(2, Constants.COLLISION_LAYERS["Puck"] - 1)))
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	direction = Vector2.ZERO
	flip = Flip.NOTHING
	
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	
	if Input.is_action_pressed("ui_right"):
		direction.x += 1  

	if Input.is_action_pressed("ui_up"):
		direction.y -= 1

	if Input.is_action_pressed("ui_down"):
		direction.y += 1
		
	direction = direction.normalized()
	
	if direction.x < -0.01:
		flip = Flip.LEFT
		facing = Facing.LEFT
	elif direction.x > 0.01:
		flip = Flip.RIGHT
		facing = Facing.RIGHT

func _physics_process(delta):
	if Input.is_action_pressed("ui_select"):
		player_state = PlayerState.CHARGING
	elif Input.is_action_just_released("ui_select"):
		if player_state == PlayerState.CHARGING and puck != null:
			player_state = PlayerState.SHOOTING
			release_puck()
		else:
			player_state = PlayerState.IDLE
	elif linear_velocity.length() > 5.0 or direction.length() > 0.01:
		player_state = PlayerState.SKATING
	else:
		player_state = PlayerState.IDLE
	
	match player_state:
		PlayerState.IDLE:
			if facing == Facing.RIGHT:
				animation_player.play("Idle" if lefty else "Idle - Back")
				flipper.play("Idling Right")
			else:
				animation_player.play("Idle - Back" if lefty else "Idle")
				flipper.play("Idling Left")
		PlayerState.SKATING:
			if facing == Facing.RIGHT:
				animation_player.play("Skating" if lefty else "Skating - Back")
				flipper.play("Skating Right")
			else:
				animation_player.play("Skating - Back" if lefty else "Skating")
				flipper.play("Skating Left")
		PlayerState.CHARGING:
			if facing == Facing.RIGHT:
				animation_player.play("Charging Shot - Back" if lefty else "Charging Shot")
				flipper.play("Shooting Right")
			else:
				animation_player.play("Charging Shot" if lefty else "Charging Shot - Back")
				flipper.play("Shooting Left")
	
#	add_force(Vector2(0, 0), direction * 10)
func get_direction():
	if direction.length_squared() > 0.01:
		return direction
	
	match facing:
		Facing.RIGHT:
			return Vector2.RIGHT
		Facing.LEFT:
			return Vector2.LEFT

func release_puck():
	if puck:
		puck.release()
		puck = null

func _on_PuckArea_body_entered(body: RigidBody2D):
	if body.is_in_group("puck"):
		body.hold(self)

func _integrate_forces(state):
	match player_state:
		PlayerState.IDLE, PlayerState.SKATING:
			if (direction.length() > 0.01):
				apply_central_impulse(direction * 1.75)
		PlayerState.SHOOTING:
			apply_central_impulse(-get_direction() * 50)
			player_state = PlayerState.IDLE
		_:
			pass
