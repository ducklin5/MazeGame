extends Node2D

const mazeLayerScene = preload("res://Scenes/MazeLayer.tscn")
var layers = 2
var randomSeed = 1
var SpawnPoints = []
var portals = 4

func _ready():
	var mazeLayer
	seed(randomSeed)
	for l in range(layers):
		mazeLayer = mazeLayerScene.instance()
		mazeLayer.randomSeed = randi()
		mazeLayer.set_name(str(l))
		mazeLayer.set_collision_layer(pow(2,l))
		mazeLayer.set_collision_mask(pow(2,l))
		mazeLayer.set_pos(Vector2(l*300,10))
		#mazeLayer.hide()
		add_child(mazeLayer)
		for c in mazeLayer.get_node("SpawnPoints").get_children():
			SpawnPoints.append({"layerIndex": l, "spawnPos": c.get_pos()})
	# make portals to jump between mazes
	createPortals()

func commonWallCheck(grid_A, grid_B, x, y):
	var walls = []
	for wall in grid_A[x][y]:
		if grid_B[x][y].find(wall) != -1:
			walls.append(wall)
	return walls

func createPortals():
	var portal = load("res://Scenes/Portal.tscn")
	for l in range(layers):
		var thisMaze = get_node(str(l))
		var next 
		if l == layers - 1 :
			next = 0
		else:
			next = l+1
			
		var nextMaze = get_node(str(next))
		
		var commonWalls = []
		for c in range(thisMaze.cols):
			for r in range(thisMaze.rows):
				var w = commonWallCheck(thisMaze.grid,nextMaze.grid,c,r)
				if w.size() != 0:
					commonWalls.append({"pos":Vector2(c,r),"walls":w})
		var n = 0
		while n < portals:
			var cell = commonWalls[rand_range(0,commonWalls.size())]
			if not thisMaze.portals.has(cell.pos) and not nextMaze.portals.has(cell.pos):
				#print( thisMaze.get_name() + " and " + nextMaze.get_name() + " do not have portals in " + str(cell.pos))
				var w = cell.walls[rand_range(0,cell.walls.size())]
				var tileCell_size = thisMaze.get_cell_size()
				var mazeCell_size = thisMaze.get_cell_size() * 3
				var mazeCell_pos = mazeCell_size * cell.pos
				
				var portalArea = portal.instance()
				portalArea.size = tileCell_size
				portalArea.wall = w
				portalArea.set_pos(mazeCell_pos)
				portalArea.set_name(str(cell.pos))
				portalArea.destination = nextMaze
				portalArea.color = Color(0,0,1,0.5)
				portalArea.set_collision_mask(thisMaze.get_collision_layer())
				portalArea.set_layer_mask(thisMaze.get_collision_layer())
				thisMaze.get_node("Portals").add_child(portalArea)
				
				var newPortalArea = portal.instance()
				newPortalArea.size = tileCell_size
				newPortalArea.wall = w
				newPortalArea.set_pos(mazeCell_pos)
				newPortalArea.set_name(str(cell.pos))
				newPortalArea.destination = thisMaze
				newPortalArea.color = Color(1,0,0,0.5)
				newPortalArea.set_collision_mask(nextMaze.get_collision_layer())
				newPortalArea.set_layer_mask(nextMaze.get_collision_layer())
				nextMaze.get_node("Portals").add_child(newPortalArea)
				
				thisMaze.portals[cell.pos] = w
				nextMaze.portals[cell.pos] = w
				
				n += 1