extends TileMap


export var randomSeed = 1
var cols = 4
var rows = 4

enum {N=0,E=1,S=2,W=3}

onready var SpawnPoints = get_node("SpawnPoints")

#const room = preload("res://Scenes/Room.tscn")
export var roomsValue = 1
var rooms = []

var start = Vector2(0,0)
var grid = []
var current
var visited = []

var portals = {}

#debugging
#timer for debugging
var t

func _ready():
	rand_seed(randomSeed)
	
	t = Timer.new()
	t.set_wait_time(2)
	t.set_one_shot(true)
	#self.add_child(t)
	
	# make a 2d array that save a [N,E,S,W] array for each cell
	for c in range(0,cols):
		grid.append([])
		for r in range(0,rows):
			grid[c].append([N,E,S,W])
			pass
	
	set_fixed_process(true)
	makeRooms (roomsValue , grid)
	createSpawnPoints()
	rBactrackMaze(grid)
	updateAll()


class room:
	var position = Vector2()
	var size = Vector2()
	var Cells = []
	func setup(p,s):
		position = p
		size = s
		for i in range (0,size.x):
			for j in range (0,size.y):
				Cells.append(Vector2(position.x+i, position.y+j))
	func get_area():
		return Cells.size()

func makeRooms (noOfRooms , grid):
	while rooms.size() < noOfRooms :
		#randomize()
		#pick a random room size and position
		var roomSize = Vector2(2,2)
		var roomPosition = Vector2(floor(rand_range(0,cols-roomSize.x+1)),floor(rand_range(0,rows-roomSize.y+1)))
		# make a new room instance called randRoom and set it up with these ^ variables
		var randRoom = room.new()
		randRoom.setup(roomPosition, roomSize)
		#validation variable: checks if the room collides with other rooms
		var collides = false 
		#check if any of randRoom's cells are already in another room, if so it has collided
		for k in randRoom.Cells:
			for r in rooms:
				if r.Cells.find(k) != -1:
					collides = true; break
			if collides == true:
				break
		#if the room didnt collide, add its cells to visited and set their approriate walls in the grid
		#finally add the room instance to the rooms array
		if collides == false:
			for k in randRoom.Cells:
				visited.append(k)
				#remove all walls of the cells in the grid
				grid[k.x][k.y] = []
				#add approriate walls
				if k.x == roomPosition.x:
					grid[k.x][k.y].append(W)
				if k.y == roomPosition.y:
					grid[k.x][k.y].append(N)
				if k.x == roomPosition.x + roomSize.x - 1:
					grid[k.x][k.y].append(E)
				if k.y == roomPosition.y + roomSize.y - 1:
					grid[k.x][k.y].append(S)
			#add the room to the rooms array
			rooms.append(randRoom)
			
	update()
	
func rBactrackMaze (grid):
	#randomize()
	var prevStack = []
	var waitForDeadEnd = 0
	var imperfect = 20
	var next
	var stack = []
	current = start
	visited.append(current)
	var notDone = true
	while notDone:
		#timmer for debugging
		#t.start()
		#yield(t, "timeout")
		#debugging ends
		var neighbors = checkNeighbors(current, grid, false)
		if neighbors.size()>0:
			next = neighbors[rand_range(0, neighbors.size())]
			removeWalls(next,current,grid)
			stack.append(current)
			visited.append(next)
			current = next
		elif(stack.size() > 0):
			#randomize()
			if(stack.size() > prevStack.size()):
				neighbors = checkNeighbors(current, grid, true)
				next = neighbors[rand_range(0, neighbors.size())]
				removeWalls(next,current,grid)
			prevStack = stack
			current = stack[-1]
			stack.pop_back()
		elif(visited.size() < cols * rows):
			prevStack = []
			var searching = true
			for r in range (0, rows):
				if searching:
					for c in range (0, cols):
						if visited.find(Vector2(c,r)) == -1:
							current = Vector2(c,r); 
							searching = false
							break;
				else: break;
		else:
			
			notDone = false
			pass
		updateAll()
	# merge maze with rooms
	#list all outer roooms
	for i in rooms:
		var roomDoor = null
		var roomOuterCells = []		
		for j in i.Cells:
			if j.x == i.position.x || j.x == i.position.x + i.size.x - 1 || j.y == i.position.y || j.y == i.position.y + i.size.y - 1 :
				roomOuterCells.append(j)
		while roomDoor == null:
			var possibleDoor = roomOuterCells[floor(rand_range(0,roomOuterCells.size()))]
			var possibleDoorNeighbors = checkNeighbors(possibleDoor,grid,true)
			var outOfRoomNeighbors = []
			for k in possibleDoorNeighbors:
				if i.Cells.find(k) == -1:
					outOfRoomNeighbors.append(k)
			if outOfRoomNeighbors.size()>0:
				roomDoor = possibleDoor
				removeWalls(roomDoor,outOfRoomNeighbors[floor(rand_range(0,outOfRoomNeighbors.size()))], grid)
	updateAll()
	

## returns all  neighbors
func checkNeighbors (vectorPos, grid, isVisited):
	var allNeighbors = [] 
	#North
	if vectorPos.y > 0 :
		allNeighbors.append(Vector2(vectorPos.x,vectorPos.y-1))
	#East
	if vectorPos.x < grid.size()-1 :
		allNeighbors.append(Vector2(vectorPos.x+1,vectorPos.y))
	#South
	if vectorPos.y < grid[vectorPos.x].size()-1 :
		allNeighbors.append(Vector2(vectorPos.x,vectorPos.y+1))
	#West
	if vectorPos.x > 0 :
		allNeighbors.append(Vector2(vectorPos.x-1,vectorPos.y))
		
	var visitedNeighbors = []
	var unvisitedNeighbors = []
		
	for n in allNeighbors : 
		if visited.find(n) != -1:
			visitedNeighbors.append(n)
		else:
			unvisitedNeighbors.append(n)
	if isVisited:
		return visitedNeighbors
	else:
		return unvisitedNeighbors

func removeWalls (a,b,grid) :
	#North
	if a.y - b.y == 1 :
		grid[a.x][a.y].erase(N); grid[b.x][b.y].erase(S)
	#East
	if a.x - b.x == -1 :
		grid[a.x][a.y].erase(E); grid[b.x][b.y].erase(W)
	#South
	if a.y - b.y == -1 :
		grid[a.x][a.y].erase(S); grid[b.x][b.y].erase(N)
	#West
	if a.x - b.x == 1 :
		grid[a.x][a.y].erase(W); grid[b.x][b.y].erase(E)
	
func drawWalls (a, grid):
	# NWall is true if N is not "not found" in Array2d cell a
	var NWall = grid[a.x][a.y].find(N) != -1
	var EWall = grid[a.x][a.y].find(E) != -1
	var SWall = grid[a.x][a.y].find(S) != -1
	var WWall = grid[a.x][a.y].find(W) != -1
	
	var ground = get_node("Floor")
	for x in range(3):
		for y in range(3):
			ground.set_cell(a.x*3+x,a.y*3+y,0)
	#right
	if EWall: 
		for y in range(3):
			set_cell(a.x*3+2,a.y*3+y,2);	ground.set_cell(a.x*3+2,a.y*3+y,3)
		if !NWall && grid[a.x][a.y-1].find(E) == -1:
			set_cell(a.x*3+2,a.y*3-1,5)
		if !SWall && grid[a.x][a.y+1].find(E) == -1:
			set_cell(a.x*3+2,a.y*3+3,7)
	#left
	if WWall: 
		for y in range(3):
			set_cell(a.x*3,a.y*3+y,3);		ground.set_cell(a.x*3,a.y*3+y,4)
		if !NWall && grid[a.x][a.y-1].find(W) == -1:
			set_cell(a.x*3,a.y*3-1,4)
		if !SWall && grid[a.x][a.y+1].find(W) == -1:
			set_cell(a.x*3,a.y*3+3,6)
	#top
	if NWall:
		for x in range(3):
			set_cell(a.x*3 + x ,a.y*3,0)
		if EWall:
			set_cell(a.x*3+2,a.y*3,4)
		elif grid[a.x+1][a.y].find(N) == -1:
			set_cell(a.x*3+3,a.y*3,6)
		if WWall:
			set_cell(a.x*3,a.y*3,5)
		elif grid[a.x-1][a.y].find(N) == -1:
			set_cell(a.x*3-1,a.y*3,7)
	#bottom
	if SWall:
		for x in range(3):
			set_cell(a.x*3 + x,a.y*3+2,1)
		if EWall:
			set_cell(a.x*3+2,a.y*3+2,6)
		elif grid[a.x+1][a.y].find(S) == -1:
			set_cell(a.x*3+3,a.y*3+2,4)
		if WWall:
			set_cell(a.x*3,a.y*3+2,7)
		elif grid[a.x-1][a.y].find(S) == -1:
			set_cell(a.x*3-1,a.y*3+2,5)
	
	update()

func updateAll():
	for i in get_used_cells():
		get_node("Floor").set_cell(i.x,i.y,-1)
		set_cell(i.x,i.y,-1)
	for c in range(0,cols):
		for r in range(0,rows):
			drawWalls(Vector2(c,r),grid)
			#up date debugging map
			#get_child(0).set_pos(Vector2((cols+1)*3*get_cell_size().x,0))
			get_child(0).update()

#creater a spawn point
func createSpawnPoints():
	var n = 0
	# create a spawn point in each room
	for r in rooms:
		var point = Position2D.new()
		var mazeCellPixelSize = 3*get_cell_size()
		#set the position of the spawnPoint to the pixel center of the room
		point.set_pos((r.position + r.size/2)*mazeCellPixelSize)
		#set the name of the Point
		point.set_name(str(n))
		#add the point to SpawnPoints
		SpawnPoints.add_child(point)
		n+=1

#set the maze color modulate:
func set_maze_color(color):
	pass