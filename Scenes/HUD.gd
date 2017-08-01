extends CanvasLayer

func _on_Health_healthChanged(health,maxHealth):
	get_node("healthBar").set_max(maxHealth)
	get_node("healthBar").set_value(health)
