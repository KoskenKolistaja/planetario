extends Node3D

@onready var planets = [
	%Planet,
	%Planet2,
	%Planet3,
	%Planet4,
	%Planet5,
	%Planet6,
	%Planet7,
	%Planet8,
	%Planet9,
	%Planet10,
	%Planet11,
	%Planet12,
]

@onready var players = [
	%Player,
	%Player2,
	%Player3,
]


func _ready():
	for p in players:
		var planet : Planet = planets.pick_random()
		p.planet = planet
		planet.controller_id = p.player_id
		planets.erase(planet)
