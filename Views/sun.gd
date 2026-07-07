extends StaticBody3D

var gravity_strength = 60.0

@export var size : float = 1.0




func _ready():
	var collision_shape : CollisionShape3D = $CollisionShape3D
	var sphere : SphereShape3D = collision_shape.shape
	sphere.radius = size * 3
	$MeshInstance3D.scale.z *= size
	$MeshInstance3D.scale.x *= size
	$MeshInstance3D.scale.y *= size
	gravity_strength *= size

func explode():
	pass
