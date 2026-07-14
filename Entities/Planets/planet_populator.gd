# Planet Populator
extends Node3D

# Update your export variable to include a setter:
@export var planet_radius: float = 50.0:
	set(value):
		planet_radius = value
		if is_node_ready():
			_generate_hemisphere_grid()
			set_max_buildings()

var max_buildings = 40

@export var min_building_distance: float = 5.0
@export var building_scale: Vector3 = Vector3(0.5, 0.1, 0.5)
@export var surface_offset: float = 0.05 

# Set where the city starts growing from. Vector3(0,0,1) is the exact middle of the positive Z hemisphere.
@export var city_center_direction: Vector3 = Vector3(0, 0, 1) 

@export_group("Functional Buildings (2x2)")
## Dictionary mapping building names to their PackedScenes e.g., {"factory": preload("..."), "space_port": preload("...")}
@export var functional_building_scenes: Dictionary = {
	"factory" : preload("res://Entities/Buildings/Functional/factory_visual.tscn"),
	"missile_silo" : preload("res://Entities/Buildings/Functional/missile_silo_visual.tscn"),
	"space_port" : preload("res://Entities/Buildings/Functional/space_port_visual.tscn"),
	"space_radar" : preload("res://Entities/Buildings/Functional/space_radar_visual.tscn"),
	"bunker" : preload("res://Entities/Buildings/Functional/bunker_visual.tscn")
}
@export var functional_building_scale: Vector3 = Vector3(1.0, 0.2, 1.0) 

var buildings: Array[PackedScene] = [
	#preload("res://Entities/Buildings/building_2.tscn"),
	#preload("res://Entities/Buildings/building_3.tscn"),
	#preload("res://Entities/Buildings/building_4.tscn"),
	#preload("res://Entities/Buildings/building_6.tscn"),
	#preload("res://Entities/Buildings/building_7.tscn"),
	#preload("res://Entities/Buildings/building_10.tscn"),
	#preload("res://Entities/Buildings/building_12.tscn"),
	preload("res://Entities/Buildings/visual_building.tscn")
]

# Master Grid tracking
var all_grid_spots: Array[Vector3] = []
var spot_owners: Dictionary = {} # Maps Vector3 spot -> Node3D (or null if empty)

# Easy access categorical arrays
var spawned_1x1_buildings: Array[Node3D] = []
var spawned_2x2_buildings: Array[Dictionary] = [] # Stores {"type": String, "node": Node3D, "spots": Array[Vector3]}

func _ready() -> void:
	randomize()
	#_generate_hemisphere_grid()
	var x = randf_range(-0.5, -0.2) if randf() < 0.5 else randf_range(0.2, 0.5)
	city_center_direction = Vector3(x, randf_range(0.2, 0.5), 1)

func set_max_buildings():
	max_buildings *= planet_radius


## Calculates a strictly positive-Z grid and registers it to our Master Grid System
func _generate_hemisphere_grid() -> void:
	all_grid_spots.clear()
	spot_owners.clear()
	
	var num_rows = floor((PI * planet_radius) / min_building_distance)
	
	for row in range(num_rows + 1):
		var lat = lerp(-PI/2.0, PI/2.0, float(row) / float(num_rows))
		var slice_radius = planet_radius * cos(lat)
		var slice_half_circumference = PI * slice_radius
		
		var num_cols = floor(slice_half_circumference / min_building_distance)
		if num_cols < 1:
			num_cols = 1 
			
		for col in range(num_cols + 1):
			var lon = -PI/2.0
			if num_cols > 0:
				lon = lerp(-PI/2.0, PI/2.0, float(col) / float(num_cols))
			
			var normal = Vector3(
				cos(lat) * sin(lon), 
				sin(lat),            
				cos(lat) * cos(lon)  
			).normalized()
			
			var pos = normal * planet_radius
			
			var is_duplicate := false
			for existing_pos in all_grid_spots:
				if existing_pos.distance_to(pos) < (min_building_distance * 0.9):
					is_duplicate = true
					break
					
			if not is_duplicate:
				all_grid_spots.append(pos)
				spot_owners[pos] = null # Start completely unoccupied

## Helper to fetch all unowned spots, sorted closest to the city center at the END of the array
func _get_available_spots_sorted() -> Array[Vector3]:
	var free_spots: Array[Vector3] = []
	for spot in all_grid_spots:
		if spot_owners[spot] == null:
			free_spots.append(spot)
			
	var center_point = city_center_direction.normalized() * planet_radius
	free_spots.sort_custom(func(a, b):
		return a.distance_to(center_point) > b.distance_to(center_point)
	)
	return free_spots

# ==========================================
# PUBLIC API COMMANDS
# ==========================================

## Syncs the 2x2 layout to completely match an array state change
func update_buildings(new_buildings: Array) -> void:
	var current_types: Array[String] = []
	for b in spawned_2x2_buildings:
		current_types.append(b["type"])

	var to_add: Array[String] = []
	var remaining_current = current_types.duplicate()

	for b_item in new_buildings:
		var b_str = str(b_item)
		var idx = remaining_current.find(b_str)
		if idx != -1:
			remaining_current.remove_at(idx)
		else:
			to_add.append(b_str)

	for b_str in remaining_current:
		delete_building(b_str)

	for b_str in to_add:
		add_building(b_str)

## Explicit command to add a single functional building
func add_building(building_name: String) -> void:
	_build_functional_structure(building_name)

## Explicit command to remove a single functional building
func delete_building(building_name: String) -> void:
	_demolish_functional_structure(building_name)

# ==========================================
# 1x1 POPULATION LOGIC
# ==========================================

func check_population(target_population: int) -> void:
	target_population = clamp(target_population, 0, max_buildings)
	var current_population = spawned_1x1_buildings.size()
	
	if current_population < target_population:
		var amount_to_add = target_population - current_population
		for i in range(amount_to_add):
			_build_new_structure()
			
	elif current_population > target_population:
		var amount_to_remove = current_population - target_population
		for i in range(amount_to_remove):
			_demolish_structure()

func _build_new_structure() -> void:
	var free_spots = _get_available_spots_sorted()
	if free_spots.is_empty():
		return
		
	var spawn_pos = free_spots.pop_back()
	var normal = spawn_pos.normalized()
	
	var scene_to_spawn: PackedScene = buildings.pick_random()
	var new_building: Node3D = scene_to_spawn.instantiate()
	
	add_child(new_building)
	
	# FIX: Explicitly use the live planet_radius instead of the cached spawn_pos magnitude
	new_building.position = (normal * planet_radius) + (normal * surface_offset)
	
	var up_dir = normal
	var guide_dir = Vector3.UP 
	if abs(up_dir.dot(Vector3.UP)) > 0.999:
		guide_dir = Vector3.FORWARD 
		
	var right_dir = guide_dir.cross(up_dir).normalized()
	var back_dir = right_dir.cross(up_dir).normalized()
	
	new_building.basis = Basis(right_dir, up_dir, back_dir)
	new_building.scale = building_scale
	
	# Register ownership
	spot_owners[spawn_pos] = new_building
	spawned_1x1_buildings.append(new_building)

func _demolish_structure() -> void:
	if spawned_1x1_buildings.is_empty():
		return
		
	var building_to_remove = spawned_1x1_buildings.pop_back()
	if is_instance_valid(building_to_remove):
		# Clear it out of our grid registry
		for spot in all_grid_spots:
			if spot_owners[spot] == building_to_remove:
				spot_owners[spot] = null
				break
				
		if building_to_remove.has_method("delete"):
			building_to_remove.delete()
		else:
			building_to_remove.queue_free()

# ==========================================
# INTERNAL 2x2 FUNCTIONAL LOGIC
# ==========================================

func _build_functional_structure(b_type: String) -> void:
	if not functional_building_scenes.has(b_type):
		push_warning("Planet Populator: " + b_type + " missing from functional_building_scenes dict!")
		return

	var scene: PackedScene = functional_building_scenes[b_type]
	var free_spots = _get_available_spots_sorted()
	if free_spots.is_empty():
		push_warning("Planet Populator: No free anchor spots found!")
		return

	var anchor_spot: Vector3
	var neighbors: Array[Vector3] = []
	var found_valid_cluster := false

	# Look for an anchor point close to the city center that forms a perfect 2x2 quad
	for i in range(free_spots.size() - 1, -1, -1):
		var candidate_anchor = free_spots[i]
		
		# Establish local orientation axes for this candidate anchor
		var normal = candidate_anchor.normalized()
		var up_dir = normal
		var guide_dir = Vector3.UP
		if abs(up_dir.dot(Vector3.UP)) > 0.999:
			guide_dir = Vector3.FORWARD
		var right_dir = guide_dir.cross(up_dir).normalized()
		var back_dir = right_dir.cross(up_dir).normalized()
		
		var best_right = null
		var best_back = null
		var best_diag = null
		
		var min_r_dist = INF
		var min_b_dist = INF
		var max_dist = min_building_distance * 1.9 # Upper boundary for grid search

		for spot in all_grid_spots:
			if spot == candidate_anchor: continue
			if _is_spot_locked_by_2x2(spot): continue

			var dist = candidate_anchor.distance_to(spot)
			if dist > max_dist: continue

			# Project the neighbor into the anchor's local 2D plane
			var v = spot - candidate_anchor
			var x = v.dot(right_dir)
			var y = v.dot(back_dir)

			# 1. Look for the closest neighbor directly in the local +Right sector
			if x > 0.5 * min_building_distance and abs(y) < x * 0.7:
				if dist < min_r_dist:
					min_r_dist = dist
					best_right = spot

			# 2. Look for the closest neighbor directly in the local +Back (Down) sector
			if y > 0.5 * min_building_distance and abs(x) < y * 0.7:
				if dist < min_b_dist:
					min_b_dist = dist
					best_back = spot

		# 3. If both structural edges exist, find the matching diagonal corner spot
		if best_right != null and best_back != null:
			var ideal_diag = best_right + best_back - candidate_anchor
			var min_d_dist = INF
			
			for spot in all_grid_spots:
				if spot == candidate_anchor or spot == best_right or spot == best_back: continue
				if _is_spot_locked_by_2x2(spot): continue

				var d_to_ideal = spot.distance_to(ideal_diag)
				if d_to_ideal < min_building_distance * 0.7:
					if d_to_ideal < min_d_dist:
						min_d_dist = d_to_ideal
						best_diag = spot

		# Verify if we successfully formed a structural 2x2 grid quad
		if best_right != null and best_back != null and best_diag != null:
			anchor_spot = candidate_anchor
			neighbors = [best_right, best_back, best_diag]
			found_valid_cluster = true
			break

	if not found_valid_cluster:
		push_warning("Planet Populator: Could not find 4 native grid positions aligned into a 2x2 quad!")
		return

	var master_cluster = [anchor_spot] + neighbors

	# Bulldoze logic: Clear out any 1x1 buildings currently using these slots
	for spot in master_cluster:
		var current_owner = spot_owners[spot]
		if is_instance_valid(current_owner) and current_owner in spawned_1x1_buildings:
			spawned_1x1_buildings.erase(current_owner)
			if current_owner.has_method("delete"): current_owner.delete()
			else: current_owner.queue_free()
			spot_owners[spot] = null

	# Instantiate the 2x2 building
	var new_b: Node3D = scene.instantiate()
	add_child(new_b)
	
	# Calculate the true center of the 4 grid positions and snap it to the planet's surface radius
	var cluster_center = (anchor_spot + neighbors[0] + neighbors[1] + neighbors[2]) / 4.0
	var center_normal = cluster_center.normalized()
	new_b.position = (center_normal * planet_radius) + (center_normal * surface_offset)

	# Orient the building using the new central normal to keep its rotation neat
	var up_dir = center_normal
	var guide_dir = Vector3.UP
	if abs(up_dir.dot(Vector3.UP)) > 0.999:
		guide_dir = Vector3.FORWARD
		
	var right_dir = guide_dir.cross(up_dir).normalized()
	var back_dir = right_dir.cross(up_dir).normalized()

	new_b.basis = Basis(right_dir, up_dir, back_dir)
	new_b.scale = functional_building_scale

	# Lock all 4 spots in the master grid system to this 2x2 building
	for spot in master_cluster:
		spot_owners[spot] = new_b

	spawned_2x2_buildings.append({
		"type": b_type,
		"node": new_b,
		"spots": master_cluster
	})

func _demolish_functional_structure(b_type: String) -> void:
	for i in range(spawned_2x2_buildings.size()):
		var dict = spawned_2x2_buildings[i]
		
		if dict["type"] == b_type:
			var node = dict["node"]
			if is_instance_valid(node):
				if node.has_method("delete"): node.delete()
				else: node.queue_free()

			# Free all 4 spots back to the global pool completely
			for spot in dict["spots"]:
				spot_owners[spot] = null

			spawned_2x2_buildings.remove_at(i)
			return

func _is_spot_locked_by_2x2(spot: Vector3) -> bool:
	for b in spawned_2x2_buildings:
		if spot in b["spots"]:
			return true
	return false
