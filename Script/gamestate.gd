extends Node

# Default game port
const DEFAULT_PORT = 10567

# Max number of players
const MAX_PEERS = 12

# Name for my player
var player_info = {"name": "PlayerX", "color": Color(randf(),randf(),randf())}

# info for players in id:info_dict format
var players = {} 

#signals
signal player_list_changed()

#function to host game
func host_game(playerInfo, maxPeers = MAX_PEERS):
	#set the host player info
	player_info = playerInfo
	#new networking variable called host
	var host = NetworkedMultiplayerENet.new()
	#make it the server with a maximum of maxPeers connections
	host.create_server(DEFAULT_PORT, maxPeers)
	#add the networking variable to the tree
	get_tree().set_network_peer(host)
	#add myself (server) to 
	players[1] = player_info

#join an existing game
func join_game(playerInfo, ip):
	#set the client player name
	player_info = playerInfo
	#new networking variable called host
	var host = NetworkedMultiplayerENet.new()
	#make it a client on the server 'ip'
	host.create_client(ip, DEFAULT_PORT)
	#add the networking variable to the tree
	get_tree().set_network_peer(host)

func _ready():
	get_tree().connect("connected_to_server", self, "_connected_ok") # run _connect_ok on client when it connects to server
	
func _connected_ok():
	# Im a Client
	# register my ID and info to all other peers including myself
	rpc("register_player", get_tree().get_network_unique_id(), player_info)
	#emit_signal("connection_succeeded")
	
sync func register_player(id, player_info):
	#print("peer " + str(get_tree().get_network_unique_id()) + " just ran register_player( " + str(id) + " , " + str(player_info) +" )")
	
	# If I am the server, let the new guy know about existing players
	if (get_tree().is_network_server()): 
		for p_id in players:
			#resgister remote players to new dude's player dict
			rpc_id(id, "register_player", p_id, players[p_id]) 
			#run register_player on remote player to add new dude to remote players' (except server's) player dict
			if p_id != 1:
				rpc_id(p_id, "register_player", id, player_info) 
	
	# Store the info
	players[id] = player_info
	
	emit_signal("player_list_changed")


func begin_game():
	#only the server can run this function
	assert(get_tree().is_network_server())
	### initiate world with a single random seed on all peers including server ###
	randomize() # randomize the server
	var s = randi() # create a seed, this variable will be used to a similar generate world on all peers
	var spawnpoints = add_world(s) #generate the world on server and store the spawnpoints information
	rpc("add_world",s) #generate the world on all peers

	#print(spawnpoints) #print spawnpoints for debugging
	
	# Create a dictionary with peer id and respective spawn points
	# in the form peerID:spawnPointID
	var peer2spawnPoint = {}
	var spawnIndex = 0
	for p in players:
		peer2spawnPoint[p] = spawnpoints[spawnIndex]
		spawnIndex += 1
		
	var playerLayer = 0
	for p in players:
		for s in spawnpoints:
			if s.layerIndex == playerLayer:
				peer2spawnPoint[p] = s
				playerLayer += 1
				break;
	print(peer2spawnPoint) #print peer2spawnPoint for debugging
	#print("players:" + str(players)) #print players for debugging
	#Call to pre-start game on all peers with the spawn points 
	rpc("pre_start_game", peer2spawnPoint)
	
sync func pre_start_game(peer2spawnPoint):
	#hide the lobby
	get_tree().get_root().get_node("lobby").hide()
	var HUD = load("res://Scenes/HUD.tscn").instance()
	get_parent().add_child(HUD)
	var player_scene = load("res://Scenes/Player.tscn")
	for p_id in peer2spawnPoint:
		var spawn = peer2spawnPoint[p_id]
		var player = player_scene.instance()
		
		if get_tree().get_network_unique_id() == p_id:
			player.set_network_mode(NETWORK_MODE_MASTER)
			player.get_node("camera").make_current()
		else:
			player.set_network_mode(NETWORK_MODE_SLAVE)
		
		player.set_name(str(p_id)) # Use unique ID as node name
		player.set_character_name(players[p_id].name)
		player.set_character_color(players[p_id].color)
		player.set_pos(spawn.spawnPos)
		var x = pow(2,spawn.layerIndex)
		player.set_collision_mask(x)
		player.set_layer_mask(x)
		
		#add player to scene
		var world = get_tree().get_root().get_node("World")
		world.get_child(spawn.layerIndex).add_child(player)
		world.get_child(spawn.layerIndex).set_maze_color(players[p_id].color)
# add a randomly generated 3d maze and also return the its SpawnPoints Array
remote func add_world(worldSeed):
	#new world instance
	var world = load("res://Scenes/World.tscn").instance()
	world.randomSeed = worldSeed
	world.layers = players.size() + 1
	get_tree().get_root().add_child(world)
	
	###/** Seperate Bot spawn points from player Spawn Points **/####
	var PlayerSpawnPoits = []
	var BotSpawnPoints = []
	var l 
	for s in world.SpawnPoints:
		if l != s.layerIndex:
			PlayerSpawnPoits.append(s)
			l = s.layerIndex
		else:
			BotSpawnPoints.append(s)
	
	var botScene = load("res://Scenes/Bot.tscn")
	for s in range(BotSpawnPoints.size()):
		var bot = botScene.instance()
		var spawn = BotSpawnPoints[s]
		bot.set_pos(spawn.spawnPos)
		world.get_child(spawn.layerIndex).add_child(bot)
		var x = pow(2,spawn.layerIndex)
		bot.set_collision_mask(x)
		bot.set_layer_mask(x)
		
	#return array of spawn point dictionaries in the format {"layerIndex": int, "spawnPos": vector2d}
	return PlayerSpawnPoits