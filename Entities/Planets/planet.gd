extends AnimatableBody3D

@export var orbit_point: Node3D
@export var orbit_radius: float = 10.0
@export var ellipticalness: float = 1.0 # 1.0 = circle, 0.5 = squashed Y axis, 2.0 = stretched Y axis
@export var orbit_speed: float = 1.0 # Radians per second
@export var starting_angle: float = 0.0
@export var clockwise: bool = true

@export var planet_material : StandardMaterial3D

@export var missile_scene : PackedScene
@export var ship_scene : PackedScene
@export var gravitator_scene : PackedScene
@export var starship_scene : PackedScene

@export var controller_id : int = -1

@export var controller : Node3D

@export var planet_name : String = "<noname>"

var buildings = []

var type = 0

var technology = 0

var angle: float

var linear_velocity: Vector3
var previous_position: Vector3

var visualization_size = 10

signal technology_changed
signal buildings_changed
signal trajectory_changed

func _ready():
	angle = deg_to_rad(starting_angle)
	previous_position = global_position
	%Mesh.set_surface_override_material(0,planet_material)
	
	if controller:
		focus(controller)
	
	technology_changed.connect(_on_technology_changed)
	
	if controller_id > -1:
		var mat : StandardMaterial3D = %Highlight.get_active_material(0)
		mat.albedo_color = PlayerData.colors[controller_id]

func add_building(building_name):
	print("ADD CALLED")
	var is_radar = false
	match building_name:
		"space_port":
			if get_building_amount(buildings,"space_port") >= 1:
				return
			if buildings.has("space_port"):
				print("returned space_port")
				return
		"factory":
			if get_building_amount(buildings,"factory") >= 5:
				return
			pass
		"missile_silo":
			if get_building_amount(buildings,"missile_silo") >= 1:
				return
			if buildings.has("missile_silo"):
				print("returned missile_silo")
				return
		"space_radar":
			if get_building_amount(buildings,"space_radar") >= 5:
				return
			is_radar = true
		"bunker":
			if get_building_amount(buildings,"bunker") >= 1:
				return
			if buildings.has("bunker"):
				print("returned bunker")
				return
	
	#if buildings.size() >= 5:
		#return
	
	print("HERE")
	if technology >= BuildingData.prices[building_name]:
		print("HERE?")
		technology -= BuildingData.prices[building_name]
		buildings.append(building_name)
		if is_radar:
			trajectory_changed.emit()
		technology_changed.emit(technology)
		print(buildings)
		%PlanetPopulator.update_buildings(buildings.duplicate())
		buildings_changed.emit(buildings)

func get_building_amount(list,item_name) -> int:
	var amount = 0
	print(buildings)
	print(item_name)
	for item in list:
		if item == item_name:
			amount += 1
	
	print(amount)
	return amount


func delete_building(building_name):
	print("DELETING...")
	print(building_name)
	print(buildings)
	if buildings.has(building_name):
		buildings.erase(building_name)
		buildings_changed.emit(buildings)
		print("SUCCEEDED DELETING...")
		if controller:
			controller.update_visualization()
		%PlanetPopulator.update_buildings(buildings)
	

func focus(exp):
	%Highlight.show()
	controller = exp
	if controller_id > -1:
		var mat : StandardMaterial3D = %Highlight.get_active_material(0)
		mat.albedo_color = PlayerData.colors[controller_id]

func lose_focus():
	%Highlight.hide()
	controller = null

func _physics_process(delta):
	if orbit_point == null:
		return
	var direction := -1.0 if clockwise else 1.0
	angle += orbit_speed * direction * delta * 0.1
	
	# Apply ellipticalness to the Y axis calculation
	global_position = orbit_point.global_position + Vector3(
		cos(angle) * orbit_radius,
		sin(angle) * (orbit_radius * ellipticalness), 
		0.0
	)
	
	linear_velocity = (global_position - previous_position) / delta
	previous_position = global_position






func explode():
	
	
	if buildings.has("bunker"):
		technology *= 0.3
	else:
		technology = 0
		controller_id = -1
	
	buildings.clear()
	
	if is_instance_valid(controller):
		controller.force_change_planet(self)
	check_population(technology)

func launch(launched_item,vector,player_id):
	if launched_item == "missile":
		spawn_missile(vector)
	if launched_item == "ship":
		spawn_ship(vector,player_id)
	if launched_item == "gravitator":
		spawn_gravitator(vector,player_id)
	if launched_item == "starship":
		spawn_starship(vector,player_id)

func spawn_missile(vector):
	if not buildings.has("missile_silo"):
		return
	if technology >= MetaData.missile_price:
		technology -= MetaData.missile_price
		technology_changed.emit(technology)
	else:
		return
	
	
	var direction : Vector3 = Vector3.UP
	
	
	if vector.length() > 0.1:
		direction = vector.normalized()
	
	var missile_instance : Area3D = missile_scene.instantiate()
	var world = get_tree().get_first_node_in_group("world")
	
	missile_instance.rotation_degrees.z = rad_to_deg(atan2(vector.y,vector.x)) - 90
	
	world.add_child(missile_instance)
	missile_instance.global_position = self.global_position + (direction * 4)
	missile_instance.set_velocity(linear_velocity)
	
	

func spawn_ship(vector,player_id):
	if not buildings.has("space_port"):
		return
	if technology >= MetaData.ship_price:
		technology -= MetaData.ship_price
		technology_changed.emit(technology)
	else:
		return
	
	
	var direction : Vector3 = Vector3.UP
	
	if vector.length() > 0.1:
		direction = vector.normalized()
	
	var ship_instance : Area3D = ship_scene.instantiate()
	var world = get_tree().get_first_node_in_group("world")
	
	ship_instance.player_id = player_id
	ship_instance.rotation_degrees.z = rad_to_deg(atan2(vector.y, vector.x)) - 90
	ship_instance.origin_planet = self
	
	world.add_child(ship_instance)
	ship_instance.global_position = self.global_position + (direction * 4)
	ship_instance.set_velocity(linear_velocity)

func spawn_gravitator(vector: Vector3, player_id):
	if technology < MetaData.gravitator_price:
		return

	technology -= MetaData.gravitator_price
	technology_changed.emit(technology)

	var direction: Vector3 = Vector3.UP
	if vector.length() > 0.1:
		direction = vector.normalized()

	var gravitator_instance: Area3D = gravitator_scene.instantiate()
	var world = get_tree().get_first_node_in_group("world")

	gravitator_instance.rotation_degrees.z = rad_to_deg(atan2(vector.y, vector.x)) - 90
	gravitator_instance.player_id = player_id

	world.add_child(gravitator_instance)
	gravitator_instance.global_position = global_position + (direction * 4)
	gravitator_instance.set_velocity(linear_velocity)

func spawn_starship(vector: Vector3, player_id):
	if technology < MetaData.starship_price:
		return
	
	technology -= MetaData.starship_price
	technology_changed.emit(technology)

	var direction: Vector3 = Vector3.UP
	if vector.length() > 0.1:
		direction = vector.normalized()
	
	var starship_instance: Node3D = starship_scene.instantiate()
	var world = get_tree().get_first_node_in_group("world")
	
	starship_instance.controller_id = player_id
	
	world.add_child(starship_instance)
	starship_instance.global_position = global_position + (direction * 8)

func inhabit(player_id):
	if controller_id < 0:
		controller_id = player_id
		print("PLANET INHABITATED. NEW ID: " + str(controller_id))
	elif controller_id == player_id:
		technology += 50
		print("PLANET GOT A PACKAGE OF TECHNOLOGY. NEW AMOUNT: " + str(technology))
		technology_changed.emit(technology)
	else:
		return
	



func _on_timer_timeout():
	if controller_id < 0:
		return
	technology += 1
	for building in buildings:
		if building == "factory":
			technology += 1
	technology_changed.emit(technology)

func get_visualization_size():
	var current = 10
	
	for b in buildings:
		if b == "space_radar":
			current += 10
	
	return current

func _on_technology_changed(amount : int = 0):
	check_population(amount)

func check_population(amount):
	var from_buildings = 0
	
	if controller_id > -1:
		from_buildings += 25
	
	
	
	%PlanetPopulator.check_population(int((amount + from_buildings) * 0.04))
