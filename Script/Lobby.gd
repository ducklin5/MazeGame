extends Control
var config = ConfigFile.new()
onready var yourIP = find_node("yourIP")

func _ready():
	var err = config.load("user://settings.cfg")
	if err != OK or config.get_value("Player","color") == null:
		config.set_value("Player","name", "Player"+str(randi()))
		config.set_value("Player","color", Color(1,1,1))
		config.save("user://settings.cfg")
	else:
		get_node("connect/Tabs/Settings/nick").set_text(config.get_value("Player","name"))
		get_node("connect/Tabs/Settings/colorPick").set_color(config.get_value("Player","color"))
		
	for i in IP.get_local_addresses():
		if i.find(":") == -1:
			 yourIP.add_item (i)
	gamestate.connect("player_list_changed", self, "refresh_lobby")

func refresh_hostList():
	var host = NetworkedMultiplayerENet.new()
	
	for x in range(168,169):
		for y in range(8,9):
			for z in range(100,200):
				#print("resloving "+str(192)+"."+str(x)+"."+str(y)+"."+str(z))
				host.create_client(str(192)+"."+str(x)+"."+str(y)+"."+str(z), 10567)
				host.poll()
				host.close_connection()
	
	
	

func _on_hostButton_pressed():
	if (find_node("nick").get_text() == ""):
		invalidNick()
	else:
		var name = find_node("nick").get_text()
		var color =  find_node("colorPick").get_color()
		var playerInfo = {"name":name, "color":color}
		gamestate.host_game(playerInfo, find_node("maxPlayers").get_value())
		showWaitLobby()
		refresh_lobby()
		
func _on_joinButton_pressed():
	if (find_node("nick").get_text() == ""):
		invalidNick()
	else:
		var joinIP = get_node("connect/Tabs/Join/joinIP")
		var a = joinIP.get_node("a").get_val(); var b = joinIP.get_node("b").get_val(); var c = joinIP.get_node("c").get_val(); var d = joinIP.get_node("d").get_val()
		var ip = str(a) + "." + str(b) + "." + str(c) + "." + str(d)
		var name = find_node("nick").get_text()
		var color =  find_node("colorPick").get_color()
		var playerInfo = {"name":name, "color":color}
		gamestate.join_game(playerInfo, ip)
		showWaitLobby()
		
func invalidNick():
	find_node("nickError").show()
	find_node("Tabs").set_current_tab(2)
func showWaitLobby():
	find_node("nickError").hide()
	get_node("connect").hide()
	get_node("wait").show()
	
func refresh_lobby():
	var players = gamestate.players
	get_node("wait/playerList").clear()
	for id in players:
		if id == get_tree().get_network_unique_id():
			get_node("wait/playerList").add_item( "-> " + players[id].name + " (You)")
		else:
			get_node("wait/playerList").add_item(players[id].name)
	get_node("wait/playerList").sort_items_by_text()
	get_node("wait/start").set_disabled(not get_tree().is_network_server())
	
func _on_start_pressed():
	gamestate.begin_game()

func _on_nick_text_changed( text ):
	config.set_value("Player","name", text)
	config.save("user://settings.cfg")
	
func _on_colorPick_color_changed( color ):
	config.set_value("Player","color", color)
	config.save("user://settings.cfg")
