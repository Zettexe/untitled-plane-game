extends Node

#-----------------SCENE--SCRIPT------------------#
#    Close your game faster by clicking 'Esc'    #
#   Change mouse mode by clicking 'Shift + F1'   #
#------------------------------------------------#

export var is_debug_enabled: = true
var debug: = false

var debug_quit = "ui_cancel"
var debug_mouse_release = "mouse_input"
var debug_canvas_layer

var level_select
var biplane
var camera

func _ready() -> void:
	if OS.is_debug_build(): debug = is_debug_enabled
	if debug: debug_init()
	
	game_init()

# Production code goes here
func game_init():
	pass

# Only runs when in the editor and debug set to true
# DO NOT put production code here
func debug_init():
	"""
	Semi-automated key detection for debug keys
	"""
	print("** Debug mode enabled **")
	
	var keys = ""
	var first = true
	for action in InputMap.get_action_list(debug_quit):
		if action is InputEventKey:
			if not first: keys += ", "
			else: first = false
			keys += "'%s'" % OS.get_scancode_string(action.get_scancode_with_modifiers()).replace("+", " + ")
	print("** %s to close **" % keys)
	
	keys = ""
	first = true
	for action in InputMap.get_action_list(debug_mouse_release):
		if action is InputEventKey:
			if not first: keys += ", "
			else: first = false
			keys += "'%s'" % OS.get_scancode_string(action.get_scancode_with_modifiers()).replace("+", " + ")
	print("** %s to release mouse **" % keys)
	
	level_select = preload("res://Debug/Level Select/LevelSelect.tscn").instance()
	var buttons_container = level_select.get_node("GridContainer")
	
	var levels = {}
	var dir = Directory.new()
	dir.open("res://Levels")
	dir.list_dir_begin()
	
	var i = 0
	while true:
		var level_name = dir.get_next()
		if level_name == "": break
		if level_name.begins_with("."): continue
		if i >= buttons_container.get_child_count(): 
			push_warning("Unable to display all levels: Too many levels")
			break
		
		print(level_name)
		levels[level_name] = load("res://Levels/%s/L_%s.tscn" % [level_name, level_name]).instance()
		i += 1
	
	dir.list_dir_end()
	
	i = 0
	for button in buttons_container.get_children():
		button = button as Button
		if i >= levels.size():
			button.disabled = true
			continue
		print(i)
		button.text = levels.keys()[i]
		button.connect("button_up", self, "level_init", [levels.values()[i]])
		i += 1
		pass
	
	add_child(level_select)

# Initialized a level by inserting biplane and generating collision data
func level_init(level):
	# Load plane and camera
	biplane = preload("res://Plane/Biplane.tscn").instance()
	camera = preload("res://Plane/Camera.tscn").instance()
	
	# If plane spawn point is defined spawn it there
	# Otherwise leave it to default (Vector3.ZERO)
	var plane_spawn = level.get_node("plane_spawn")
	if plane_spawn:
		biplane.transform = plane_spawn.transform
	
	camera.position_node = biplane.get_node("Camera_Pivot/SpringArm/Position")
	
	add_child(biplane)
	add_child(camera)
	
	# Generate level collision to aid level creation
	var old_objects_node = level.get_node("Objects")
	
	if old_objects_node:
		var objects_node = StaticBody.new()
		objects_node.name = "Objects"
		
		for _i in range(0, old_objects_node.get_child_count()):
			var child: Spatial = old_objects_node.get_child(0)
			var collision_shape
			
			if child is CSGBox:
				collision_shape = BoxShape.new()
				collision_shape.extents = Vector3(child.width, child.height, child.depth) / 2
			elif child is CSGCylinder:
				collision_shape = CylinderShape.new()
				collision_shape.radius = child.radius
				collision_shape.height = child.height
			elif child is CSGSphere:
				collision_shape = SphereShape.new()
				collision_shape.radius = child.radius
			else: return
			
			var collision = CollisionShape.new()
			collision.shape = collision_shape
			collision.transform = child.transform
			collision.name = child.name
			
			child.transform = objects_node.transform
			
			child.name = "MeshInstance"
			
			old_objects_node.remove_child(child)
			collision.add_child(child)
			objects_node.add_child(collision)
		
		level.remove_child(old_objects_node)
		level.add_child(objects_node)
	
	# TODO: Add level changing system
	add_child(level)
	remove_child(level_select)

func _input(event: InputEvent) -> void:
	if not debug: return
	
	if event.is_action_pressed(debug_quit):
		get_tree().quit() # Quits the game TODO: Pause Menu
	
	if event.is_action_pressed(debug_mouse_release):
		match Input.get_mouse_mode():
			Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

