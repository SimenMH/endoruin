extends TextureRect

var item = null

func update_item(new_item):
	item = new_item
	if new_item != null:
		var res = load('res://sprites/items/' + new_item.name + '.png')
		$ItemIcon.texture = res
