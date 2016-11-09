
extends RigidBody2D

# travel speed in pixel/s
export var speed = 200

# at which distance to stop moving
# NOTE: setting this value too low might result in jerky movement near destination
var eps = 1.5

# points in the path
var points = []

var target_point = Vector2(0,0)

var direction = Vector2(0,0)

export var character = "mage"

var character_path = "res://characters/"

func set_paramters(info):
	get_node("username").set_text(info.username)
	var tex = load(character_path + info.character + ".png")
	get_node("Sprite").set_texture(tex)

func _ready():
	set_fixed_process(true)
	set_process_input(true)
	
	target_point = get_global_pos()
	
	eps = get_node("CollisionShape2D").get_shape().get_radius() 

master func walk_to(p):
	set_target(p)
	
	rpc("set_target", p)
	
	play_ui_animation("walk_to", p )

slave func set_target(p):
	target_point = p
	
	points = get_node("../../world").get_simple_path(get_global_pos(), target_point, false)

func play_ui_animation(anim, p):
	get_node("ui_animations/AnimationPlayer").play(anim)
	get_node("ui_animations/"+anim).set_global_pos(p)

func _fixed_process(delta):
	# refresh the points in the path
	# if the path has more than one point
	points = get_node("../../world").get_simple_path(get_global_pos(), target_point, false)
	if points.size() > 1:
		var distance = points[1] - get_global_pos()
		direction = distance.normalized() # direction of movement
		if distance.length() > eps or points.size() > 2:
			set_linear_velocity(direction*speed)
			if direction.x < -0.2:
				get_node("Sprite").set_flip_h(true)
			elif direction.x > 0.2:
				get_node("Sprite").set_flip_h(false)
		else:
			set_linear_velocity(Vector2(0, 0)) # close enough - stop moving
		update() # we update the node so it has to draw it self again
	
	

func _draw():
	# if there are points to draw
	if (Globals.get('debug') == true):

		if points.size() > 1:
			var i = 0
			for i in range(points.size()-1):
				draw_line((points[i] - get_global_pos()) * get_scale(), (points[i+1] - get_global_pos()) * get_scale(), Color(1.0,1.0,1.0,1.0), 2.0, true)
			
			draw_circle((points[points.size()-1] - get_global_pos()) * get_scale(), 8, Color(0.2, 0.7, 0.2)) # we draw a circle (convert to global position first)
		
		draw_circle(Vector2(0,0), get_node("CollisionShape2D").get_shape().get_radius() * 2, Color(0.2, 0.2, 0.2, 0.2)) # we draw a circle (convert to global position first)
		
		if get_linear_velocity().length() > 30:
			draw_line(Vector2(0,0), get_node("CollisionShape2D").get_shape().get_radius() * direction * 3 ,Color(0.2, 0.7, 0.2), 6) # we draw a circle (convert to global position first)
		
		