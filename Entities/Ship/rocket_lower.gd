extends Area3D



var velocity : Vector3 = Vector3.ZERO
var speed = 1.0
var acceleration = 0.1

var player_id = null

@export var gravity_strength := 500.0

var inactive = false

var accelerating = false

var origin_planet : Node3D


func _ready():
	await get_tree().create_timer(2.0).timeout
	fade()


func fade():
	var mat: StandardMaterial3D = %Mesh.get_active_material(0)
	var mat2: StandardMaterial3D = %Mesh.get_active_material(1)
	var tween = create_tween()
	tween.set_parallel(true)
	if mat:
		tween.tween_property(mat, "albedo_color:a", 0.0, 3.0)
	if mat2:
		tween.tween_property(mat2, "albedo_color:a", 0.0, 3.0)

func set_color():
	if player_id != null:
		var color = PlayerData.colors[player_id]
		var mesh :MeshInstance3D = %Mesh
		var mat :StandardMaterial3D = mesh.get_surface_override_material(1)
		mat.emission = color

func _physics_process(delta):
	var gravitators = get_tree().get_nodes_in_group("gravitator")
	apply_gravity(gravitators,delta)
	
	
	global_position += velocity * delta
	if accelerating:
		velocity += global_basis.y * acceleration * 0.1
	#rotation_degrees.z = rad_to_deg(atan2(velocity.y,velocity.x)) - 90
	
	#velocity = (origin_planet.global_position - self.global_position).normalized() * 0.02
	velocity = velocity.move_toward((origin_planet.global_position - self.global_position).normalized() * 10,0.01)

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







func push(exp_velocity):
	velocity += exp_velocity


func _on_body_entered(body):
	queue_free()
