
extends KinematicBody2D

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

var velocity = Vector2(0,0)
var facing = Vector2(1,0)

var is_local = false

var mouse_glitch = false

func set_is_local(b):
	if b:
		get_node("target_flag").set_opacity(1)
	else:
		get_node("target_flag").set_opacity(0)

func set_paramters(info):
	get_node("username").set_text(info.username)
	var tex = load(character_path + info.character + ".png")
	get_node("Sprite").set_texture(tex)

func _ready():
	set_fixed_process(true)
	set_process_input(true)
	
	target_point = get_global_pos()
	
	eps = 3
	
func walk_to(p):
	set_target(p)
	
	print("animation playing")
	play_ui_animation("walk_to", p )
	print("walk kick-off complete")

func set_target(p):
	mouse_glitch = true
	target_point = p
	
	var world = get_node("../../world")
	var pos = get_global_pos()
	
	print("Getting points: ", typeof(pos), "=",typeof(p))
	var new_points = world.get_simple_path(pos, target_point, true)
	print("Got points")
	
	points = new_points
	mouse_glitch = false

master func cast(spell_num, pos):
	print("Casting Spell: ", spell_num, pos)
	rpc("add_spell")

slave func add_spell():
	print("spell added")

func play_ui_animation(anim, p):
	var animation = load("res://ui/"+anim+".tscn").instance()
	print("animation loaded")
	animation.set_global_pos(p)
	print("animation set")
	get_node("../").add_child(animation)

func _fixed_process(delta):
	# refresh the points in the path
	# if the path has more than one point
	if points.size() > 0:
		get_node("target_flag").set_global_pos((points[points.size()-1]))
		
		var distance = points[0] - get_global_pos()
		direction = distance.normalized() # direction of movement
		if distance.length() > eps:
			velocity =  direction*speed
			if direction.x < -0.2:
				get_node("Sprite").set_flip_h(true)
			elif direction.x > 0.2:
				get_node("Sprite").set_flip_h(false)
		else:
			set_pos(points[0])# close enough - stop moving
			points.remove(0)
			
			
	else:
		velocity = Vector2(0,0)
	
	update() # we update the node so it has to draw it self again
			
	var motion = move(velocity * delta)
	
	if (is_colliding()):
		var n = get_collision_normal()
		motion = n.reflect(motion)
		move(motion)
	
	

func _draw():
	# if there are points to draw
	if (Globals.get('debug') == true):
		if points.size() > 1:
			var i = 0
			for i in range(points.size()-1):
				draw_line((points[i] - get_global_pos()) * get_scale(), (points[i+1] - get_global_pos()) * get_scale(), Color(1.0,1.0,1.0,1.0), 2.0, true)
				draw_circle((points[i] - get_global_pos()) * get_scale(), 4, Color(0, 0, 0)) # we draw a circle (convert to global position first)
		
			
			draw_circle((points[points.size()-1] - get_global_pos()) * get_scale(), 8, Color(0.2, 0.7, 0.2)) # we draw a circle (convert to global position first)
		
		#draw_circle(Vector2(0,0), get_node("CollisionShape2D").get_shape().get_radius() * 2, Color(0.2, 0.2, 0.2, 0.2)) # we draw a circle (convert to global position first)
		
		