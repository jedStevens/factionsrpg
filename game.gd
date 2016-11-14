extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"


const GUEST_USERNAME_LEN = 10

const NET_REQUEST_CONNECTION = "cr"
const NET_ACCEPT_CONNECTION = "ca"
const NET_ACTION = "a"
const NET_UPDATE_OVERRIDE = "u"

const GAME_ACTION_SPAWN_PLAYER = "s"
const GAME_ACTION_DELETE_PLAYER = "d"
const GAME_ACTION_CHAT_MESSAGE = "c"

const NETWORK_FPS = 1


var player_info = {}
var my_info = {username = "guest", character = "mage" , net_id=-1} ;

var websocket = null;
var is_connecting = false

var spawn = Vector2(300, 450)
var timer = 0
var bad_chars = ["(",")"," "]

const correction_radius = 128

func _ready():

	set_process_input(true)
	
	set_process(true)
	
	Globals.set("debug", true)
	
	if Globals.get('username'):
		my_info.username = Globals.get('username')
	
	websocket = preload('ws.gd').new(self)
	websocket.start('boiling-waters-10225.herokuapp.com',80)
	websocket.set_reciever(self,'_on_message')
	is_connecting = true

func safe_string(s):
	var out = s
	for c in bad_chars:
		out = out.replace(c, "")
	return out

func _process(delta):
	if is_connecting:
		if websocket.on_accept != null:
			print("Connection Accepted, user has id#", websocket.on_accept)
			my_info.net_id = websocket.on_accept
			is_connecting = false
			websocket.send('a:s:'+str(my_info.net_id)+":"+str(my_info.username)+":"+str(my_info.character)+":450:300")

	if websocket.pre_commands.size() > 0:
		for command in websocket.pre_commands:
			print("RUNNING PRE: ")
			_on_message(command)
		websocket.pre_commands = []

	var duration = 1.0 / NETWORK_FPS
	
	if get_node("level/objects/"+str(my_info.net_id)) != null:
		if (timer < duration):
			timer += delta
		else:
			timer = 0
			websocket.send("u:"+str(my_info.net_id)+":"+safe_string(str(get_node("level/objects/"+str(my_info.net_id)).get_global_pos())).replace(",",":"))

func spawn_player(net_id, username, character, position):
	print("Adding  player #", net_id, " at: ", position, " named ", username, " as the ", character)
	var node = load("res://"+character+".tscn").instance()
	node.set_pos(position)
	node.set_name(str(net_id))
	if username=="guest":
		username += str(net_id)
	node.get_node("username").set_text(username)
	
	if net_id == my_info.net_id:
		var cam = preload("res://camera.tscn").instance()
		cam.make_current()
		node.get_node("CollisionShape2D").add_child(cam)
		node.set_is_local(true)
		print("Added camera")
	
	get_node("level/objects").add_child(node)

func delete_player(net_id):
	get_node("level/objects").remove_child(get_node("level/objects/"+str(net_id)))

func on_accept(data):
	print(data)
# handler to text messages

func vec2_from_str(v):
	#Assumes format (x, y)
	var args = v.replace("(", "").replace(")", "").split(",")
	return Vector2(float(args[0]), float(args[1]))

func _on_message(msg):
	print("IN: ", msg)
	var args = msg.split(":")
	if msg.begins_with(NET_ACCEPT_CONNECTION):
		var args = msg.split(":")
		
		var net_id = args[1];
		
		my_info.net_id = net_id;
		
		print("Player Connected", net_id);
	
	elif args[0] == NET_ACTION:
		if args[1] == GAME_ACTION_SPAWN_PLAYER:
			print("Spawning player")
			spawn_player(int(args[2]), args[3], args[4], Vector2(int(args[5]), int(args[6])))
		
		if args[1] == GAME_ACTION_DELETE_PLAYER:
			print("removing player")
			delete_player(int(args[2]))
		
		if args[1] == "m":
			print("(", str(my_info.net_id) == str(args[2]), ") Moving player ", args[2] , " to ", args[3], ", ", args[4])
			if str(args[2]) == str(my_info.net_id):
				print("moving self")
				var node = get_node("level/objects/"+str(my_info.net_id))
				var p = Vector2(int(args[3]), int(args[4]))
				print("walking to point: ", p)
				node.walk_to(p)
				print("moved self")
			else:
				get_node("level/objects/"+str(args[2])).set_target(Vector2(int(args[3]), int(args[4])))
		
		if args[2] == "spell_0":
			var node = preload("res://death_bolt.tscn").instance()
			node.set_pos(vec2_from_str(args[3]))
			get_node("level/objects").add_child(node)
		elif args[2] == "spell_1":
			var node = preload("res://death_curse.tscn").instance()
			node.set_pos(vec2_from_str(args[3]))
			get_node("level/objects").add_child(node)
	
	elif msg.begins_with(NET_REQUEST_CONNECTION):
		print("Join Request: ", msg)
	
	elif args[0] == NET_UPDATE_OVERRIDE: # "u:"
		var new_pos = Vector2(int(args[2]), int(args[3]))
		if new_pos.distance_to(get_node("level/objects").get_node(str(args[1])).get_pos()) > correction_radius:
			get_node("level/objects").get_node(str(args[1])).set_pos(new_pos)


func _input(event):
	var mouse_pos = get_global_mouse_pos()
	if str(my_info.net_id) != "-1":
		if event.type == InputEvent.KEY:
			if event.is_action_pressed("hide_ui"):
				get_node("CanvasLayer/lobby").set_opacity(1 - get_node("CanvasLayer/lobby").get_opacity())
				return
	
			if event.is_action_pressed("spell_0"):
				websocket.send(NET_ACTION+":"+str(my_info.net_id)+":spell_0:"+safe_string(str(mouse_pos).replace(",",":")))
	
			if event.is_action_pressed("spell_1"):
				websocket.send(NET_ACTION+":"+str(my_info.net_id)+":spell_1:"+safe_string(str(mouse_pos).replace(",",":")))
	
		if event.type == InputEvent.MOUSE_BUTTON:
			if event.pressed and event.button_index == 2:
				websocket.send(NET_ACTION+":m:"+str(my_info.net_id)+":"+safe_string(str(mouse_pos).replace(",",":")))
				var node = get_node("level/objects/"+str(my_info.net_id))
				if node != null:
					node.play_ui_animation("walk_to", mouse_pos)

func remove_all_players():
	for c in get_node("level/players").get_children():
		get_node("level/players").remove_child(c)
