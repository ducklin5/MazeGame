extends CanvasLayer
var HP
#var pos = Vector2( 

func _ready():
	HP = get_node("healthBar")
	HP.set_global_pos(
		Vector2(get_viewport().get_visible_rect().size.x - HP.get_size().x - 20, 20)
	)
	set_fixed_process(true)


func _on_Health_healthChanged(health,maxHealth):
	HP.set_max(maxHealth)
	HP.set_value(health)
