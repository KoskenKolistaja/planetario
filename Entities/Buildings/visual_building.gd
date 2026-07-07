extends Node3D


var buildings: Array[PackedScene] = [
	#preload("res://Entities/Buildings/building_1.tscn"),
	preload("res://Entities/Buildings/building_2.tscn"),
	preload("res://Entities/Buildings/building_3.tscn"),
	preload("res://Entities/Buildings/building_4.tscn"),
	#preload("res://Entities/Buildings/building_5.tscn"),
	preload("res://Entities/Buildings/building_6.tscn"),
	preload("res://Entities/Buildings/building_7.tscn"),
	#preload("res://Entities/Buildings/building_8.tscn"),
	#preload("res://Entities/Buildings/building_9.tscn"),
	preload("res://Entities/Buildings/building_10.tscn"),
	#preload("res://Entities/Buildings/building_11.tscn"),
	preload("res://Entities/Buildings/building_12.tscn"),
	#preload("res://Entities/Buildings/building_13.tscn"),
	#preload("res://Entities/Buildings/building_14.tscn"),
]


func _ready():
	%AnimationPlayer.play("build")
	await get_tree().physics_frame
	var scene_instance = buildings.pick_random().instantiate()
	scene_instance.scale.z *= 30
	scene_instance.scale.x *= 30
	scene_instance.scale.y *= 15
	%MeshContainer.add_child(scene_instance)


func delete():
	%AnimationPlayer.play_backwards("build")
	await %AnimationPlayer.animation_finished
	queue_free()
