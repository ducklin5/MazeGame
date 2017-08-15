extends "res://Script/Character.gd"

onready var camera = get_node("camera")

func _init():
	MOTION_SPEED = 1000

func think():
	if !is_processing_input():
		set_process_input(true)
	var directions = int(Input.is_action_pressed("ui_up"))  << 0
	directions	|= int(Input.is_action_pressed("ui_down"))  << 1
	directions	|= int(Input.is_action_pressed("ui_left"))  << 2
	directions	|= int(Input.is_action_pressed("ui_right")) << 3
	if sprite_motion.has(directions):
		moveDir = sprite_motion[directions]
	
	lookDir = (get_global_mouse_pos() -  get_global_pos()).normalized()
	#	get_node("Canon").set_rot(0)
	#	canonYScale = 0.2 - 0.03 * abs(sin(angle-PI/2))
	#	get_node("Canon").set_scale(Vector2(0.2, canonYScale))
	#	get_node("CollisionCanon").set_scale(Vector2(1, canonYScale/0.2))
	#	get_node("Canon").set_rot(angle)
	#	get_node("CollisionCanon").set_rot(angle)
	
func _input(ev):
	if (is_network_master() and ev.type==InputEvent.MOUSE_BUTTON and ev.button_index==1 and ev.pressed  ):
		shoot(lookDir)
		var dir = (get_global_mouse_pos() -  get_global_pos()).normalized()
		rpc("shoot",dir)
