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

func _process(delta):
	if visible:
		get_input()
	# Testing
	if Input.is_action_just_pressed('ui_accept'):
		add_to_inventory({'name': 'Shortsword'})
		update_inventory()

func get_input():
	var new_slot_idx
	if Input.is_action_just_pressed('ui_up'):
		new_slot_idx = selected_slot_idx - columns
	if Input.is_action_just_pressed('ui_down'):
		if selected_slot_idx != inventory_space -1:
			new_slot_idx = selected_slot_idx + columns
			if new_slot_idx >= inventory_space:
				new_slot_idx -= inventory_space - 1
		else:
			new_slot_idx = 0
	if Input.is_action_just_pressed('ui_left'):
		new_slot_idx = selected_slot_idx - 1
	if Input.is_action_just_pressed('ui_right'):
		new_slot_idx = selected_slot_idx + 1
	if new_slot_idx != null:
		if new_slot_idx < 0:
			new_slot_idx = inventory_space - 1
		if new_slot_idx >= inventory_space:
			new_slot_idx = 0
		inventory_slots.get_child(selected_slot_idx).selected = false
		inventory_slots.get_child(new_slot_idx).selected = true
		selected_slot_idx = new_slot_idx
	

func initialize_inventory():
	for i in range(inventory_space):
		inventory.append(null)

func update_equipment():
	var slots = equipment_slots.get_children()
	for slot in slots:
		var slot_type = slot.name.to_lower()
		slot.get_child(1).update_item(equipment[slot_type])

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

func get_vert_slot_idx(idx):
	var column = idx / rows
	var row = idx - (idx / rows * rows)
	var slot_idx = (row * inventory_slots.columns) + column
	return slot_idx

func add_to_inventory(item):
	for i in range(inventory.size()):
		if inventory[i] == null:
			inventory[i] = item
			return true
	if inventory.size() < inventory_space:
		inventory.append(item)
		return true
	else:
		print('Inventory full!')
		return false
