extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var heroku_server_uri = "http://factions-serverlist.herokuapp.com"

var server_list = []

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	server_list = get_servers()

func get_servers():
	var err=0
	var http = HTTPClient.new() # Create the Client

	var err = http.connect(heroku_server_uri,80) # Connect to host/port
	assert(err==OK) # Make sure connection was OK

	# Wait until resolved and connected
	while( http.get_status()==HTTPClient.STATUS_CONNECTING or http.get_status()==HTTPClient.STATUS_RESOLVING):
		http.poll()
		print("Connecting..")
		OS.delay_msec(500)

	assert( http.get_status() == HTTPClient.STATUS_CONNECTED ) # Could not connect

	# Some headers

	var headers=[
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*"
	]

	err = http.request(HTTPClient.METHOD_GET,"/servers",headers) # Request a page from the site (this one was chunked..)

	assert( err == OK ) # Make sure all is OK

	while (http.get_status() == HTTPClient.STATUS_REQUESTING):
		# Keep polling until the request is going on
		http.poll()
		OS.delay_msec(500)


	assert( http.get_status() == HTTPClient.STATUS_BODY or http.get_status() == HTTPClient.STATUS_CONNECTED ) # Make sure request finished well.

	if (http.has_response()):

		# This method works for both anyway

		var rb = RawArray() # Array that will hold the data

		while(http.get_status()==HTTPClient.STATUS_BODY):
			# While there is body left to be read
			http.poll()
			var chunk = http.read_response_body_chunk() # Get a
			if (chunk.size()==0):
				# Got nothing, wait for buffers to fill a bit
				OS.delay_usec(1000)
			else:
				rb = rb + chunk # Append to read buffer
		
		# Done!
		var text = rb.get_string_from_ascii()
		
		var servers = parse_for_servers(text)
		
		if servers.servers.size() > 0:
			get_node("server_list/container").remove_child(get_node("server_list/container/item"))
		
		var i = 0
		for server in servers.servers:
			
			var node = preload("res://server_item.tscn").instance()
			node.get_node("spacer/labels/server_name").set_text(server['name'])
			node.get_node("spacer/labels/users").set_text("?/" + str(server['max_users']) + " Users")
			node.get_node("spacer/ping").set_text("??? ms")
			node.get_node("spacer/labels/join").connect("pressed", self, "join_server", [i])
			node.ip = server['ip']
			node.port=server['port']
			get_node("server_list/container").add_child(node)
			i += 1
		return servers

func parse_for_servers(text):
	var dict = Dictionary()
	dict.parse_json(text)
	return dict

func _on_back_pressed():
	get_tree().change_scene("res://main_menu.tscn")

func join_server(index):
	var server_item = get_node("server_list/container").get_child(index)
	Globals.set("ip", server_item.get_ip())
	Globals.set("port", server_item.get_port())
	get_tree().change_scene("res://game.tscn")