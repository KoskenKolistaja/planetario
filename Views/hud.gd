extends Panel


@export var player_id = 0
@export var player : Node3D

var buildings = []
var technology = 0




func _ready():
	update_launch_index(0)
	update_build_index(0)
	await get_tree().physics_frame
	%Cursor.global_position = %Buildables.get_child(0).global_position
	self.self_modulate = PlayerData.colors[player_id]
	self.self_modulate.a = 0.2

func update_technology(amount : int):
	%TechnologyLabel.text = str(amount)
	technology = amount
	
	check_availability()

#buildables = ["space_port","factory","missile_silo","space_radar","bunker"]
#launchables = ["ship","missile","gravitator"]

func check_availability():
	# Buildings
	%SpacePort.disabled = (
		get_building_amount(buildings, "space_port") >= 1
		or technology < BuildingData.prices["space_port"]
	)

	%Factory.disabled = (
		get_building_amount(buildings, "factory") >= 5
		or technology < BuildingData.prices["factory"]
	)

	%SpaceRadar.disabled = (
		get_building_amount(buildings, "space_radar") >= 5
		or technology < BuildingData.prices["space_radar"]
	)

	%MissileSilo.disabled = (
		get_building_amount(buildings, "missile_silo") >= 1
		or technology < BuildingData.prices["missile_silo"]
	)

	%Bunker.disabled = (
		get_building_amount(buildings, "bunker") >= 1
		or technology < BuildingData.prices["bunker"]
	)

	# Launchables
	%Ship.disabled = (
		get_building_amount(buildings, "space_port") == 0
		or technology < MetaData.ship_price
	)

	%Missile.disabled = (
		get_building_amount(buildings, "missile_silo") == 0
		or technology < MetaData.missile_price
	)

	%Gravitator.disabled = technology < MetaData.gravitator_price

func get_building_amount(list,item_name) -> int:
	var amount = 0
	for item in list:
		if item == item_name:
			amount += 1
	return amount

func update_buildings(building_list: Array):
	buildings = building_list.duplicate()
	check_availability()
	
	var space_ports = 0
	var factories = 0
	var missile_silos = 0
	var space_radars = 0
	var bunkers = 0
	
	for b in buildings:
		match b:
			"space_port":
				space_ports += 1
			"factory":
				factories += 1
			"missile_silo":
				missile_silos += 1
			"space_radar":
				space_radars += 1
			"bunker":
				bunkers += 1
	
	%SpacePortAmount.text = str(space_ports) + "/1"
	%FactoryAmount.text = str(factories) + "/5"
	%MissileSiloAmount.text = str(missile_silos) + "/1"
	%SpaceRadarAmount.text = str(space_radars) + "/5"
	%BunkerAmount.text = str(bunkers) + "/1"
	
	%BuildingsTotalAmount.text = "Buildings:    " + str(buildings.size()) + "/13"


func update_build_index(index):
	%Buildables.show()
	%Launchables.hide()
	%Cursor.global_position = %Buildables.get_child(index).global_position

func update_launch_index(index):
	%Buildables.hide()
	%Launchables.show()
	%Cursor.global_position = %Launchables.get_child(index).global_position


func update_planet_name(new_name):
	%PlanetName.text = new_name
	print(new_name)
