extends "player.gd"

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

master func cast(spell_num, pos):
	if spell_num == 0:
		rpc("add_spell_0", pos)
		add_spell_0(pos)
		return
	if spell_num == 1:
		rpc("add_spell_1", pos)
		add_spell_1(pos)
		return

slave func add_spell_0(pos):
		var node = preload("res://death_bolt.tscn").instance()
		
		var dir = pos - get_pos()
		dir = dir.normalized()
		
		node.set_pos(get_pos() + dir * 64)
		node.velocity = dir
		
		get_tree().get_root().get_node("Node/level/players").add_child(node)

slave func add_spell_1(pos):
		var node1 = preload("res://death_curse.tscn").instance()
		var node2 = preload("res://death_curse.tscn").instance()
		var node3 = preload("res://death_curse.tscn").instance()
		
		var dir = pos - get_pos()
		dir = dir.normalized()
		
		node1.set_pos(get_pos() + dir * 16)
		node1.velocity = dir
		
		node2.set_pos(get_pos() + dir.rotated(PI/4) * 16)
		node2.velocity = dir.rotated(PI/4)
		
		node3.set_pos(get_pos() + dir.rotated(-PI/4) * 16)
		node3.velocity = dir.rotated(-PI/4)
		
		node1.add_to_group(get_name())
		node2.add_to_group(get_name())
		node3.add_to_group(get_name())
		
		node1.owner_name = get_name()
		node2.owner_name = get_name()
		node3.owner_name = get_name()
		
		get_tree().get_root().get_node("Node/level/players").add_child(node1)
		get_tree().get_root().get_node("Node/level/players").add_child(node2)
		get_tree().get_root().get_node("Node/level/players").add_child(node3)
	