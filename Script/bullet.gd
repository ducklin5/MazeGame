extends KinematicBody2D

var shooter
var hasLeftShooter = false
var canTeleport = true
var motion=Vector2(1,0)
const ADVANCE_SPEED = 10

var hit=false
onready var sprite = get_node("Sprite")

func _fixed_process(delta):
	move(motion*delta*ADVANCE_SPEED)
	
func _ready():
	get_node("area").set_layer_mask(get_layer_mask())
	get_node("area").set_collision_mask(get_layer_mask())
	set_fixed_process(true)
	
func _on_area_body_enter( body ):
	if body != self and (body != shooter || hasLeftShooter ):
		hit = true
		if body.is_in_group("player"):
			body.health.hit(10)
	if hit:
		queue_free()


func _on_area_body_exit( body ):
	if body == shooter:
		hasLeftShooter = true
		
