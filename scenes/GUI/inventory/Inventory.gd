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

func _ready():
	inventory_slots.get_child(selected_slot_idx).selected = true
	if inventory.size() < inventory_space:
		initialize_inventory()
	update_inventory()
	update_equipment()

func _process(_delta):
	if visible:
		get_nav_input()

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

func get_nav_input():
	var new_slot_idx
	if Input.is_action_just_pressed('ui_up'):
		# Equipment Navigation
		if selected_slot_idx < 0:
			if selected_slot_idx == -1:
				new_slot_idx = - rows
			else:
				new_slot_idx = selected_slot_idx + 1
		# Inventory Navigation
		elif selected_slot_idx > 0:
			new_slot_idx = selected_slot_idx - columns
			if new_slot_idx < 0:
				new_slot_idx += inventory_space - 1
		else:
			new_slot_idx = inventory_space - 1
	if Input.is_action_just_pressed('ui_down'):
		# Equipment Navigation
		if selected_slot_idx < 0:
			if abs(selected_slot_idx) >= rows:
				new_slot_idx = -1
			else:
				new_slot_idx = selected_slot_idx - 1
		# Inventory Navigation
		elif selected_slot_idx < inventory_space - 1:
			new_slot_idx = selected_slot_idx + columns
			if new_slot_idx >= inventory_space:
				new_slot_idx -= inventory_space - 1
		else:
			new_slot_idx = 0
	if Input.is_action_just_pressed('ui_left'):
		# Equipment Navigation
		if selected_slot_idx < 0:
			new_slot_idx = abs(selected_slot_idx + 1) * columns + columns - 1
		# Inventory Navigation
		else:
			new_slot_idx = selected_slot_idx - 1
			if selected_slot_idx % columns == 0:
				new_slot_idx = - int(selected_slot_idx / columns + 1)
	if Input.is_action_just_pressed('ui_right'):
		# Equipment Navigation
		if selected_slot_idx < 0:
			new_slot_idx = abs(selected_slot_idx + 1) * columns
		# Inventory Navigation
		else:
			new_slot_idx = selected_slot_idx + 1
			if new_slot_idx % columns == 0:
				new_slot_idx = - int(new_slot_idx / columns)
	if Input.is_action_just_pressed('ui_accept'):
		select_item()
	update_selected_slot(new_slot_idx)

func update_selected_slot(idx):
	if idx != null:
		# Unselect Equipment Slot
		if selected_slot_idx < 0:
			var equipment_idx = abs(selected_slot_idx + 1)
			var equipment_slot = equipment_slots.get_child(equipment_idx).get_child(1)
			equipment_slot.selected = false
		# Unselect Inventory Slot
		else:
			inventory_slots.get_child(selected_slot_idx).selected = false
		# Select Equipment Slot
		if idx < 0:
			var equipment_idx = abs(idx + 1)
			var equipment_slot = equipment_slots.get_child(equipment_idx).get_child(1)
			equipment_slot.selected = true
		# Select Inventory Slot
		else:
			inventory_slots.get_child(idx).selected = true
		
		selected_slot_idx = idx

func select_item():
	if selected_slot_idx >= 0:
		equip_item(selected_slot_idx)
	else:
		unequip_item(selected_slot_idx)

func equip_item(inv_idx):
	if grow_vertically:
		inv_idx = get_vert_inv_idx(inv_idx)
	var item = inventory[inv_idx]
	if item && item.has('slot'):
		inventory[inv_idx] = equipment[item.slot]
		equipment[item.slot] = item
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
