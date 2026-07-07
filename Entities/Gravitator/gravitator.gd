extends Area3D

var strength = 10.0

var max_strength = 3.0
var velocity : Vector3 = Vector3.ZERO
var speed = 3.0
var acceleration = 0.1

var player_id = null

@export var gravity_strength := 500.0

@export var explosion_scene : PackedScene

var inactive = false

var accelerating = false


func _ready():
	await get_tree().create_timer(6.0).timeout
	inactivate()
	%AnimationPlayer.play("Fade")
	await get_tree().create_timer(4.0).timeout
	queue_free()


func inactivate():
	inactive = true
	%GPUParticles3D.emitting = false

func _physics_process(delta):
	#var bodies = get_overlapping_bodies()
	global_position += velocity * delta
	velocity *= 0.995
	
	if inactive:
		return
	
	var areas = get_overlapping_areas()
	for a : Area3D in areas:
		if not a.has_method("push"):
			continue
		
		var push_velocity = Vector3.ZERO
		
		var offset = self.global_position - a.global_position
		var distance = offset.length()
		
		if distance < 0.1:
			continue
		
		var direction = offset.normalized()
		
		# Cubic falloff (very strong nearby, quickly weaker farther away)
		var force = self.strength / pow(distance, 2)
		
		force = clamp(force,0,max_strength)
		
		push_velocity += -direction * force * delta
		
		a.push(push_velocity)






func set_velocity(inherited_velocity):
	velocity = inherited_velocity + (global_basis.y * speed)


func push(exp_velocity):
	velocity += exp_velocity


func _on_body_entered(body):
	inactivate()
