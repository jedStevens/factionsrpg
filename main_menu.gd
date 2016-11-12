extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	if Globals.get("username") == null:
		get_node("log_in_pop_up").popup()
		get_node("start_fight_button").set_disabled(true)
		get_node("join_fight_button").set_disabled(true)


func _on_start_fight_button_pressed():
	get_tree().change_scene("res://host_game_menu.tscn")


func _on_join_fight_button_pressed():
	get_tree().change_scene("res://join_game_menu.tscn")


func _on_log_in_pressed():
	# Pretend like we logged in
	Globals.set("username", get_node("log_in_pop_up/VBoxContainer/username/LineEdit").get_text())
	get_node("start_fight_button").set_disabled(false)
	get_node("join_fight_button").set_disabled(false)
	get_node("log_in_pop_up").hide()
	pass # replace with function body


func _on_guest_pressed():
	Globals.set("username", "guest")
	get_node("start_fight_button").set_disabled(false)
	get_node("join_fight_button").set_disabled(false)
	get_node("log_in_pop_up").hide()
	pass # replace with function body
