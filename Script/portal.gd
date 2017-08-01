extends Area2D
var size = Vector2(0,0)
var wall = 0
var destination = null
var color = Color(1,1,1)

signal playerLayer_changed 

func _ready():
	var wallPos
	var points 
	if wall == 0: #North
		wallPos = Vector2(size.x,0)
		points = [Vector2(0,size.y*2/3),Vector2(size.x,size.y*2/3),Vector2(size.x,size.y),Vector2(0,size.y)]
	elif wall == 1: #East
		wallPos = Vector2(size.x*2,size.y)
		points = [Vector2(0,0),Vector2(size.x/3,0),Vector2(size.x/3,size.y),Vector2(0,size.y)]
	elif wall == 2: #South
		wallPos = Vector2(size.x,size.y*2)
		points = [Vector2(0,0),Vector2(size.x,0),Vector2(size.x,size.y/3),Vector2(0,size.y/3)]
	elif wall == 3: #West
		wallPos = Vector2(0,size.y)
		points = [Vector2(size.x*2/3,0),Vector2(size.x,0),size,Vector2(size.x*2/3,size.y)]
	for p in range (0, points.size()):
		points[p].y -= size.y/3
	var polygon = ConvexPolygonShape2D.new()
	polygon.set_points(points)
	add_shape(polygon)
	translate(wallPos)
	connect("body_enter",self,"_body_enter_portal", [destination])
	connect("body_exit",self,"_body_exit_portal")
	
	get_child(0).set_polygon(points)
	get_child(0).set_color(color)
	
func _body_enter_portal(body, destination):
	if body.get("canTeleport") != null:
		print(str(self) + "._body_enter_portal("+str(body)+"," + str(destination)+")")
	if body.get("canTeleport") == true:
		if body.is_in_group("player"):
			body.portalCountDown()
			body.portalTimer.connect("timeout", self, "_teleportToNode", [body, destination])
		else:
			_teleportToNode(body, destination)
		
func _teleportToNode(body, destination):
	print(str(self) + "._teleportToNode("+str(body)+"," + str(destination)+")")
	if overlaps_body(body) :
		body.set_pos(Vector2(body.get_pos().x, body.get_pos().y+300))
		body.set_collision_mask(destination.get_collision_layer())
		body.set_layer_mask(destination.get_collision_layer())
		body.get_parent().remove_child(body)
		body.motion *= -1
		body.canTeleport = false
		
		destination.add_child(body)
		
		if body.is_in_group("player"):
			body.disablePortalProg()
		

func _body_exit_portal(body):
	print(str(self) + "._body_exit_portal("+str(body)+")")
	#if the player timer is still running, stop it
	if body.is_in_group("player"):
		body.disablePortalProg()
		#if the body exited the portal and timer is still connected
		if body.portalTimer.is_connected("timeout", self, "_teleportToNode"):
			body.portalTimer.disconnect("timeout", self, "_teleportToNode")
	if body.canTeleport == false:
		body.canTeleport = true
	
