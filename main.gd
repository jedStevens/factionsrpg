extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process_input(true)
	Globals.set("debug", true)

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

func _on_lobby_start_game( info ):
	remove_all_players()
	for id in info:
		var scn = load("res://"+info[id].character+".tscn")
		var node = scn.instance()
		
		node.set_name(str(id))
		
		node.get_node("username").set_text(info[id].username)
		
		node.set_pos(Vector2(100, 100))
		
		node.set_network_mode(NETWORK_MODE_SLAVE)
		
		node.add_to_group(node.get_name())
		
		if id == get_tree().get_network_unique_id():
			var camera_scn = load("res://camera.tscn")
			var camera_node = camera_scn.instance()
			node.add_child(camera_node)
			
			node.set_network_mode(NETWORK_MODE_MASTER)
		
		
		get_node("level/players").add_child(node)
