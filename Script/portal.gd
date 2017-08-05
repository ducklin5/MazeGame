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
	get_child(0).set_polygon(points)
	get_child(0).set_color(color)
	connect("body_enter",self,"_body_enter_portal", [destination])
	connect("body_exit",self,"_body_exit_portal")

func _body_enter_portal(body, destination):
	if body.get("canTeleport") == true:
		if body.is_in_group("player"):
			body.portalCountDown()
			body.portalTimer.connect("timeout", self, "_teleportToNode", [body, destination])
		else:
			_teleportToNode(body, destination)
	elif body.has_user_signal("portalMe"):
		body.connect("portalMe", self, "_teleportToNode", [body, destination])

func _teleportToNode(body, destination):
	if body != null:
		var newbody = clone(body)
		if body.is_in_group("player"):
			newbody.portalTimer.disconnect("timeout", self, "_teleportToNode")
			if body.is_network_master():
				newbody.set_network_mode(NETWORK_MODE_MASTER)
				#newbody.get_node("camera").make_current()
				#body.get_node("camera").clear_current()
			else:
				newbody.set_network_mode(NETWORK_MODE_SLAVE)
			newbody.disablePortalProg()
		newbody.set_collision_mask(destination.get_collision_layer())
		newbody.set_layer_mask(destination.get_collision_layer())
		newbody.canTeleport = false
		newbody.motion *= -1
		destination.add_child(newbody)
		body.queue_free()

func clone(node):
	var newNode = node.duplicate()
	#replicate properties of parent node
	replicateProperties(node,newNode)
	#replicate properties of child tree nodes
	replicateChildProperties(node,newNode)
	return newNode
func replicateChildProperties(fromNode,toNode):
	if fromNode.get_child_count() > 0:
		for child in fromNode.get_children():
			var i = child.get_index()
			replicateProperties(child,toNode.get_child(i))
			replicateChildProperties(child,toNode.get_child(i))
	
func replicateProperties(fromNode,toNode):
	for property in fromNode.get_property_list():
		if property.usage == PROPERTY_USAGE_SCRIPT_VARIABLE : 
					toNode[property.name] = fromNode[property.name]

func _body_exit_portal(body):
	if body.is_in_group("player"):
		body.disablePortalProg()
		if body.portalTimer.is_connected("timeout", self, "_teleportToNode"):
			body.portalTimer.disconnect("timeout", self, "_teleportToNode")
	if body.get("canTeleport") == false:
		body.canTeleport = true
	if body.has_user_signal("portalMe") and body.is_connected("portalMe", self, "_teleportToNode"):
		body.disconnect("portalMe", self, "_teleportToNode")
	
