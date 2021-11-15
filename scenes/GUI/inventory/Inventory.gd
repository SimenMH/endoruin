extends ColorRect

onready var inventory = PlayerData.inventory
onready var equpment = PlayerData.equipment
onready var inventory_slots = $ColorRect/HBoxContainer/InventorySlots
onready var equipment_slots = $ColorRect/HBoxContainer/CenterContainer/EquipmentSlots

export var grow_vertically = true

func _ready():
	update_inventory()

func _process(delta):
	# Testing
	if Input.is_action_just_pressed('ui_accept'):
		inventory.append({'name': 'Shortsword'})
		update_inventory()

func update_inventory():
	for i in range(inventory.size()):
		if i >= inventory_slots.get_child_count():
			print('ERROR: Inventory index out of range')
			break
		var slot_idx = i
		if grow_vertically:
			slot_idx = get_vert_slot_idx(i)
		var slot = inventory_slots.get_child(slot_idx)
		slot.update_item(inventory[i])

func get_vert_slot_idx(idx):
	var columns = inventory_slots.columns
	var rows = inventory_slots.get_child_count() / inventory_slots.columns
	var column = idx / rows
	var row = idx - (idx / rows * rows)
	var slot_idx = (row * inventory_slots.columns) + column
	return slot_idx
