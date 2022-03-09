extends KinematicBody

class_name Biplane

""" CAMERA VARIABLES """
export(float) var controller_sensitivity = 3
export(float) var mouse_sensitivity = 0.1
export(Vector2) var camera_clamp_angle = Vector2(-75, 75)
export(Vector2) var horizontal_camera_clamp_angle = Vector2(-50, 50)
""" CAMERA VARIABLES """


export(float) var acceleration_speed = 20
export(float) var rotation_strength = 0.8


# Gravity kicks in below this speed (interpolated)
var min_flight_speed = 10
# Turn speed in relation to how far rotated the plane is
var turn_speed = .5
# Climb/dive rate
var pitch_speed = 0.5
# How fast the plane rotates
var rotation_speed = 2
# Throttle change speed
var throttle_delta = 30
# Acceleration/deceleration
var acceleration = 6.0

# Current speed
var forward_speed = 0
# Throttle input speed
var target_speed = 0
# Lets us change behavior when grounded
var grounded = false

var velocity = Vector3.ZERO

var input_vector = Vector3.ZERO
var prev_input_vector = Vector3.ZERO

onready var _mesh_pivot = $Mesh_Pivot
onready var _camera_pivot = $Camera_Pivot
onready var _spring_arm = $Camera_Pivot/SpringArm
onready var _camera_position = $Camera_Pivot/SpringArm/Position as Position3D

func _ready():
	_camera_position.transform.origin.z = _spring_arm.spring_length
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#func _unhandled_input(event):
#	var mouse_mode_captured = Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
#
#	if event is InputEventMouseMotion and mouse_mode_captured:
#		_camera_pivot.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
#		_spring_arm.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))

func handle_camera():
	""" 
	Need to handle joystick controls in _physics_process
	since joystick input does not always update every frame 
	(May be better in _process but its fine for now)
	"""
#	var input_vector = Vector2( \
#		Input.get_action_strength("look_right") - Input.get_action_strength("look_left"), 
#		Input.get_action_strength("look_down") - Input.get_action_strength("look_up")  
#	)
#	if input_vector.length() > 0.05:
#		_camera_pivot.rotate_y(deg2rad(-input_vector.x * controller_sensitivity))
#		_spring_arm.rotate_x(deg2rad(-input_vector.y * controller_sensitivity))
	
	_camera_pivot.rotation.y = _mesh_pivot.rotation.y
	_spring_arm.rotation.x = _mesh_pivot.rotation.x
	
#	_spring_arm.rotation.x = clamp(_spring_arm.rotation.x, deg2rad(camera_clamp_angle.x), deg2rad(camera_clamp_angle.y))
#	_camera_pivot.rotation.y = clamp(_camera_pivot.rotation.y, deg2rad(horizontal_camera_clamp_angle.x), deg2rad(horizontal_camera_clamp_angle.y))

func handle_movement(delta):
	input_vector = Vector2( \
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left") , 
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)
	
	input_vector.x = lerp(prev_input_vector.x, input_vector.x, 3 * delta)
	
	prev_input_vector = input_vector
	
	var forward_input = 1 # Input.get_action_strength("accelerate")
	
	DebugDraw.draw_ray_3d(transform.origin, velocity, 1, Color.red)
	
	if input_vector.abs().x < 0.05:
		input_vector.x = 0
	
	if input_vector.abs().y < 0.05:
		input_vector.y = 0
	
	# Accelerate/decelerate
	forward_speed = lerp(forward_speed, forward_input * acceleration_speed, acceleration * delta)
	# Movement is always forward
	velocity = -_mesh_pivot.transform.basis.z * forward_speed
	velocity = move_and_slide(velocity, Vector3.UP)
	
	
	_mesh_pivot.transform.basis = _mesh_pivot.transform.basis.rotated(_mesh_pivot.transform.basis.x, input_vector.y * rotation_strength * delta)
	
	_mesh_pivot.rotation.z = lerp(_mesh_pivot.rotation.z, _mesh_pivot.rotation.z - input_vector.x, rotation_speed * abs(input_vector.x) * delta)
	_mesh_pivot.transform.basis = _mesh_pivot.transform.basis.rotated(Vector3.UP, Vector3.UP.dot(_mesh_pivot.transform.basis.x) * turn_speed * delta)
	
	
#	if action_strength:
#		add_central_force(-get_global_transform().basis.z.normalized() * (action_strength * acceleration_speed * delta))

func _physics_process(delta):
	handle_camera()
	
	handle_movement(delta)
