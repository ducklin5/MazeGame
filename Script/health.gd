extends Node
var MAX_HEALTH = 100
var health = MAX_HEALTH
var hitMultiplier = 1
var healMultiplier = 1

signal healthChanged(current,maximum)
signal dead

func hit(x, shooter):
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
		if shooter.id == get_parent().get_name():
			print("SUICIDAL MANIAC!")
		else:
			print("killed by: " + shooter.name)
	else:
		if shooter.id == get_parent().get_name():
			print("Why are hitting yourself?")
		else:
			print("hit by: " + shooter.name)

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
