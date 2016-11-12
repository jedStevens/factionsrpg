extends KinematicBody2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var velocity = Vector2(0,0)
var speed = 250

var target = null

var owner_name = ""

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process(true)


func _process(delta):
	if target == null:
		for p in get_node("seek_area").get_overlapping_bodies():
			if p.is_in_group("player") and not p.is_in_group(owner_name):
				target = p
				
				return
	
	if target != null:
		velocity = (target.get_pos() - get_pos()).normalized()
	
	move(velocity * speed  * delta)