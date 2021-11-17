extends Node

var player_node = null
var level_layer = 0
var data

func _ready():
	var file = File.new()
	file.open("res://data.json", file.READ)
	var json = file.get_as_text()
	data = JSON.parse(json).result
	file.close()
