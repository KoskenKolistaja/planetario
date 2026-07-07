extends StaticBody3D

var gravity_strength = 60.0

@export var size : float = 1.0




func _ready():
	var collision_shape : CollisionShape3D = %CollisionShape3D
	var sphere : SphereShape3D = collision_shape.shape
	sphere.radius = size * 3
	%Mesh.scale.z *= size
	%Mesh.scale.x *= size
	%Mesh.scale.y *= size
	gravity_strength *= size

func explode():
	pass
