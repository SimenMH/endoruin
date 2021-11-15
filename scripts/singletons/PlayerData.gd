extends Node

var player_name = 'Bob'
var stats = {
	'level': 1,
	'max_health': 15,
	'health': 15,
	'max_mana': 10,
	'mana': 10,
	'armour': 0,
	'weight': 0,
	'experience': 0
}
var inventory = []
var equipment = {
	'head': null,
	'neck': null,
	'chest': null,
	'feet': null,
	'mhand': null,
	'ohand': null,
	'ring1': null,
	'ring2': null,
}
var skills = []
var abilities = []

func _ready():
	stats.health = stats.max_health
	stats.mana = stats.max_mana
