extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	for c : GPUParticles3D in %Emitters.get_children():
		c.emitting = true
	
	%AnimationPlayer.play("explode")
	
	await get_tree().create_timer(10).timeout
	queue_free()
