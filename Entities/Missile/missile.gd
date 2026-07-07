extends Area3D


var velocity : Vector3 = Vector3.ZERO
var speed = 1.0
var acceleration = 0.1


@export var gravity_strength := 500.0

@export var explosion_scene : PackedScene

var inactive = false

var accelerating = true

func _ready():
	await get_tree().create_timer(1.0).timeout
	%GPUParticles3D.emitting = true
	await get_tree().create_timer(4.0).timeout
	%GPUParticles3D.emitting = false
	accelerating = false


func _physics_process(delta):
	var gravitators = get_tree().get_nodes_in_group("gravitator")
	apply_gravity(gravitators,delta)
	
	
	global_position += velocity * delta
	if accelerating:
		velocity += global_basis.y * acceleration * 0.1
	rotation_degrees.z = rad_to_deg(atan2(velocity.y,velocity.x)) - 90


func set_velocity(inherited_velocity):
	velocity = inherited_velocity + (global_basis.y * speed)

func apply_gravity(gravitators: Array, delta: float):
	for gravitator in gravitators:
		var offset = gravitator.global_position - global_position
		var distance = offset.length()

		if distance < 0.1:
			continue

		var direction = offset / distance

		# Cubic falloff (very strong nearby, quickly weaker farther away)
		var force = gravitator.gravity_strength / pow(distance, 2)

		velocity += direction * force * delta


func _on_body_entered(body):
	if inactive:
		return
	if body.has_method("explode"):
		body.explode()
		explode()


func explode():
	var explosion_instance = explosion_scene.instantiate()
	get_tree().get_first_node_in_group("world").add_child(explosion_instance)
	explosion_instance.global_position = self.global_position
	inactive = true
	%GPUParticles3D.emitting = false
	%GPUParticles3D2.emitting = false
	
	await get_tree().create_timer(0.5).timeout
	queue_free()


func push(exp_velocity):
	velocity += exp_velocity
