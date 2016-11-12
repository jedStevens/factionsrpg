extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var server = null # if hosting

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	Globals.set('debug', false)

