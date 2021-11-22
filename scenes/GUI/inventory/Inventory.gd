extends ColorRect

onready var inventory = PlayerData.inventory
onready var equipment = PlayerData.equipment
onready var inventory_slots = $ColorRect/HBoxContainer/InventorySlots
onready var equipment_slots = $ColorRect/HBoxContainer/CenterContainer/EquipmentSlots
onready var inventory_space = inventory_slots.get_child_count()
onready var columns = inventory_slots.columns
onready var rows = inventory_space / inventory_slots.columns

export var grow_vertically = true

var selected_slot_idx = 0
var alt_selected_slot_idx = 0
var alt_select = false

enum EQUIPMENT_SLOTS { HEAD, NECK, CHEST, FEET, MHAND, OHAND, RING1, RING2 }

signal update_player_stats

func _ready():
	inventory_slots.get_child(selected_slot_idx).selected = true
	if inventory.size() < inventory_space:
		initialize_inventory()
	update_inventory()
	update_equipment()

func _process(_delta):
	if visible:
		if alt_select:
			var new_slot_idx = get_new_idx(alt_selected_slot_idx)
			update_selected_slot(alt_selected_slot_idx, new_slot_idx)
			alt_selected_slot_idx = new_slot_idx
			if Input.is_action_just_pressed('ui_accept'):
				alt_select = false
				hide_selected_slot(alt_selected_slot_idx)
		else:
			var new_slot_idx = get_new_idx(selected_slot_idx)
			update_selected_slot(selected_slot_idx, new_slot_idx)
			selected_slot_idx = new_slot_idx
			if Input.is_action_just_pressed('ui_accept'):
				alt_selected_slot_idx = 0
				alt_select = true

func initialize_inventory():
	for _i in range(inventory_space):
		inventory.append(null)

func update_inventory():
	for i in range(inventory.size()):
		if i >= inventory_space:
			print('ERROR: Inventory index out of range')
			break
		var slot_idx = i
		if grow_vertically:
			slot_idx = get_vert_slot_idx(i)
		var slot = inventory_slots.get_child(slot_idx)
		slot.update_item(inventory[i])

func update_equipment():
	var slots = equipment_slots.get_children()
	for slot in slots:
		var slot_type = slot.name.to_lower()
		slot.get_child(1).update_item(equipment[slot_type])
	emit_signal('update_player_stats')

func get_vert_slot_idx(idx):
	var row = idx - (idx / rows * rows)
	var column = idx / rows
	var slot_idx = (row * columns) + column
	return slot_idx

func get_vert_inv_idx(idx):
	var row = idx / columns
	var column = idx - (idx / columns * columns)
	var inv_idx = (rows * column) + row
	return inv_idx

func add_to_inventory(item):
	for i in range(inventory.size()):
		if inventory[i] == null:
			inventory[i] = item
			update_inventory()
			return true
	if inventory.size() < inventory_space:
		inventory.append(item)
		update_inventory()
		return true
	else:
		print('Inventory full!')
		return false

func get_new_idx(prev_slot_idx):
	var new_slot_idx = prev_slot_idx
	if Input.is_action_just_pressed('ui_up'):
		# Equipment Navigation
		if prev_slot_idx < 0:
			if prev_slot_idx == -1:
				new_slot_idx = - rows
			else:
				new_slot_idx = prev_slot_idx + 1
		# Inventory Navigation
		elif prev_slot_idx > 0:
			new_slot_idx = prev_slot_idx - columns
			if new_slot_idx < 0:
				new_slot_idx += inventory_space - 1
		else:
			new_slot_idx = inventory_space - 1
	if Input.is_action_just_pressed('ui_down'):
		# Equipment Navigation
		if prev_slot_idx < 0:
			if abs(prev_slot_idx) >= rows:
				new_slot_idx = -1
			else:
				new_slot_idx = prev_slot_idx - 1
		# Inventory Navigation
		elif prev_slot_idx < inventory_space - 1:
			new_slot_idx = prev_slot_idx + columns
			if new_slot_idx >= inventory_space:
				new_slot_idx -= inventory_space - 1
		else:
			new_slot_idx = 0
	if Input.is_action_just_pressed('ui_left'):
		# Equipment Navigation
		if prev_slot_idx < 0:
			new_slot_idx = abs(prev_slot_idx + 1) * columns + columns - 1
		# Inventory Navigation
		else:
			new_slot_idx = prev_slot_idx - 1
			if prev_slot_idx % columns == 0:
				new_slot_idx = - int(prev_slot_idx / columns + 1)
	if Input.is_action_just_pressed('ui_right'):
		# Equipment Navigation
		if prev_slot_idx < 0:
			new_slot_idx = abs(prev_slot_idx + 1) * columns
		# Inventory Navigation
		else:
			new_slot_idx = prev_slot_idx + 1
			if new_slot_idx % columns == 0:
				new_slot_idx = - int(new_slot_idx / columns)
	return new_slot_idx

func update_selected_slot(prev_idx, new_idx):
	if !alt_select || alt_selected_slot_idx != selected_slot_idx:
		hide_selected_slot(prev_idx)
	show_selected_slot(new_idx)

func show_selected_slot(idx):
	# Select Equipment Slot
	if idx < 0:
		var equipment_idx = abs(idx + 1)
		var equipment_slot = equipment_slots.get_child(equipment_idx).get_child(1)
		equipment_slot.selected = true
	# Select Inventory Slot
	else:
		inventory_slots.get_child(idx).selected = true

func hide_selected_slot(idx):
	# Unselect Equipment Slot
	if idx < 0:
		var equipment_idx = abs(idx + 1)
		var equipment_slot = equipment_slots.get_child(equipment_idx).get_child(1)
		equipment_slot.selected = false
	# Unselect Inventory Slot
	else:
		inventory_slots.get_child(idx).selected = false

func select_item():
	if selected_slot_idx >= 0:
		equip_item(selected_slot_idx)
	else:
		unequip_item(selected_slot_idx)

func equip_item(inv_idx):
	if grow_vertically:
		inv_idx = get_vert_inv_idx(inv_idx)
	var item = inventory[inv_idx]
	if item && item.has('type'):
		if item.type == 'weapon':
			inventory[inv_idx] = equipment['mhand']
			equipment['mhand'] = item
		else:
			inventory[inv_idx] = equipment[item.type]
			equipment[item.type] = item
	update_inventory()
	update_equipment()

func unequip_item(equip_idx):
	equip_idx = abs(equip_idx + 1)
	var slot_type = equipment_slots.get_child(equip_idx).name.to_lower()
	if equipment.has(slot_type):
		var cur_equipped = equipment[slot_type]
		if add_to_inventory(cur_equipped):
			equipment[slot_type] = null
	update_inventory()
	update_equipment()
