extends Node3D





func _ready():
	%Pivot.rotation_degrees.y = randi_range(0,360)
	

func _physics_process(delta):
	%Pivot.rotation_degrees.y += 0.5
