extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var heroku_server_uri = "http://factions-serverlist.herokuapp.com"

var port = 3344

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass


func _on_begin_pressed():
	#Connect to the selected server
	var settings = {}
	
	settings.name = get_node("host_menu/name/line_edit").get_text()
	settings.key = get_node("host_menu/key/line_edit").get_text()
	
	if (settings.name.length() < 1 or settings.key.length() < 1):
		return false;
	
	
	settings.max_users = get_node("host_menu/max_users/HSlider").get_value()
	settings.is_public = get_node("host_menu/add_to_matchlist/network_type").is_pressed()
	settings.password = get_node("host_menu/password/line_edit").get_text()
	settings.port = port
	
	host_game(settings)

func host_game(settings):
	if settings.is_public:
		var added = add_game_to_public_server_list(settings)
		
		if added:
			Globals.set('max_users', settings.max_users)
			Globals.set('password', settings.password)
			Globals.set('username', "test user")
			Globals.set('port', port)
			Globals.set('is_hosting', true)
			get_tree().change_scene("res://game.tscn")
		else:
			print("server was not added, try again please")


func add_game_to_public_server_list(settings):
	var err=0
	var http = HTTPClient.new() # Create the Client

	var err = http.connect(heroku_server_uri,80) # Connect to host/port
	assert(err==OK) # Make sure connection was OK

	# Wait until resolved and connected
	while( http.get_status()==HTTPClient.STATUS_CONNECTING or http.get_status()==HTTPClient.STATUS_RESOLVING):
		http.poll()
		print("Connecting...", http.get_status())
		OS.delay_msec(250)

	assert( http.get_status() == HTTPClient.STATUS_CONNECTED ) # Could not connect

	# Some headers

	var headers=[
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*"
	]

	var params_string = "?name="+str(settings.name)+"&key="+str(settings.key)+"&max_users="+str(settings.max_users)+"&password="+str(settings.password)+"&port="+str(settings.port)
	err = http.request(HTTPClient.METHOD_GET,"/add_server"+params_string,headers) # Request a page from the site (this one was chunked..)

	assert( err == OK ) # Make sure all is OK

	while (http.get_status() == HTTPClient.STATUS_REQUESTING):
		# Keep polling until the request is going on
		http.poll()
		print("Polling...", http.get_status())
		OS.delay_msec(250)


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
				OS.delay_usec(250)
			else:
				rb = rb + chunk # Append to read buffer

		# Done!
		var text = rb.get_string_from_ascii()
		if (text == "Server added!"):
			return true
		return false


func _on_back_pressed():
	get_tree().change_scene("res://main_menu.tscn")
