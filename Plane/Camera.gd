extends ClippedCamera

var position_node: Position3D

export(float) var camera_follow_speed = 10

func _ready():
	transform = position_node.global_transform

func _physics_process(delta):
	transform = transform.interpolate_with(position_node.global_transform, camera_follow_speed * delta)
