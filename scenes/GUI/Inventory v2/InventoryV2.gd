extends ColorRect


var test_item = {
	"name": "Shortsword",
	"size": "Small",
	"damage": [
		"2-6",
		"5-9",
		"7-14",
		"12-18",
		"15-22",
		"20-27"
	],
	"thrown_damage": "1-2",
	"type": "weapon",
	"description": "Lorem ipsum"
}

onready var inventory = PlayerData.inventory
onready var equipment = PlayerData.equipment
var inv_slots = []
var inv_size = [0, 0, 0] # x, y, total
var inv_pos = Vector2(1, 0)

signal update_player_stats

func _physics_process(_delta):
	if visible:
		if Input.is_action_just_pressed('ui_left'):
			move_in_inv(Vector2.LEFT)
		if Input.is_action_just_pressed('ui_right'):
			move_in_inv(Vector2.RIGHT)
		if Input.is_action_just_pressed('ui_up'):
			move_in_inv(Vector2.UP)
		if Input.is_action_just_pressed('ui_down'):
			move_in_inv(Vector2.DOWN)
		if Input.is_action_just_pressed('ui_select'):
			add_to_inventory2(test_item)
		if Input.is_action_just_pressed('ui_accept'):
			select_item()


func _ready():
	get_inv_size()
	inv_slots[inv_pos.x][inv_pos.y].selected = true
	update_equipment()
	update_inventory()

func get_inv_size():
	inv_size[0] = $CenterContainer/HBoxContainer/InvSlotContainer.get_child_count()
	inv_size[1] = $CenterContainer/HBoxContainer/InvSlotContainer/VBoxContainer.get_child_count()
	inv_size[2] = inv_size[0] * inv_size[1]
	
	var inv_container = $CenterContainer/HBoxContainer/InvSlotContainer/
	
	var eq_container = $CenterContainer/HBoxContainer/EqInvSlotContainer
	
	# Equipment Slots
	inv_slots.append([])
	for i in range(eq_container.get_child_count()):
		var eq_slot = eq_container.get_child(i)
		inv_slots[0].append(eq_slot)
	
	# Inventory Slots
	for i in range(inv_container.get_child_count()):
		inv_slots.append([])
		var v_node = inv_container.get_child(i)
		for j in range(v_node.get_child_count()):
			inv_slots[i+1].append(v_node.get_child(j))

func move_in_inv(dir):
	var temp_pos = inv_pos + dir
	
	# While the temp_pos is out of range
	while(temp_pos.x >= inv_slots.size() || temp_pos.y >= inv_slots[inv_pos.x].size() || temp_pos.x < 0 || temp_pos.y < 0):
		# Check if at the end of the x array
		if temp_pos.x >= inv_slots.size(): 
			# Loop back to x pos 0
			temp_pos.x = 0
			temp_pos.y += dir.x
		elif temp_pos.x < 0:
			# Jump to end of array
			temp_pos.x = inv_slots.size() - 1
			temp_pos.y += dir.x
		# Check if at the end of the y array
		elif temp_pos.y >= inv_slots[temp_pos.x].size():
			# Loop back to y pos 0
			temp_pos.y = 0
			temp_pos.x += dir.y
		elif temp_pos.y < 0:
			# Jump to end of array
			temp_pos.y = inv_slots[temp_pos.x].size() - 1
			temp_pos.x += dir.y

	inv_slots[inv_pos.x][inv_pos.y].selected = false
	inv_slots[temp_pos.x][temp_pos.y].selected = true
	
	inv_pos = temp_pos


func add_to_inventory(item):
	for i in range(1, inv_slots.size()):
		for j in range(inv_slots[i].size()):
			if !inv_slots[i][j].item:
				inv_slots[i][j].update_item(item)
				return


func add_to_inventory2(item):
	for i in range(inventory.size()):
		if inventory[i] == null:
			inventory[i] = item
			update_inventory()
			return true
	if inventory.size() < inv_size[2]:
		inventory.append(item)
		update_inventory()
		return true
	else:
		print('Inventory full!')
		return false

func select_item():
	var selected_slot = inv_slots[inv_pos.x][inv_pos.y]
	var item = selected_slot.item
	if item != null:
		if inv_pos.x == 0:
			# Equipment slot
			select_equipped_item()
		elif item.has('type'):
			var inv_idx = pos_to_index(inv_pos.x, inv_pos.y)
			if item.type == 'weapon':
				inventory[inv_idx] = equipment['mhand']
				equipment['mhand'] = item
			else:
				inventory[inv_idx] = equipment[item.type]
				equipment[item.type] = item
		update_equipment()
		update_inventory()

func select_equipped_item():
	var selected_slot = inv_slots[inv_pos.x][inv_pos.y]
	var slot_type = selected_slot.name.to_lower()
	var cur_equipped = equipment[slot_type]
	if (add_to_inventory2(cur_equipped)):
		equipment[slot_type] = null
	else:
		print('No room in inventory to unequip item')

func update_equipment():
	var equipment_slots = inv_slots[0]
	for slot in equipment_slots:
		var slot_type = slot.name.to_lower()
		slot.update_item(equipment[slot_type])
	emit_signal('update_player_stats')

func update_inventory():
	for i in range(inventory.size()):
		var pos = idx_to_pos(i)
		var slot = inv_slots[pos.x][pos.y]
		slot.update_item(inventory[i])

func pos_to_index(x, y):
	return (x - 1) * inv_size[1] + y

func idx_to_pos(idx):
	var x = floor(idx / inv_size[1]) + 1
	var y = idx % inv_size[1]
	return Vector2(x, y)
