extends TileMap

var randomSeed = 10
var cols = 8
var rows = 8

enum {N=0,E=1,S=2,W=3}

onready var SpawnPoints = get_node("SpawnPoints")

var roomsValue = 2
var rooms = []

var grid = []
var current = Vector2(randi()%cols,randi()%rows)
var visited = []

var portals = {}

signal mazePercentDone(x)
#debugging
#timer for debugging
var t

func _ready():
	rand_seed(randomSeed)
	#t = Timer.new()
	#t.set_wait_time(0.001)
	#t.set_one_shot(true)
	#self.add_child(t)
	
	# make a 2d array that save a [N,E,S,W] array for each cell
	for c in range(0,cols):
		grid.append([])
		for r in range(0,rows):
			grid[c].append([N,E,S,W])
			pass
	
	makeRooms (roomsValue , grid)
	createSpawnPoints()
	emit_signal("mazePercentDone", 25)
	#updateAll()
	current = rooms[0].position
	var uncarved = rows*cols - visited.size()
	drunkardWalk(grid, uncarved*0.6)
	rBactrackMaze(grid, uncarved*0.15)
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
	for x in range (noOfRooms):
	#while rooms.size() < noOfRooms :
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

func drunkardWalk(grid,x):
	var carved = 0
	if visited.find(current) == -1 and x>0:
		visited.append(current)
		carved += 1
	
	while carved < ceil(x) and visited.size() < cols * rows :
		#t.start()
		#yield(t, "timeout")
		#get all neighbors
		var visitedNeighbors = checkNeighbors(current, grid, true)
		var unvisitedNeighbors = checkNeighbors(current, grid, false)
		var neighbors = visitedNeighbors
		for u in unvisitedNeighbors:
			neighbors.append(u)
		var next = neighbors[rand_range(0,neighbors.size())]
		removeWalls(next,current,grid)
		if visited.find(next) == -1:
			visited.append(next)
			carved+=1
		current = next
		#updateAll()
	return true
	
func rBactrackMaze (grid,x):
	var carved = 0
	var next
	var stack = []
	if visited.find(current) == -1 and x>0:
		visited.append(current)
		carved += 1
	while carved < ceil(x) and visited.size() < cols * rows:
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
			carved += 1
			current = next
		elif(stack.size() > 0):
			var neighbors = checkNeighbors(current, grid, true)
			next = neighbors[rand_range(0, neighbors.size())]
			removeWalls(next,current,grid)
			current = stack[-1]
			stack.pop_back()
		else:
			var v = 0; var searching = true
			while v < visited.size() and searching:
				if checkNeighbors(visited[v], grid, false).size() > 0:
					searching = false;
					current = visited[v]; 
				v+=1
		#updateAll()
func mergeRoomMaze():
	# merge maze with rooms
	#list all outer rooom cells
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
		#updateAll()

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
	if visited.has(a):
		# NWall is true if N is not "not found" in Array2d cell a
		var NWall = grid[a.x][a.y].find(N) != -1
		var EWall = grid[a.x][a.y].find(E) != -1
		var SWall = grid[a.x][a.y].find(S) != -1
		var WWall = grid[a.x][a.y].find(W) != -1
		
		#right
		if EWall: 
			for y in range(3):
				set_cell(a.x*3+2,a.y*3+y,2);
			if !NWall && grid[a.x][a.y-1].find(E) == -1:
				set_cell(a.x*3+2,a.y*3-1,9)
			if !SWall && grid[a.x][a.y+1].find(E) == -1:
				set_cell(a.x*3+2,a.y*3+3,11)
		#left
		if WWall: 
			for y in range(3):
				set_cell(a.x*3,a.y*3+y,3);
			if !NWall && grid[a.x][a.y-1].find(W) == -1:
				set_cell(a.x*3,a.y*3-1,8)
			if !SWall && grid[a.x][a.y+1].find(W) == -1:
				set_cell(a.x*3,a.y*3+3,10)
		#top
		if NWall:
			for x in range(3):
				set_cell(a.x*3 + x ,a.y*3,0)
			if EWall:
				set_cell(a.x*3+2,a.y*3,4)
			elif grid[a.x+1][a.y].find(N) == -1:
				set_cell(a.x*3+3,a.y*3,10)
			if WWall:
				set_cell(a.x*3,a.y*3,5)
			elif grid[a.x-1][a.y].find(N) == -1:
				set_cell(a.x*3-1,a.y*3,11)
		#bottom
		if SWall:
			for x in range(3):
				set_cell(a.x*3 + x,a.y*3+2,1)
			if EWall:
				set_cell(a.x*3+2,a.y*3+2,6)
			elif grid[a.x+1][a.y].find(S) == -1:
				set_cell(a.x*3+3,a.y*3+2,8)
			if WWall:
				set_cell(a.x*3,a.y*3+2,7)
			elif grid[a.x-1][a.y].find(S) == -1:
				set_cell(a.x*3-1,a.y*3+2,9)
	else:
		for x in range (3):
			for y in range (3):
				set_cell(a.x*3+x,a.y*3+y,13);
		
	update()

func drawGround():
	print("ping")
	var ground = get_node("Ground")
	for v in visited:
		for x in range (3):
			for y in range (3):
				if get_cell(v.x*3+x,v.y*3+y) == -1:
					ground.set_cell(v.x*3+x,v.y*3+y,12)

func updateAll():
	for i in get_used_cells():
		set_cell(i.x,i.y,-1)
	for c in range(0,cols):
		for r in range(0,rows):
			drawWalls(Vector2(c,r),grid)
	drawGround()
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