extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process(true)

func _process(delta):
	get_node("max_users/labels/count").set_text(str(get_max_users()))

func get_max_users():
	return get_node("max_users/HSlider").get_value()

func get_is_public():
	return get_node("add_to__matchlist/network_type").is_pressed()

func get_password():
	return get_node("password/line_edit").get_text()

func get_server_name():
	return get_node("name/line_edit").get_text()
func get_server_key():
	return get_node("key/line_edit").get_text()