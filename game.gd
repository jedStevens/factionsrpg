extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var player_info = {}
var my_info = {username = "", character = "" } ;
func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	
	## Networking
	
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	##
	
	
	
	set_process_input(true)
	Globals.set("debug", true)

	if (Globals.get("is_hosting")):
		start_server()
	else:
		join_server()

func _player_connected(id):
	print("Connection at id #",id)
	pass

func _player_disconnected(id):
	player_info.erase(id) # Erase player from info

func _connected_ok():
    # Only called on clients, not server. Send my ID and info to all the other peers
    rpc("register_player", get_tree().get_network_unique_id(), my_info)

func _server_disconnected():
	pass

func _connected_fail():
	pass
	# SHOW SOME DIALOG

func start_server():
	var port = Globals.get("port")
	player_info = {}

	my_info.username = Globals.get('username')
	my_info.character = "mage"

	var host = NetworkedMultiplayerENet.new()
	host.create_server(port, int(Globals.get('max_users')))
	get_tree().set_network_peer(host)

	register_player(1, my_info)

func join_server():
	var ip = Globals.get("ip")
	var port = Globals.get("port")
	
	print ("Trying to join: ", ip, ":", port)

	player_info = {}

	my_info.username = Globals.get("username")
	my_info.character = "mage"

	var host = NetworkedMultiplayerENet.new()
	host.create_client(ip, int(port))

	get_tree().set_network_peer(host)
	
	print("Connected to: ", ip, ":", port)

remote func register_player(id, info):
	print("Registering Player: ", id)
	# Store the info
	player_info[id] = info

	add_player(id, player_info[id] )

	# If I'm the server, let the new guy know about existing players
	if (get_tree().is_network_server()):
		for peer_id in player_info:
			rpc_id(id, "register_player", peer_id, player_info[peer_id])

func add_player( id, info ):
	var scn = load("res://"+info.character+".tscn")
	var node = scn.instance()
	node.set_name(str(id))

	node.get_node("username").set_text(info.username)

	#SPAWN POINT HERE
	node.set_pos(Vector2(100, 100))

	node.set_network_mode(NETWORK_MODE_SLAVE)

	node.add_to_group(node.get_name())

	if id == get_tree().get_network_unique_id():
		# If this is our player
		var camera_scn = load("res://camera.tscn")
		var camera_node = camera_scn.instance()
		node.add_child(camera_node)

		node.set_network_mode(NETWORK_MODE_MASTER)


	get_node("level/players").add_child(node)

func _input(event):
	if event.type == InputEvent.KEY:
		if event.is_action_pressed("hide_ui"):
			get_node("CanvasLayer/lobby").set_opacity(1 - get_node("CanvasLayer/lobby").get_opacity())
			return

		if event.is_action_pressed("spell_0"):
			var player = get_node("level/players/"+str(get_tree().get_network_unique_id()))

			if player != null:
				player.rpc("cast", 0, get_global_mouse_pos())
				#player.walk_to(get_global_mouse_pos())

		if event.is_action_pressed("spell_1"):
			var player = get_node("level/players/"+str(get_tree().get_network_unique_id()))

			if player != null:
				player.rpc("cast", 1, get_global_mouse_pos())
				#player.walk_to(get_global_mouse_pos())

	if event.type == InputEvent.MOUSE_BUTTON:
		if event.pressed and event.button_index == 2:
			var player = get_node("level/players/"+str(get_tree().get_network_unique_id()))

			if player != null:
				player.rpc("walk_to", get_global_mouse_pos())
				#player.walk_to(get_global_mouse_pos())

func remove_all_players():
	for c in get_node("level/players").get_children():
		get_node("level/players").remove_child(c)
