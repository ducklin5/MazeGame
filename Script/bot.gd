extends "res://Script/Character.gd"
enum { ROAM = 0, WAIT = 1, CHASE = 2 }
onready var Ray = get_node("ThinkRay")
var r = 0
var rotation = 0
var fovAngle = PI/2
var points={"far" : [] , "near" : []}
var objects = {}
var state = ROAM
var globalDestination = Vector2(0,0)
var roamPoints = []

func _init():
	MOTION_SPEED = 1000

func think():
	if state == ROAM:
		var newRoamPoints = get_parent().get_parent().get_simple_path(get_global_pos(), globalDestination, false)
		if roamPoints.size() < 0 or newRoamPoints.size() == 0: #set a new destination if the current destination is already reached or is unreachable 
			var checkpoints = get_parent().visited
			var randCheckpoint = checkpoints[rand_range(0,checkpoints.size())] + Vector2(0.5,0.5)
			globalDestination = get_parent().get_global_transform().xform(randCheckpoint * get_parent().get_cell_size() * 3)
			roamPoints = get_parent().get_parent().get_simple_path(get_global_pos(), globalDestination, false)
			if roamPoints.size() > 0:
				roamPoints.remove(0) #remove the staring position
		# if the path has more than one point
		
		if roamPoints.size() > 0:
			var distance = roamPoints[0] - get_global_pos() 
			var direction = distance.normalized() # direction of movement
			if distance.length() > 40:
				rotation = atan2(direction.x,direction.y) - PI/2
				print(Vector2(rand_range(0,direction.x),rand_range(0,direction.y)))
				moveDir = direction
			else:
				roamPoints.remove(0)
	scan()
	update()

func scan():
	objects = {}
	points.far = []
	points.near = []
	var alpha = rotation - fovAngle/2
	while alpha < rotation + fovAngle/2  :
		if Ray.is_colliding():
			# update far and near points
			var p = get_global_transform().xform_inv(Ray.get_collision_point())
			if points.far.size() == 0 and points.near.size() == 0:
				points.far.append(p); points.near.append(p);
			elif ceil(p.length()) == ceil(points.far[0].length()):
				points.far.append(p)
			elif floor(p.length()) == floor(points.near[0].length()):
				points.near.append(p)
			elif p.length() > points.far[0].length():
				points.far = [p]
			elif p.length() < points.near[0].length():
				points.near = [p]
			#identify any nearby objects
			if Ray.get_collider().is_in_group("character"):
				objects[Ray.get_collider()] = p
		alpha+=0.2
		Ray.set_rot(alpha)
		Ray.force_raycast_update()

func _draw():
	# if there are points to draw
	if roamPoints.size() > 1:
		for p in roamPoints:
			draw_circle(p - get_global_pos(), 10, Color(1, 0, 0)) # we draw a circle (convert to global position first)
	draw_circle_arc_poly( Vector2(0,0), 100, rotation - fovAngle/2, rotation + fovAngle/2, Color(1,1,0,0.4))
	for p in points.far:
		draw_line(Vector2(0,0), p, Color(1,0,0))
	for p in points.near:
		draw_line(Vector2(0,0), p, Color(0,0,1))
	for p in objects:
		draw_line(Vector2(0,0), objects[p], Color(0,1,0))

func draw_circle_arc_poly( center, radius, angle_from, angle_to, color ):
    var nb_points = 32
    var points_arc = Vector2Array()
    points_arc.push_back(center)
    var colors = ColorArray([color])

    for i in range(nb_points+1):
        var angle_point = angle_from + i*(angle_to-angle_from)/nb_points 
        points_arc.push_back(center + Vector2( cos( angle_point ), -sin( angle_point) ) * radius)
    draw_polygon(points_arc, colors)
