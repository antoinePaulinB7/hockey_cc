extends RigidBody2D
class_name Puck

export(float, 150.0, 750.0) var explosion_threshold = 500.0

enum PuckState {
	CALM, BOBBLING,
}

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var shot_particles: Particles2D = $ShotParticles
onready var bomb_particles: Particles2D = $BombParticles

var holder: Player = null

# Called when the node enters the scene tree for the first time.
func _ready():
	animation_player.play("Bobbling")
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if linear_velocity.length() > 25.0:
		animation_player.play("Bobbling")
	else:
		animation_player.play("Idle")


func _physics_process(delta):
#	if holder:
#		global_position = holder.puck_collider.global_position
#		linear_velocity = holder.linear_velocity
		
	pass

func hold(player: Player):
	holder = player
	player.puck = self
	
#	set_sleeping(true)
	
#	Constants.reparent(self, holder.puck_collider)
	
	set_collision_mask_bit(Constants.COLLISION_LAYERS["Player"], false)
	set_collision_mask_bit(Constants.COLLISION_LAYERS["PuckAreas"], false)
	set_collision_mask_bit(Constants.COLLISION_LAYERS["Goaltender"], false)

func release():
#	Constants.reparent(self, get_node("/root"))
	
#	global_position = holder.puck_collider.global_position
#	position = holder.puck_collider.position

	set_collision_mask_bit(Constants.COLLISION_LAYERS["Player"], true)
	set_collision_mask_bit(Constants.COLLISION_LAYERS["Goaltender"], true)
	linear_velocity = Vector2.ZERO
	
	var puck_impulse_strength = lerp(150, 750, holder.get_shot_strength())
	
	if puck_impulse_strength > explosion_threshold:
		shot_particles.emitting = true
		bomb_particles.emitting = true
	
	apply_central_impulse(holder.get_shot_direction() * puck_impulse_strength) # 500
#	set_sleeping(false)
	holder = null
	
	yield(get_tree().create_timer(1.0), "timeout")
	shot_particles.emitting = false
	bomb_particles.emitting = false
	set_collision_mask_bit(Constants.COLLISION_LAYERS["PuckAreas"], true)

func _integrate_forces(state):
	if holder:
		state.transform = Transform2D(0, holder.puck_collider.global_position)
		state.linear_velocity = holder.linear_velocity
	
#	if holder:
#		global_position = holder.puck_collider.global_position
#		linear_velocity = holder.linear_velocity
	pass
