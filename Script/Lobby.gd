extends Control
var config = ConfigFile.new()
var udp = PacketPeerUDP.new()
const DEFAULT_PORT = 10567
const MAGIC = "sfjs343"
var hostsArray = []
onready var yourIP = find_node("yourIP")
onready var hostList = get_node("connect/Tabs/Join/hostList")
onready var joinIP = get_node("connect/Tabs/Join/joinIP")

var my_ip
var t = Timer.new()

func _ready():
	#get settings from file
	var err = config.load("user://settings.cfg")
	if err != OK or config.get_value("Player","color") == null:
		config.set_value("Player","name", "Player"+str(randi()))
		config.set_value("Player","color", Color(1,1,1))
		config.save("user://settings.cfg")
	else:
		get_node("connect/Tabs/Settings/nick").set_text(config.get_value("Player","name"))
		get_node("connect/Tabs/Settings/colorPick").set_color(config.get_value("Player","color"))
	
	# get local address
	my_ip = IP.resolve_hostname(IP.get_local_addresses()[1], 1)
	yourIP.add_item(my_ip)
	
	#connect signals
	gamestate.connect("player_list_changed", self, "refresh_lobby")
	
	#create timer
	t.set_wait_time(1)
	add_child(t)
	t.start()
	#get game servers on local network
	
	refresh_hostList()


func _on_hostButton_pressed():
	if (find_node("nick").get_text() == ""):
		invalidNick()
		return;
	udp.close()
	var err = udp.set_send_address('255.255.255.255',DEFAULT_PORT)
	if (err != OK):
		print("Error:\nCan't resolve.")
	else:
		var name = find_node("nick").get_text()
		var color =  find_node("colorPick").get_color()
		var playerInfo = {"name":name, "color":color}
		gamestate.host_game(playerInfo, find_node("maxPlayers").get_value())
		showWaitLobby()
		refresh_lobby()
		while(true):
			var data = [MAGIC,get_node("connect/Tabs/Host/serverName").get_text()]
			udp.put_var(data)
			yield(t,"timeout")

func refresh_hostList():
	var err = udp.listen(DEFAULT_PORT)
	if (err != OK):
		print("Error:\nCan't listen.")
	else:
		get_node("connect/Tabs/Join/refresh").set_disabled(true)
		hostsArray = []
		hostList.clear()
		var n = 10
		while n > 0:
			if udp.get_available_packet_count() > 0:
				var packet = udp.get_var()
				var hostIP = udp.get_packet_ip()
				var port = udp.get_packet_port()
				
				if packet[0] == MAGIC and !hostsArray.has(hostIP):
					hostsArray.append(hostIP)
					hostList.add_item(packet[1])
			yield(t,"timeout")
			n-=1
		get_node("connect/Tabs/Join/refresh").set_disabled(false)

func _on_hostList_item_selected( index ):
	var ip = hostsArray[index]
	var ipFloats = ip.split_floats(".")
	for i in range (4):
		joinIP.get_child(i).set_val(ipFloats[i])

func _on_joinButton_pressed():
	if (find_node("nick").get_text() == ""):
		invalidNick()
	else:
		var ip = ""
		for i in range (4):
			ip += str(joinIP.get_child(i).get_val())
			if i < 3 : ip += "."
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
