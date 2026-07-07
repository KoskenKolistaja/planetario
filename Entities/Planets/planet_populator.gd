# Planet Populator
extends Node3D

@export var planet_radius: float = 50.0
@export var min_building_distance: float = 5.0
@export var building_scale: Vector3 = Vector3(0.5, 0.1, 0.5)
@export var surface_offset: float = 0.05 

# Set where the city starts growing from. Vector3(0,0,1) is the exact middle of the positive Z hemisphere.
@export var city_center_direction: Vector3 = Vector3(0, 0, 1) 

var buildings: Array[PackedScene] = [preload("res://Entities/Buildings/visual_building.tscn")]

var spawned_buildings: Array[Node3D] = []
var available_grid_spots: Array[Vector3] = []

func _ready() -> void:
	randomize()
	_generate_hemisphere_grid()
	
	city_center_direction = Vector3(randf_range(-1,1),randf_range(-1,1),1)

## Calculates a strictly positive-Z grid based on the radius and min_distance
func _generate_hemisphere_grid() -> void:
	available_grid_spots.clear()
	
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
			for existing_pos in available_grid_spots:
				if existing_pos.distance_to(pos) < (min_building_distance * 0.9):
					is_duplicate = true
					break
					
			if not is_duplicate:
				available_grid_spots.append(pos)
				
	# REPLACE SHUFFLE WITH DISTANCE SORTING
	_sort_grid_for_expansion()

## Sorts the grid so the coordinates closest to the city center are at the end of the array
func _sort_grid_for_expansion() -> void:
	var center_point = city_center_direction.normalized() * planet_radius
	
	# Godot's sort_custom: Returning true means 'a' goes before 'b'.
	# We want the LARGEST distances at the start, and SMALLEST distances at the end.
	available_grid_spots.sort_custom(func(a: Vector3, b: Vector3):
		return a.distance_to(center_point) > b.distance_to(center_point)
	)

func check_population(target_population: int) -> void:
	target_population = clamp(target_population, 0, 120)
	var current_population = spawned_buildings.size()
	
	if current_population < target_population:
		var amount_to_add = target_population - current_population
		for i in range(amount_to_add):
			_build_new_structure()
			
	elif current_population > target_population:
		var amount_to_remove = current_population - target_population
		for i in range(amount_to_remove):
			_demolish_structure()

func _build_new_structure() -> void:
	if available_grid_spots.is_empty():
		push_warning("Planet Populator: Grid is completely full! Cannot place more buildings.")
		return
		
	var spawn_pos = available_grid_spots.pop_back()
	var normal = spawn_pos.normalized()
	
	var scene_to_spawn: PackedScene = buildings.pick_random()
	var new_building: Node3D = scene_to_spawn.instantiate()
	
	add_child(new_building)
	
	new_building.position = spawn_pos + (normal * surface_offset)
	
	var up_dir = normal
	var guide_dir = Vector3.UP 
	
	if abs(up_dir.dot(Vector3.UP)) > 0.999:
		guide_dir = Vector3.FORWARD 
		
	var right_dir = guide_dir.cross(up_dir).normalized()
	var back_dir = right_dir.cross(up_dir).normalized()
	
	new_building.basis = Basis(right_dir, up_dir, back_dir)
	new_building.scale = building_scale
	
	spawned_buildings.append(new_building)

func _demolish_structure() -> void:
	if spawned_buildings.is_empty():
		return
		
	var building_to_remove = spawned_buildings.pop_back()
	if is_instance_valid(building_to_remove):
		available_grid_spots.append(building_to_remove.position)
		
		# RESORT THE GRID instead of shuffling so empty spots near the center are prioritized
		_sort_grid_for_expansion()
		
		building_to_remove.delete()
