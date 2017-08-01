extends Node
var MAX_HEALTH = 100
var health = MAX_HEALTH
var hitMultiplier = 1
var healMultiplier = 1

signal healthChanged(current,maximum)
signal dead

func hit(x):
	var finalHit = x * hitMultiplier
	if health < finalHit:
		finalHit = health
	health -= finalHit
	
	var hL = hitLabel.new()
	hL.finalHit = -finalHit
	add_child(hL)
	emit_signal("healthChanged", health, MAX_HEALTH)
	
	if health == 0:
		emit_signal("dead")

func heal(x):
	health -= x * healMultiplier
	emit_signal("healthCahnged", health, MAX_HEALTH )

class hitLabel:
	extends Label
	var finalHit = 0
	var lifeSpan = 2
	var time = 0
	func _ready():
		set_pos(Vector2(0,-20))
		set_text(str(finalHit))
		set_fixed_process(true)
	func _fixed_process(delta):
		time += delta
		if time > lifeSpan:
			queue_free()
