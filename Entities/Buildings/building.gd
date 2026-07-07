extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
var buildings: Array[PackedScene] = [
	preload("res://Entities/Buildings/building_2.tscn"),
	preload("res://Entities/Buildings/building_3.tscn"),
	preload("res://Entities/Buildings/building_4.tscn"),
	preload("res://Entities/Buildings/building_6.tscn"),
	preload("res://Entities/Buildings/building_7.tscn"),
	preload("res://Entities/Buildings/building_10.tscn"),
	preload("res://Entities/Buildings/building_12.tscn"),
]


func delete():
	queue_free()
