extends TextureRect

var selected = false
var item = null

func update_item(new_item):
	item = new_item
	if new_item != null:
		var res = load('res://sprites/items/' + new_item.name + '.png')
		$ItemIcon.texture = res

func _process(delta):
	if selected:
		$SelectedInvSlot.visible = true
	else:
		$SelectedInvSlot.visible = false
