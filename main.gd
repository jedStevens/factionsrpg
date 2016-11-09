extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process_input(true)

func _input(event):
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
		
		if id == get_tree().get_network_unique_id():
			var camera_scn = load("res://camera.tscn")
			var camera_node = camera_scn.instance()
			node.add_child(camera_node)
			
			node.set_network_mode(NETWORK_MODE_MASTER)
		
		
		get_node("level/players").add_child(node)
