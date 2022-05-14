extends ColorRect

onready var inventory = PlayerData.inventory
onready var equipment = PlayerData.equipment
var inv_slots = []
var inv_size = [0, 0, 0] # x, y, total
var select_pos = Vector2(1, 0)
var alt_select_pos = Vector2(1, 0)
var select_active = true
var alt_select_active = false
var alt_select_action = null

signal update_player_stats

func _input(event):
	if visible && (select_active || alt_select_active):
		if event.is_action_pressed('ui_left'):
			move_in_inv(Vector2.LEFT)
		if event.is_action_pressed('ui_right'):
			move_in_inv(Vector2.RIGHT)
		if event.is_action_pressed('ui_up'):
			move_in_inv(Vector2.UP)
		if event.is_action_pressed('ui_down'):
			move_in_inv(Vector2.DOWN)
		if event.is_action_pressed('ui_select'):
			add_to_inventory2(GameData.data.weapons[0])
		if event.is_action_pressed('ui_accept'):
			yield(get_tree(), "idle_frame")
			if select_active:
				select_item()
			elif alt_select_active:
				alt_select_item()
		if event.is_action_pressed('ui_cancel'):
			if alt_select_active:
				end_alt_select()

func _ready():
	get_inv_size()
	inv_slots[select_pos.x][select_pos.y].selected = true
	fill_inventory()
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

func fill_inventory():
	for _i in range(inv_size[2] - inventory.size()):
		inventory.append(null)

func move_in_inv(dir):
	var cur_pos
	if (select_active):
		cur_pos = select_pos
	elif (alt_select_active):
		cur_pos = alt_select_pos
	var temp_pos = cur_pos + dir
	
	# While the temp_pos is out of range
	while(temp_pos.x >= inv_slots.size() || temp_pos.y >= inv_slots[cur_pos.x].size() || temp_pos.x < 0 || temp_pos.y < 0):
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
	
	if (select_active || select_pos != alt_select_pos):
		inv_slots[cur_pos.x][cur_pos.y].selected = false
	inv_slots[temp_pos.x][temp_pos.y].selected = true
	
	if (select_active):
		select_pos = temp_pos
	else:
		alt_select_pos = temp_pos


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
	var selected_slot = inv_slots[select_pos.x][select_pos.y]
	var item = selected_slot.item
	if item != null:
		var options = []
		if select_pos.x == 0:
			# Equipment slot
			options.append('Unequip')
		elif item.has('type'):
			options.append('Equip')
		options.append_array(['Examine', 'Combine', 'Move', 'Drop'])
		var submenu = $SubMenu
		submenu.open_submenu(options)
		submenu.visible = true
		select_active = false

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

func select_action(action):
	match action:
		'Equip':
			var select_inv_idx = pos_to_index(select_pos.x, select_pos.y)
			var selected_item = inventory[select_inv_idx]
			var slots_idx = {'head': 0, 'neck': 1, 'chest': 2, 'feet': 3, 'weapon': 4, 'ring': 6 }
			var start_pos = Vector2(0,slots_idx[selected_item.type])
			start_alt_select(action, start_pos)
		'Unequip':
			unequip_item()
			select_active = true
		'Examine':
			select_active = true
		'Combine':
			select_active = true
		'Move':
			start_alt_select(action, select_pos)
		'Drop':
			select_active = true
		_:
			select_active = true

func start_alt_select(action, initial_pos=Vector2(1,0)):
	alt_select_pos = initial_pos
	alt_select_active = true
	alt_select_action = action
	inv_slots[initial_pos.x][initial_pos.y].selected = true

func end_alt_select():
	alt_select_active = false
	alt_select_action = null
	select_active = true
	if (alt_select_pos != select_pos):
		inv_slots[alt_select_pos.x][alt_select_pos.y].selected = false

func alt_select_item():
	match alt_select_action:
		'Equip':
			equip_item()
		'Move':
			move_item()
		'Combine':
			end_alt_select()
		_:
			end_alt_select()

func equip_item():
	if (alt_select_pos.x != 0):
		print('Select a valid slot')
		return
	var select_inv_idx = pos_to_index(select_pos.x, select_pos.y)
	var selected_item = inventory[select_inv_idx]
	
	var slot = inv_slots[alt_select_pos.x][alt_select_pos.y].name.to_lower()
	if selected_item.type == 'weapon' && (slot == 'mhand' || slot == 'ohand'):
		inventory[select_inv_idx] = equipment[slot]
		equipment[slot] = selected_item
	elif (slot == selected_item.type):
		inventory[select_inv_idx] = equipment[selected_item.type]
		equipment[selected_item.type] = selected_item
	else:
		print('Cannot equip this item in this slot')
		return
	update_equipment()
	update_inventory()
	end_alt_select()


func unequip_item():
	var selected_slot = inv_slots[select_pos.x][select_pos.y]
	var slot_type = selected_slot.name.to_lower()
	var cur_equipped = equipment[slot_type]
	if (add_to_inventory2(cur_equipped)):
		equipment[slot_type] = null
		update_equipment()
	else:
		print('No room in inventory to unequip item')


func move_item():
	if (select_pos.x > 0 && alt_select_pos.x > 0):
		var select_inv_idx = pos_to_index(select_pos.x, select_pos.y)
		var alt_select_inv_idx = pos_to_index(alt_select_pos.x, alt_select_pos.y)
		var select_item = inventory[select_inv_idx]
		var alt_select_item = inventory[alt_select_inv_idx]
		
		inventory[select_inv_idx] = alt_select_item
		inventory[alt_select_inv_idx] = select_item
		if (select_pos != alt_select_pos):
			inv_slots[select_pos.x][select_pos.y].selected = false
		select_pos = alt_select_pos
		update_inventory()
		end_alt_select()
	else:
		print('Cannot move this item here')
