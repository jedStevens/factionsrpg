# Typical lobby implementation, imagine this being in /root/lobby

extends Node
var timer = null
# Connect all functions

signal start_game(info)

func game_log(message):
	get_node("VBoxContainer/TextEdit").set_text(get_node("VBoxContainer/TextEdit").get_text() + message + "\n")
func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	set_process(true)
	timer = Timer.new()
	
	get_node("VBoxContainer/play").connect("pressed", self, "start_game")
	
	fill_character_box()

func fill_character_box():
	get_node("menu/container/character").add_item("warrior", 1)
	get_node("menu/container/character").add_item("mage", 2)
	get_node("menu/container/character").add_item("archer", 3)

func _process(delta):
	if timer.get_time_left() != 0:
		print("Timer left: ", timer.get_time_left())
	
	for id in player_info:
		get_node("VBoxContainer/players/"+str(id)).get_node("labels/ready").set_pressed(player_info[id].ready)
	
	check_play_button()

# Player info, associate ID to data
var player_info = {}
# Info we send to other players
var my_info = { username = "null", character = null, ready = false }

var PlayerItem = preload("res://player_lobby_item.tscn")

var players = {}

var is_host = false

func _player_connected(id):
	pass

func _player_disconnected(id):
	var node = get_node("VBoxContainer/players").get_node("player"+str(id))
	get_node("VBoxContainer/players").remove_child(node)

	player_info.erase(id) # Erase player from info

func _connected_ok():
    # Only called on clients, not server. Send my ID and info to all the other peers
    rpc("register_player", get_tree().get_network_unique_id(), my_info)

func _server_disconnected():
	player_info = {}
	build_lobby()

func _connected_fail():
	player_info = {}
	build_lobby()
	# SHOW SOME DIALOG

remote func register_player(id, info):
	# Store the info
	player_info[id] = info
	
	game_log("Player Conntected: "+ player_info[id].username)
	
	# If I'm the server, let the new guy know about existing players
	if (get_tree().is_network_server()):
		for peer_id in player_info:
			rpc_id(id, "register_player", peer_id, player_info[peer_id])
	
	build_lobby()


func connect_to_server(ip, port):
	game_log("Connecting to: "+ ip+":"+str(port))
	player_info = {}
	
	my_info.username = get_node("menu/container/username").get_text()
	my_info.character = get_node("menu/container/character").get_text()
	
	var host = NetworkedMultiplayerENet.new()
	host.create_client(ip, port)
	get_tree().set_network_peer(host)
	
func start_server(port=3000):
	player_info = {}
	
	my_info.username = get_node("menu/container/username").get_text()
	my_info.character = get_node("menu/container/character").get_text()
	game_log("Hosting Server\n")
	
	var host = NetworkedMultiplayerENet.new()
	host.create_server(port, 4)
	get_tree().set_network_peer(host) 
	
	var addresses = IP.get_local_addresses()
	var ip = '127.0.0.1'
	
	for add in addresses:
		if add.begins_with("192."):
			ip = add
			break
	
	get_node("menu/container/ip").set_text(ip)
	get_node("menu/container/port").set_text(str(port))
	
	register_player(1, my_info)
	
	is_host = true
	pass


func _on_host_pressed():
	player_info = {}
	build_lobby()
	var port = 3000
	if get_node("menu/container/port").get_text().length() > 0:
		port = int(get_node("menu/container/port").get_text())
		print("Hosting on port: ", port)
	
	get_node("VBoxContainer/TextEdit").set_text("")
	
	start_server(port)
	

func _on_connect_pressed():
	_on_cancel_pressed()
	
	print("Connecting in 3 seconds")
	timer.connect("timeout", self, "connect_to_server", [get_node("menu/container/ip").get_text(), int(get_node("menu/container/port").get_text())])
	timer.set_wait_time(0.25)
	timer.start()
	timer.set_one_shot(true)
	
	get_node("VBoxContainer/TextEdit").set_text("")
	
	add_child(timer)

func clear_all_from_lobby():
	for c in get_node("VBoxContainer/players").get_children():
		get_node("VBoxContainer/players").remove_child(c)


remote func toggle_ready(ready, id):
	player_info[id].ready = ready
	if id == get_tree().get_network_unique_id():
		rpc("toggle_ready", player_info[id].ready, id)

func check_play_button():
	
	get_node("VBoxContainer/play").set_disabled(true)
	
	if not is_host:
		return
	
	get_node("VBoxContainer/play").set_disabled(false)
	
	for id in player_info:
		if player_info[id].ready == false:
			get_node("VBoxContainer/play").set_disabled(true)
			return

func build_lobby():
	clear_all_from_lobby()
	for id in player_info:
		var node = PlayerItem.instance()
		print("Added player "+str(id) + " to lobby")
		node.set_name(str(id))
		
		node.get_node("labels/username").set_text(player_info[id].username)
		
		node.get_node("labels/character").set_text(get_node("menu/container/character").get_text())
		
		if id == get_tree().get_network_unique_id():
			node.get_node("labels/ready").connect("toggled", self, "toggle_ready", [get_tree().get_network_unique_id()])
		
		get_node("VBoxContainer/players").add_child(node)
	
func _on_cancel_pressed():
	player_info = {}
	build_lobby()
	get_node("VBoxContainer/TextEdit").set_text("")
	get_tree().set_network_peer(null)

remote func start_game():
	game_log("Starting Game: " + str(player_info) + "\n")
	
	emit_signal("start_game", player_info)
	
	if get_tree().is_network_server():
		rpc("start_game")
		pass