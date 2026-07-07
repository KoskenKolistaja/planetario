extends Area3D


var velocity : Vector3 = Vector3.ZERO
var speed = 1.0
var acceleration = 0.1

var player_id = null

@export var gravity_strength := 500.0


@export var lower_scene : PackedScene

var inactive = false

var accelerating = true


var origin_planet : Node3D

func _ready():
	set_color()
	
	
	%Particles1.emitting = true
	await get_tree().create_timer(3.0).timeout
	detach_lower()
	%Particles1.emitting = false
	await get_tree().create_timer(1.5).timeout
	%Particles2.emitting = true
	await get_tree().create_timer(5.5).timeout
	%Particles2.emitting = false



func detach_lower():
	%RocketLower.hide()
	var lower_instance = lower_scene.instantiate()
	var rocket_velocity = velocity + (-basis.y * 0.4) + Vector3(randf_range(-0.1,0.1),randf_range(-0.1,0.1),randf_range(-0.1,0.1))
	get_tree().get_first_node_in_group("world").add_child(lower_instance)
	lower_instance.velocity = rocket_velocity
	lower_instance.global_transform = self.global_transform
	lower_instance.origin_planet = origin_planet

func set_color():
	if player_id != null:
		var color = PlayerData.colors[player_id]
		var mat :StandardMaterial3D = %RocketUpper.get_active_material(0)
		var mat2 :StandardMaterial3D = %RocketUpper.get_active_material(1)
		var mat3 :StandardMaterial3D = %RocketLower.get_active_material(0)
		var mat4 :StandardMaterial3D = %RocketLower.get_active_material(1)
		mat.emission = color
		mat2.emission = color
		mat2.albedo_color = color
		mat3.emission = color
		mat4.emission = color
		mat4.albedo_color = color


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
	if body.has_method("inhabit") and player_id != null:
		body.inhabit(player_id)
	
	explode()

func explode():
	#var explosion_instance = explosion_scene.instantiate()
	#get_tree().get_first_node_in_group("world").add_child(explosion_instance)
	#explosion_instance.global_position = self.global_position
	inactive = true
	%Particles1.emitting = false
	%Particles2.emitting = false
	await get_tree().create_timer(0.5).timeout
	queue_free()


func push(exp_velocity):
	velocity += exp_velocity


func _on_timer_timeout():
	accelerating = false
