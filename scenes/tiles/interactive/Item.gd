extends Node2D

var item = {'name': 'Shortsword', 'slot': 'mhand'}


func _ready():
	if item:
		var res = load('res://sprites/items/' + item.name + '.png')
		$Sprite.texture = res

func on_interact():
	if GameData.player_node.pickup_item(item):
		queue_free()
