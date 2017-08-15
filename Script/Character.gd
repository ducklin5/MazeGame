extends KinematicBody2D
# Constants
var MOTION_SPEED = 750 # Pixels/second
var glide = 0
var finalSpeed
var killed = false

var moveDir = Vector2(0,0)
var motion = Vector2()
var lookDir = Vector2()

slave var slave_pos = Vector2()
slave var slave_motion = Vector2()
slave var slave_lookDir = Vector2()

#required by portaling
export var canTeleport = true
var portalWait = 0.5
onready var portalTimer = get_node("portalTimer")
onready var health = get_node("Health")

enum {
	SPR_UP = 1, SPR_DOWN = 2, SPR_LEFT = 4, SPR_RIGHT = 8,
} 

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
 
func _ready():
	var tr = RayCast2D.new()
	set_fixed_process(true)
	if !portalTimer.is_connected("timeout", self, "disablePortalProg"):
		portalTimer.connect("timeout", self, "disablePortalProg")

func think():
	# code to get motion direction goes here it must return a vector
	moveDir = Vector2(0,0)
	#code related to the looking direction of the charcter goes here, it must update the variable "lookDir"
	lookDir = (get_global_mouse_pos() -  get_global_pos()).normalized()

func _fixed_process(delta):
	if is_network_master():
		think()
		move_character(moveDir, delta)
		#update slave
		if canTeleport:
			rset("slave_pos", get_pos())
			rset("slave_motion", motion)
			rset("slave_lookDir", lookDir)
	else:
		set_pos(slave_pos)
		motion = slave_motion
		slave_pos = get_pos() # To avoid jitter
		lookDir = slave_lookDir

	if portalTimer.is_active():
		var x =  100 - portalTimer.get_time_left()*100/portalTimer.get_wait_time()
		get_node("portalProg").set_value(x)
 
###############
### Methods ###
###############
#slave func animate_character(directions):
	# If it has animation in this direction
#	if sprite_direction.has(directions):
#		var new_anim = sprite_direction[directions]
#		if new_anim != Anims.get_current_animation() || !Anims.is_playing():
#			Anims.play(new_anim)
#	elif Anims.is_playing():
#		Anims.stop()
#	return Anims.is_playing()
 
func move_character(moveDir, delta=0):
	if moveDir == Vector2(0,0):
		motion *= (glide * delta)
	else:
		motion = moveDir.normalized() * (MOTION_SPEED*delta)
	move(motion)
	# Make character slide when collisions are detected
	var slide_attempts = 1
	while is_colliding() and slide_attempts > 0:
		motion = get_collision_normal().slide(motion)
		move(motion)
		slide_attempts -= 1
	self.moveDir = Vector2(0,0)

slave func shoot(lookDir = lookDir):
	var bullet = preload("res://Scenes/Bullet.tscn").instance()
	
	bullet.shooter = {"id" : get_name(), "name" : get_character_name()}
	bullet.motion = lookDir
	bullet.set_layer_mask(get_layer_mask())
	bullet.set_collision_mask(get_layer_mask())
	get_parent().add_child(bullet)
	bullet.set_pos(get_pos())


func set_character_name(name):
	get_node("label").set_text(name)

func get_character_name():
	return get_node("label").get_text()

func set_character_color(color):
	get_node("Sprite").set_modulate(color)

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