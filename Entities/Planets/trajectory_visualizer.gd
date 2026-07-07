extends Node3D
class_name TrajectoryVisualizer

@export var planet: Node3D
@export var missile_speed: float = 1.0
@export var missile_acceleration: float = 0.1
@export var acceleration_duration_ms: float = 5000.0 # 5 seconds in milliseconds

var player_id

# How many simulated physics frames between each visible mesh.
# Increase this number to see further into the future!
@export var steps_per_mesh: int = 15 

var trajectory_meshes: Array[Node3D] = []

var visualizing = true

var visualization_size = 10

var gravitable = true

var launched = false

func _ready():
	# Gather all the child meshes to use as trajectory points
	for child in get_children():
		if child is Node3D:
			trajectory_meshes.append(child)
	
	player_id = get_parent().player_id

func _physics_process(delta):
	if visualizing:
		show()
	else:
		hide()
		return
	if planet == null or trajectory_meshes.is_empty():
		return
		
	# 1. Get joystick input to find the launch direction
	var y = -Input.get_joy_axis(player_id, JOY_AXIS_LEFT_Y)
	var x = Input.get_joy_axis(player_id, JOY_AXIS_LEFT_X)
	var input_vector = Vector3(x, y, 0)
	
	var direction = Vector3.UP
	
	var vis_size = visualization_size
	
	if not gravitable:
		vis_size = 5
	
	for m in trajectory_meshes: m.visible = false
	
	# Only show the trajectory if the player is actually aiming
	if input_vector.length() > 0.3 and not launched:
		var index = 0
		direction = input_vector.normalized()
		for i in vis_size:
			trajectory_meshes[index].visible = true
			index += 1
	elif launched and input_vector.length() > 0.3:
		for m in trajectory_meshes: m.visible = false
		return
	else:
		launched = false
		for m in trajectory_meshes: m.visible = false
		return
		
	# 2. Setup the initial state exactly like spawn_missile() does
	var sim_pos = planet.global_position + (direction * 4.0)
	var sim_vel = planet.linear_velocity + (direction * missile_speed)
	
	# At launch, the missile's forward direction (basis.y) equals the launch direction
	var sim_basis_y = direction 
	
	var gravitators = get_tree().get_nodes_in_group("gravitator")
	
	# 3. Simulate future physics frames
	var mesh_index = 0
	var total_simulation_steps = trajectory_meshes.size() * steps_per_mesh
	
	for i in range(total_simulation_steps):
		
		# Calculate how many milliseconds into the future this simulation step is
		var simulated_time_ms = (i + 1) * delta * 1000.0
		
		# A. Apply Gravity (Matches your apply_gravity function)
		if gravitable:
			for gravitator in gravitators:
				var offset = gravitator.global_position - sim_pos
				var distance = offset.length()
				
				if distance >= 0.1:
					var dir = offset / distance
					var force = gravitator.gravity_strength / pow(distance, 2)
					sim_vel += dir * force * delta
					
		# B. Update Position
		sim_pos += sim_vel * delta
		
		# C. Apply Acceleration (Only if under the time limit)
		if simulated_time_ms <= acceleration_duration_ms:
			sim_vel += sim_basis_y * missile_acceleration * 0.1
		
		# D. Update Rotation/Basis
		# Because your missile rotates to face its velocity (atan2), its local Y axis 
		# (global_basis.y) will always point exactly in the direction of the velocity vector.
		if sim_vel.length() > 0.001:
			sim_basis_y = sim_vel.normalized()
			
		# E. Place a mesh at the specified time interval
		if (i + 1) % steps_per_mesh == 0:
			if mesh_index < trajectory_meshes.size():
				var mesh = trajectory_meshes[mesh_index]
				mesh.global_position = sim_pos
				# Match the rotation of the missile so the meshes point along the curve
				mesh.rotation_degrees.z = rad_to_deg(atan2(sim_vel.y, sim_vel.x)) - 90
				mesh_index += 1

func update_planet(exp_planet = null):
	if exp_planet:
		planet = exp_planet
	update_visualization()

func update_visualization():
	visualization_size = planet.get_visualization_size()


func check_launchable(exp):
	if exp == "gravitator":
		gravitable = false
		missile_speed = 3.0
	else:
		gravitable = true
		missile_speed = 1.0
	
	launched = false
