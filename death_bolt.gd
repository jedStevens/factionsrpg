extends KinematicBody2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var velocity = Vector2(0,0)
var speed = 450

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process(true)
	

func _process(delta):
	get_node("Sprite").set_rot(velocity.angle() - PI/2)
	move(velocity * speed  * delta)