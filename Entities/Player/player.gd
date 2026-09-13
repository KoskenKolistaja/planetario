extends Node3D

@export var player_id: int = 0
@export var planet: Node3D

@export var hud : Control

var launchable = "ship"
var buildable = "space_port"

var build_index = 0
var launch_index = 0

var buildables = ["space_port","factory","missile_silo","space_radar","bunker"]
var launchables = ["ship","missile","gravitator","starship","command_ship"]

var launching = false

signal build_index_changed
signal launch_index_changed

# We need this to ensure the joystick acts like a "button press" (a flick).
# Otherwise, holding the stick will swap planets 60 times a second!
var trigger_was_reset: bool = true
var launch_was_reset: bool = true

func _ready():
	await get_tree().create_timer(0.01).timeout
	if not planet:
		print("No planet...")
		var all_planets = get_tree().get_nodes_in_group("planet")
		for p in all_planets:
			# Safely check if the property exists and matches our ID
			if "controller_id" in p and p.controller_id == player_id:
				planet = p
				break # We found our first own planet, stop searching
	else:
		print("Planet. Contoller: " +str(player_id))
		activate_planet(planet)
		planet.focus(self)
		planet.technology += 300
	
	if hud:
		build_index_changed.connect(hud.update_build_index)
		launch_index_changed.connect(hud.update_launch_index)

func _physics_process(delta):
	# 1. Bumper/Button cycling
	#if Input.is_action_just_pressed("p%s_next" % player_id):
		#next_planet()
	#if Input.is_action_just_pressed("p%s_previous" % player_id):
		#previous_planet()
		
	# 2. Joystick directional snapping
	
	if Input.get_joy_axis(player_id,JOY_AXIS_TRIGGER_LEFT) > 0.3:
		handle_directional_selection()
	else:
		trigger_was_reset = true
	
	if Input.is_action_just_pressed("p%s_accept" % player_id):
		if launching:
			launch()
		else:
			planet.add_building(buildable)
	
	if Input.is_action_just_pressed("p%s_delete" % player_id):
		if not launching:
			planet.delete_building(buildable)
	
	
	if Input.is_action_just_pressed("p%s_ui_up" % player_id):
		if launching:
			launching = false
			build_index_changed.emit(build_index)
		else:
			launching = true
			launch_index_changed.emit(launch_index)
	if Input.is_action_just_pressed("p%s_ui_down" % player_id):
		if launching:
			launching = false
			build_index_changed.emit(build_index)
		else:
			launching = true
			launch_index_changed.emit(launch_index)
	
	if Input.is_action_just_pressed("p%s_ui_left" % player_id):
		if launching:
			launch_index -= 1
			if launch_index < 0:
				launch_index = launchables.size() - 1
			launch_index_changed.emit(launch_index)
			launchable = launchables[launch_index]
			check_launchable()
		else:
			build_index -= 1
			if build_index < 0:
				build_index = buildables.size() - 1
			build_index_changed.emit(build_index)
			buildable = buildables[build_index]
			check_launchable()
	if Input.is_action_just_pressed("p%s_ui_right" % player_id):
		if launching:
			launch_index += 1
			if launch_index > launchables.size() - 1:
				launch_index = 0
			launch_index_changed.emit(launch_index)
			launchable = launchables[launch_index]
			check_launchable()
		else:
			build_index += 1
			if build_index > buildables.size() - 1:
				build_index = 0
			build_index_changed.emit(build_index)
			buildable = buildables[build_index]
			check_launchable()
	
	if Input.get_joy_axis(player_id,JOY_AXIS_TRIGGER_RIGHT) > 0.3:
		if launch_was_reset:
			launch()
			launch_was_reset = false
	else:
		launch_was_reset = true
	
	handle_steering()


func launch():
	var y = -Input.get_joy_axis(player_id,JOY_AXIS_RIGHT_Y)
	var x = Input.get_joy_axis(player_id,JOY_AXIS_RIGHT_X)
	var vector : Vector3 = Vector3(x,y,0)
	if vector.length() > 0.3:
		if planet:
			planet.launch(launchable,vector,player_id)

func handle_steering():
	var x = Input.get_joy_axis(player_id,JOY_AXIS_LEFT_X)
	var y = -Input.get_joy_axis(player_id,JOY_AXIS_LEFT_Y)
	var vector = Vector3(x,y,0)
	
	if vector.length() > 0.3:
		if planet.has_method("steer"):
			planet.steer(vector)

func check_launchable():
	%TrajectoryVisualizer.check_launchable(launchable)

func force_change_planet(caller_planet):
	if planet == caller_planet:
		next_planet()



# --- HELPER FUNCTION ---
func get_own_planets() -> Array:
	var all_planets = get_tree().get_nodes_in_group("planet")
	var own = []
	for p in all_planets:
		if "controller_id" in p and p.controller_id == player_id:
			own.append(p)
	return own



func change_to_closest_planet(exp_position):
	var own_planets: Array = get_own_planets()
	
	if own_planets.is_empty():
		return
	
	var closest = own_planets[0]
	var closest_distance = closest.global_position.distance_squared_to(exp_position)
	
	for p in own_planets:
		var current_distance = p.global_position.distance_squared_to(exp_position)
		if current_distance < closest_distance:
			closest = p
			closest_distance = current_distance
	
	activate_planet(closest)


# --- BUTTON CYCLING ---
func next_planet():
	var own_planets = get_own_planets()
	if own_planets.size() <= 1 or not planet:
		return
		
	var current_idx = own_planets.find(planet)
	# Modulo (%) wraps the index back to 0 if it goes over the array size
	var next_idx = (current_idx + 1) % own_planets.size()
	var current_planet = own_planets[next_idx]
	activate_planet(current_planet)

func previous_planet():
	var own_planets = get_own_planets()
	if own_planets.size() <= 1 or not planet:
		return
		
	var current_idx = own_planets.find(planet)
	# We add the size() before the modulo to prevent negative index errors
	var prev_idx = (current_idx - 1 + own_planets.size()) % own_planets.size()
	var current_planet = own_planets[prev_idx]
	activate_planet(current_planet)

# --- DIRECTIONAL SEARCH ---
func handle_directional_selection():
	if not planet:
		return
		
	# Mirroring the XY logic from your missile script
	var x = Input.get_joy_axis(player_id, JOY_AXIS_LEFT_X)
	var y = -Input.get_joy_axis(player_id, JOY_AXIS_LEFT_Y)
	var input_dir = Vector3(x, y, 0)
	
	# Deadzone check & Flick reset

	
	if not trigger_was_reset:
		return # Stick is actively being held; don't calculate a new swap yet
		
	input_dir = input_dir.normalized()
	
	var best_planet = null
	var best_score = -1.0
	var own_planets = get_own_planets()
	
	for p in own_planets:
		if p == planet:
			continue # Don't search the planet we are currently on
			
		var offset = p.global_position - planet.global_position
		var distance = offset.length()
		
		if distance < 0.001:
			continue
			
		var target_dir = offset.normalized()
		var dot_product = input_dir.dot(target_dir)
		
		# A dot product > 0.5 means the planet is within a 90-degree cone 
		# facing the exact direction the player pushed the stick.
		if dot_product > 0.5:
			
			# The Magic Formula: Good angle alignment increases the score, 
			# but being far away decreases the score.
			var score = dot_product / distance
			
			if score > best_score:
				best_score = score
				best_planet = p
				
	# If we found a valid planet in that direction, swap to it
	if best_planet:
		activate_planet(best_planet)
		trigger_was_reset = false # Force the player to let go of the stick before flicking again


func activate_planet(exp_planet : Node3D):
	exp_planet.focus(self)
	
	print(planet)
	
	if planet:
		planet.lose_focus()
		
		# 1. DISCONNECT the old planet so it stops talking to the HUD
		if hud and planet.technology_changed.is_connected(hud.update_technology):
			planet.technology_changed.disconnect(hud.update_technology)
		if hud and planet.buildings_changed.is_connected(hud.update_buildings):
			planet.buildings_changed.disconnect(hud.update_buildings)
		if planet.trajectory_changed.is_connected(%TrajectoryVisualizer.update_planet):
			planet.trajectory_changed.disconnect(%TrajectoryVisualizer.update_planet)
	
	%TrajectoryVisualizer.update_planet(exp_planet)
	planet = exp_planet # Now we safely overwrite the active planet
	
	if hud:
		# 2. CONNECT the new planet (checking first to be safe)
		if not planet.technology_changed.is_connected(hud.update_technology):
			planet.technology_changed.connect(hud.update_technology)
		if not planet.buildings_changed.is_connected(hud.update_buildings):
			planet.buildings_changed.connect(hud.update_buildings)
		if not planet.trajectory_changed.is_connected(%TrajectoryVisualizer.update_planet):
			planet.trajectory_changed.connect(%TrajectoryVisualizer.update_planet)
		
		
		# 3. INSTANT REFRESH so the HUD updates immediately upon swapping
		hud.update_technology(planet.technology)
		hud.update_buildings(planet.buildings)
		hud.update_planet_name(planet.planet_name)

func update_visualization():
	%TrajectoryVisualizer.update_visualization()
