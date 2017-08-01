extends KinematicBody2D
# Constants
const MOTION_SPEED = 100 # Pixels/second
var glide = 0
var motion = Vector2()
var finalSpeed
var killed = false
var dir = Vector2()
slave var slave_pos = Vector2()
slave var slave_motion = Vector2()
slave var slave_dir = Vector2()
var canonYScale

#required by portaling
export var canTeleport = true
var portalWait = 0.5
onready var portalTimer = get_node("portalTimer")


enum {
	SPR_UP = 1, SPR_DOWN = 2, SPR_LEFT = 4, SPR_RIGHT = 8,
}
 
# Nodes
onready var Anims = find_node("anim")
onready var sprite = find_node("Sprite")
onready var camera = find_node("camera")
onready var camera_anim = find_node("camera_anim")
onready var health = get_node("Health")
 
# "Private" members
onready var sprite_direction = { # All 8 directions for a sprite's animation
	SPR_UP					: "walkUp"		,
	SPR_DOWN				: "walkDown"	,
	SPR_LEFT				: "walkLeft"	,
	SPR_RIGHT				: "walkRight"	,
	SPR_UP   | SPR_LEFT		: "walkLeft"	,
	SPR_UP   | SPR_RIGHT	: "walkRight"	,
	SPR_DOWN | SPR_LEFT		: "walkLeft"	,
	SPR_DOWN | SPR_RIGHT	: "walkRight"	,
}
onready var sprite_motion = {
	SPR_UP			   : Vector2( 0, -1),
	SPR_DOWN			 : Vector2( 0,  1),
	SPR_LEFT			 : Vector2(-1,  0),
	SPR_RIGHT			: Vector2( 1,  0),
	SPR_UP   | SPR_LEFT  : Vector2(-1, -1),
	SPR_UP   | SPR_RIGHT : Vector2( 1, -1),
	SPR_DOWN | SPR_LEFT  : Vector2(-1,  1),
	SPR_DOWN | SPR_RIGHT : Vector2( 1,  1),
}
 
######################
### Core functions ###
######################
func _ready():
	set_process_input(true)
	set_fixed_process(true)
	var HUD = get_tree().get_root().get_node("HUD")
	if is_network_master() && !health.is_connected("healthChanged", HUD, "_on_Health_healthChanged"):
		health.connect("healthChanged", HUD, "_on_Health_healthChanged")

func _fixed_process(delta):
	# Grabbing directions from Input and transforming them into flags
	var directions = int(Input.is_action_pressed("ui_up"))  << 0
	directions	|= int(Input.is_action_pressed("ui_down"))  << 1
	directions	|= int(Input.is_action_pressed("ui_left"))  << 2
	directions	|= int(Input.is_action_pressed("ui_right")) << 3
	
	var angle
	# If it is master
	if is_network_master():
		#animate canon
		dir = (get_global_mouse_pos() -  get_global_pos()).normalized()
		angle = atan2(dir.x,dir.y)
		#move the character, animate the character
		if sprite_direction.has(directions):
			move_character(directions, delta)
		else:
			motion *= glide
			move(motion)
		#update slave
		if canTeleport:
			rset("slave_motion", motion)
			rset("slave_pos", get_pos())
			rset("slave_dir", dir)
	else:
		set_pos(slave_pos)
		motion = slave_motion
		slave_pos = get_pos() # To avoid jitter
		dir = slave_dir
		angle = atan2(slave_dir.x,slave_dir.y)
	
	get_node("Canon").set_rot(0)
	canonYScale = 0.2 - 0.03 * abs(sin(angle-PI/2))
	get_node("Canon").set_scale(Vector2(0.2, canonYScale))
	get_node("CollisionCanon").set_scale(Vector2(1, canonYScale/0.2))
	get_node("Canon").set_rot(angle)
	get_node("CollisionCanon").set_rot(angle)
		
	if portalTimer.is_active():
		var x =  100 - portalTimer.get_time_left()*100/portalTimer.get_wait_time()
		get_node("portalProg").set_value(x)
 
###############
### Methods ###
###############
slave func animate_character(directions):
	# If it has animation in this direction
	if sprite_direction.has(directions):
		var new_anim = sprite_direction[directions]
		if new_anim != Anims.get_current_animation() || !Anims.is_playing():
			Anims.play(new_anim)
	elif Anims.is_playing():
		Anims.stop()
	return Anims.is_playing()
 
func move_character(directions, delta=0):
	#if sprite_motion.has(directions):
	motion = sprite_motion[directions]

	motion = motion.normalized() * (MOTION_SPEED*delta)
	move(motion)
	# Make character slide when collisions are detected
	var slide_attempts = 1
	while is_colliding() and slide_attempts > 0:
		motion = get_collision_normal().slide(motion)
		move(motion)
		slide_attempts -= 1


func _input(ev):
	if (is_network_master() and ev.type==InputEvent.MOUSE_BUTTON and ev.button_index==1 and ev.pressed  ):
		shoot()
		var dir = (get_global_mouse_pos() -  get_global_pos()).normalized()
		rpc("shoot",dir)

slave func shoot(dir = (get_global_mouse_pos() -  get_global_pos()).normalized()):
	var bullet = preload("res://Scenes/Bullet.tscn").instance()
	
	bullet.shooter = self
	bullet.motion = dir
	bullet.set_layer_mask(get_layer_mask())
	bullet.set_collision_mask(get_layer_mask())
	get_parent().add_child(bullet)
	bullet.set_pos(get_pos())
	#bullet.set_pos(get_pos()+canonYScale*500*dir)

func set_player_name(name):
	get_node("label").set_text(name)

func set_player_color(color):
	get_node("BlockTop").set_modulate(color)
	get_node("BlockBottom").set_modulate(color)
	get_node("Canon").set_modulate(color)

func portalCountDown():
	portalTimer.set_wait_time(portalWait)
	portalTimer.set_one_shot(true)
	portalTimer.start()
	get_node("portalProg").show()

func disablePortalProg():
	portalTimer.stop()
	get_node("portalProg").hide()

func set_health(x):
	health.health = x