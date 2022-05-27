extends RigidBody2D
class_name Player

export(bool) var lefty = true
export(float, 10.0, 50.0) var charge_shot_rate = 10.0
export(int, 1, 99) var precision = 1
export(int, 1, 99) var shot_power = 1
export(int, 1, 99) var skating_speed = 1
export(float, 100, 250) var max_speed = 100
export(float, 1.0, 5.0) var accel = 2.0

onready var sprite: Sprite = $Sprite
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var flipper: AnimationPlayer = $Flipper
onready var puck_area: Area2D = $PuckArea
onready var puck_collider: CollisionShape2D = $PuckArea/PuckCollider
onready var line_up: Line2D = $LineUp
onready var line_down: Line2D = $LineDown
onready var line_shot: Line2D = $LineShot
onready var skating_particles: Particles2D = $SkatingParticles

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
var charging: float = 0.0
var max_charge: float = 10.0

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
	direction = Vector2.RIGHT * Input.get_axis("move_left", "move_right") + Vector2.UP * Input.get_axis("move_down", "move_up")
	
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
	
	if direction.length() > 0.01 and linear_velocity.length() > 50.0:
		if abs(direction.angle_to(linear_velocity)) > 2.5:
			skating_particles.emitting = true
			skating_particles.set_rotation((direction).angle())
		else:
			skating_particles.emitting = false
	
	print(linear_velocity.length())
	
	update_line()

func _physics_process(delta):
	if Input.is_action_pressed("ui_select"):
		player_state = PlayerState.CHARGING
		charging += charge_shot_rate * delta
	elif Input.is_action_just_released("ui_select"):
		if player_state == PlayerState.CHARGING and puck != null:
			player_state = PlayerState.SHOOTING
			release_puck()
		else:
			player_state = PlayerState.IDLE
		
		charging = 0
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

func update_line():
	var precision_factor = (100.0 - precision)/99.0
	
	line_up.clear_points()
	line_up.add_point(puck_collider.position + sprite.position)
	line_up.add_point(puck_collider.position + sprite.position + get_direction().rotated((-PI/4) * precision_factor) * 10 * charging)
	
	line_down.clear_points()
	line_down.add_point(puck_collider.position + sprite.position)
	line_down.add_point(puck_collider.position + sprite.position + get_direction().rotated((PI/4) * precision_factor) * 10 * charging)
	
	line_shot.clear_points()
	line_shot.add_point(puck_collider.position + sprite.position)
	line_shot.add_point(puck_collider.position + sprite.position + Vector2.UP * 16 * get_shot_strength())

#	add_force(Vector2(0, 0), direction * 10)
func get_direction():
	if direction.length_squared() > 0.01:
		return direction
	
	match facing:
		Facing.RIGHT:
			return Vector2.RIGHT
		Facing.LEFT:
			return Vector2.LEFT

func get_shot_strength():
	var charge = min(charging, max_charge) / max_charge
	var power = shot_power / 99.0
	
	return charge * power

func get_shot_direction():
	var curr_direction = get_direction()
	var precision_factor = (100.0 - precision)/99.0
	var deviation = rand_range((-PI/4) * precision_factor, (PI/4) * precision_factor)
	
	return curr_direction.rotated(deviation)

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
				apply_central_impulse(direction * accel)
#				apply_central_impulse(direction * 1.75)
		PlayerState.SHOOTING:
			apply_central_impulse(-get_direction() * 50)
			player_state = PlayerState.IDLE
		_:
			pass
	
	state.linear_velocity = state.linear_velocity.clamped(max_speed)
