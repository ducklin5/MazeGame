extends KinematicBody2D

var shooter = {"id" : "0", "name" : "unknown"}
var hasLeftShooter = false
var canTeleport = false
var motion=Vector2(1,0)
const ADVANCE_SPEED = 3000

signal portalMe

var hit=false
onready var sprite = get_node("Sprite")
onready var area = get_node("area")

func _process(delta):
	if !hit:
		move(motion*delta*ADVANCE_SPEED)

func _ready():
	self.add_user_signal("portalMe")
	if !area.is_connected("body_enter",self,"_on_area_body_enter"):
		area.connect("body_enter",self,"_on_area_body_enter")
	if !area.is_connected("body_exit",self,"_on_area_body_exit"):
		area.connect("body_exit",self,"_on_area_body_exit")
	area.set_layer_mask(get_layer_mask())
	area.set_collision_mask(get_layer_mask())
	set_process(true)
	set_rot(atan2(motion.x,motion.y))
	
func _on_area_body_enter( body ):
	var bodyIsShooter = (body.get_name() == shooter.id)
	if body != self and (!bodyIsShooter or ( bodyIsShooter and hasLeftShooter)):
		hit = true
		if body.is_in_group("character"):
			body.health.hit(10, shooter)
	if hit:
		queue_free()

func _on_area_body_exit( body ):
	if body.get_name() == shooter.id:
		hasLeftShooter = true
		canTeleport = true
		emit_signal("portalMe")
