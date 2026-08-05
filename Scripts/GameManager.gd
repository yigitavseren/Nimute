extends Node2D

var stone_scene = preload("res://Scenes/Stone.tscn")
var all_stones = []
var selected_stones = []
var current_turn = "Player"
var selection_mode = "none"
var ai_special_uses_left = 0
var ai_ultimate_uses_left = 0
var current_level = 1

var normal_move_masks = []
var l_move_masks = []
var ultimate_move_masks = []
var memo = {}

var special_moves = []
var bomb_stones = []
var bomb_move_masks = []
var bomb_stone_ids = []
var adj_masks = []

var armored_stone_ids = []
var current_armor_state: int = 0

func _ready():
	$EndTurnButton.pressed.connect(end_turn)
	$MainMenuButton.pressed.connect(show_main_menu)
	$HUD/FastForwardButton.toggled.connect(func(pressed): Engine.time_scale = 4.0 if pressed else 1.0)
	$LevelSelectUI/Panel/PartTitle.pressed.connect(func():
		$LevelSelectUI/Panel/LevelButtons.show()
		$LevelSelectUI/Panel/PartTitle.hide()
	)
	$LevelSelectUI/Panel/LevelButtons/BackButton.pressed.connect(func():
		$LevelSelectUI/Panel/LevelButtons.hide()
		$LevelSelectUI/Panel/PartTitle.show()
	)
	$LevelSelectUI/Panel/LevelButtons/Level1Button.pressed.connect(func(): start_level(1))
	$LevelSelectUI/Panel/LevelButtons/Level2Button.pressed.connect(func(): start_level(2))
	$LevelSelectUI/Panel/LevelButtons/Level3Button.pressed.connect(func(): start_level(3))
	$LevelSelectUI/Panel/LevelButtons/Level4Button.pressed.connect(func(): start_level(4))
	$LevelSelectUI/Panel/LevelButtons/Level5Button.pressed.connect(func(): start_level(5))
	$LevelSelectUI/Panel/LevelButtons/Level6Button.pressed.connect(func(): start_level(6))
	$LevelSelectUI/Panel/LevelButtons/Level7Button.pressed.connect(func(): start_level(7))
	
	# --- UI STYLING ---
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.3, 0.3, 0.4)
	$LevelSelectUI/Panel.add_theme_stylebox_override("panel", panel_style)
	
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.2, 0.2, 0.25)
	btn_normal.corner_radius_top_left = 8
	btn_normal.corner_radius_top_right = 8
	btn_normal.corner_radius_bottom_right = 8
	btn_normal.corner_radius_bottom_left = 8
	
	var btn_hover = btn_normal.duplicate()
	btn_hover.bg_color = Color(0.3, 0.3, 0.35)
	
	var title_normal = btn_normal.duplicate()
	title_normal.bg_color = Color(0.7, 0.4, 0.1)
	var title_hover = title_normal.duplicate()
	title_hover.bg_color = Color(0.8, 0.5, 0.2)
	
	$LevelSelectUI/Panel/PartTitle.add_theme_stylebox_override("normal", title_normal)
	$LevelSelectUI/Panel/PartTitle.add_theme_stylebox_override("hover", title_hover)
	
	for btn in $LevelSelectUI/Panel/LevelButtons.get_children():
		if btn is Button:
			btn.add_theme_stylebox_override("normal", btn_normal)
			btn.add_theme_stylebox_override("hover", btn_hover)
			
	var back_normal = btn_normal.duplicate()
	back_normal.bg_color = Color(0.6, 0.2, 0.2)
	var back_hover = back_normal.duplicate()
	back_hover.bg_color = Color(0.8, 0.3, 0.3)
	$LevelSelectUI/Panel/LevelButtons/BackButton.add_theme_stylebox_override("normal", back_normal)
	$LevelSelectUI/Panel/LevelButtons/BackButton.add_theme_stylebox_override("hover", back_hover)
	# -----------------
	
	show_main_menu()

func show_main_menu():
	$LevelSelectUI.show()
	$Board.hide()
	$EndTurnButton.hide()
	$MainMenuButton.hide()
	$HUD.hide()

func start_level(level_id: int):
	current_level = level_id
	$LevelSelectUI.hide()
	$Board.show()
	$EndTurnButton.show()
	$MainMenuButton.show()
	$HUD.show()
	$HUD/GameOverPanel.hide()
	create_board()

func create_board():
	for s in all_stones:
		if is_instance_valid(s): s.queue_free()
	all_stones.clear()
	selected_stones.clear()
	bomb_stones.clear()
	armored_stone_ids.clear()
	current_armor_state = 0
	selection_mode = "none"
	current_turn = "Player"
	$EndTurnButton.disabled = false
	
	if current_level >= 4: ai_special_uses_left = 2
	else: ai_special_uses_left = 1
	
	if current_level == 7: ai_ultimate_uses_left = 1
	else: ai_ultimate_uses_left = 0
	
	if current_level == 7:
		$Board.scale = Vector2(0.85, 0.85)
	else:
		$Board.scale = Vector2(1.0, 1.0)
	$HUD/AILabel.text = "Zürafa Boss 'L' Hakkı: " + str(ai_special_uses_left)
	if ai_ultimate_uses_left > 0:
		$HUD/AILabel.text += "\nZürafa 'Nihai Atak' Hakkı: " + str(ai_ultimate_uses_left)
	
	if current_level == 1:
		var rows = [1, 3, 5, 7]
		var start_y = -120
		for r in range(rows.size()):
			var count = rows[r]
			var start_x = -(count * 80) / 2 
			var start_col = -int(count / 2.0)
			for i in range(count):
				spawn_stone(r, start_col + i, start_x + (i * 80) + 40, start_y + (r * 80))
				
	elif current_level == 2:
		var start_y = -160
		for r in range(5):
			var start_x = -(5 * 80) / 2
			for c in range(5):
				spawn_stone(r, c - 2, start_x + (c * 80) + 40, start_y + (r * 80))
				
	elif current_level == 3:
		var start_y = -160
		# Top Row
		for c in [-1, 0, 1]: spawn_stone(-1, c, c * 80 + 40, start_y - 80)
		
		# Middle Row (Wings and Bomb)
		for c in [-5, -4, -3, -2, -1, 1, 2, 3, 4, 5]:
			spawn_stone(0, c, c * 80 + 40, start_y)
		var b = spawn_stone(0, 0, 40, start_y)
		make_bomb(b)
		
		# Bottom Row 1
		for c in [-1, 0, 1]: spawn_stone(1, c, c * 80 + 40, start_y + 80)
		
		# UFO Legs
		for r in [2, 3, 4]:
			spawn_stone(r, -4, -4 * 80 + 40, start_y + r * 80)
			spawn_stone(r, 4, 4 * 80 + 40, start_y + r * 80)
			
	elif current_level == 4:
		var start_y = -240
		var start_x = -320
		for r in range(7):
			for c in range(9):
				var should_spawn = false
				var is_bomb = false
				
				if c % 4 == 0:
					should_spawn = true
				elif c % 2 == 1:
					if r % 2 == 0: should_spawn = true
				else:
					should_spawn = true
					if r % 2 == 0: is_bomb = true
					
				if should_spawn:
					var s = spawn_stone(r, c - 4, start_x + c * 80, start_y + r * 80)
					if is_bomb: make_bomb(s)
					
	elif current_level == 5:
		var start_y = -240
		var start_x = -360
		var coords = [
			Vector2(0, 2), Vector2(0, 7),
			Vector2(1, 1), Vector2(1, 2), Vector2(1, 3), Vector2(1, 6), Vector2(1, 7), Vector2(1, 8),
			Vector2(2, 0), Vector2(2, 1), Vector2(2, 3), Vector2(2, 4), Vector2(2, 5), Vector2(2, 6), Vector2(2, 8), Vector2(2, 9),
			Vector2(3, 1), Vector2(3, 2), Vector2(3, 3), Vector2(3, 6), Vector2(3, 7), Vector2(3, 8),
			Vector2(4, 3), Vector2(4, 6),
			Vector2(5, 4), Vector2(5, 5),
			Vector2(6, 4)
		]
		var armors = [
			Vector2(2, 3), Vector2(2, 4), Vector2(2, 5), Vector2(2, 6),
			Vector2(3, 1), Vector2(3, 2), Vector2(3, 3), Vector2(3, 6), Vector2(3, 7), Vector2(3, 8)
		]
		for pos in coords:
			var is_bottom = (pos.x == 6 and pos.y == 4)
			var logical_c = 99 if is_bottom else int(pos.y)
			var s = spawn_stone(int(pos.x), logical_c, start_x + pos.y * 80, start_y + pos.x * 80)
			if is_bottom:
				s.position.x += 40 # Visually center the bottom stone at col 4.5
			if armors.has(pos):
				make_armored(s)
				
	elif current_level == 6:
		var start_y = -300
		var start_x = -270
		var coords = [
			Vector2(0, 3), Vector2(1, 1), Vector2(1, 2), Vector2(1, 3),
			Vector2(2, 3), Vector2(3, 3), Vector2(4, 3), Vector2(5, 3),
			Vector2(6, 3), Vector2(6, 4), Vector2(6, 5), Vector2(6, 6), Vector2(6, 7), Vector2(6, 8),
			Vector2(7, 3), Vector2(7, 4), Vector2(7, 5), Vector2(7, 6), Vector2(7, 7), Vector2(7, 8),
			Vector2(8, 3), Vector2(9, 3), Vector2(10, 3),
			Vector2(8, 8), Vector2(9, 8), Vector2(10, 8)
		]
		var armors = [
			Vector2(6, 3), Vector2(6, 4), Vector2(6, 5), Vector2(6, 6), Vector2(6, 7), Vector2(6, 8),
			Vector2(7, 3), Vector2(7, 4), Vector2(7, 5), Vector2(7, 7), Vector2(7, 8)
		]
		var bombs = [
			Vector2(1, 3), # Head
			Vector2(7, 6), # Body Bottom
			Vector2(10, 3), # Front Hoof
			Vector2(10, 8) # Back Hoof
		]
		for pos in coords:
			var s = spawn_stone(int(pos.x), int(pos.y), start_x + pos.y * 60, start_y + pos.x * 60)
			if armors.has(pos):
				make_armored(s)
			if bombs.has(pos):
				make_bomb(s)
				
	elif current_level == 7:
		var start_y = -270
		var start_x = -450
		var coords = []
		for c in range(4, 16): coords.append(Vector2(0, c))
		for r in range(1, 3): coords.append(Vector2(r, 15))
		for c in range(9, 16): coords.append(Vector2(3, c))
		for r in range(4, 6): coords.append(Vector2(r, 9))
		for c in range(9, 13): coords.append(Vector2(6, c))
		for r in range(7, 9): coords.append(Vector2(r, 12))
		for c in range(5, 13): coords.append(Vector2(9, c))
		
		for c in range(0, 4): coords.append(Vector2(2, c))
		for r in range(3, 5):
			coords.append(Vector2(r, 0))
			coords.append(Vector2(r, 3))
		for c in range(0, 4): coords.append(Vector2(5, c))
		
		for c in range(4, 9): coords.append(Vector2(4, c))
		
		for pos in coords:
			spawn_stone(int(pos.x), int(pos.y), start_x + pos.y * 60, start_y + pos.x * 60)
				
	generate_all_move_masks()

func spawn_stone(r, c, x, y):
	var stone = stone_scene.instantiate()
	stone.row_index = r
	stone.col_index = c
	stone.position = Vector2(x, y)
	stone.stone_clicked.connect(_on_stone_clicked)
	$Board.add_child(stone)
	all_stones.append(stone)
	return stone

func make_bomb(stone):
	bomb_stones.append(stone)
	stone.base_color = Color(0.2, 0.2, 0.2)
	stone.modulate = stone.base_color

func make_armored(stone):
	var id = all_stones.find(stone)
	armored_stone_ids.append(id)
	current_armor_state |= (1 << id)
	stone.base_color = Color(0.6, 0.2, 0.8) # Purple
	stone.modulate = stone.base_color

func build_adj_masks():
	adj_masks.clear()
	for i in range(all_stones.size()):
		var mask = 0
		var r_i = all_stones[i].row_index
		var c_i = all_stones[i].col_index
		for j in range(all_stones.size()):
			if i == j: continue
			var r_j = all_stones[j].row_index
			var c_j = all_stones[j].col_index
			if (r_i == r_j and abs(c_i - c_j) == 1) or (c_i == c_j and abs(r_i - r_j) == 1):
				mask |= (1 << j)
		adj_masks.append(mask)

func generate_all_move_masks():
	normal_move_masks.clear()
	special_moves.clear()
	bomb_move_masks.clear()
	bomb_stone_ids.clear()
	
	var row_groups = {}
	var col_groups = {}
	for i in range(all_stones.size()):
		var s = all_stones[i]
		if not row_groups.has(s.row_index): row_groups[s.row_index] = []
		row_groups[s.row_index].append(s)
		if not col_groups.has(s.col_index): col_groups[s.col_index] = []
		col_groups[s.col_index].append(s)
		
	# Yatay segmentler
	for r in row_groups.values():
		r.sort_custom(func(a, b): return a.col_index < b.col_index)
		for start in range(r.size()):
			for end in range(start, r.size()):
				var is_contig = true
				for i in range(start, end):
					if r[i+1].col_index - r[i].col_index != 1:
						is_contig = false
						break
				if is_contig:
					var mask = 0
					for i in range(start, end + 1):
						mask |= (1 << all_stones.find(r[i]))
					if not normal_move_masks.has(mask): normal_move_masks.append(mask)
					
	# Dikey segmentler
	for c in col_groups.values():
		c.sort_custom(func(a, b): return a.row_index < b.row_index)
		for start in range(c.size()):
			for end in range(start, c.size()):
				var is_contig = true
				for i in range(start, end):
					if c[i+1].row_index - c[i].row_index != 1:
						is_contig = false
						break
				if is_contig:
					var mask = 0
					for i in range(start, end + 1):
						mask |= (1 << all_stones.find(c[i]))
					if not normal_move_masks.has(mask): normal_move_masks.append(mask)
					
	# L şekli segmentler
	for corner in all_stones:
		var row_segs = []
		for dir in [-1, 1]:
			var current_seg = [corner]
			var col = corner.col_index
			while true:
				col += dir
				var next_s = get_stone_at_full(corner.row_index, col)
				if next_s:
					current_seg.append(next_s)
					row_segs.append(current_seg.duplicate())
				else: break
		var col_segs = []
		for dir in [-1, 1]:
			var current_seg = [corner]
			var row = corner.row_index
			while true:
				row += dir
				var next_s = get_stone_at_full(row, corner.col_index)
				if next_s:
					current_seg.append(next_s)
					col_segs.append(current_seg.duplicate())
				else: break
					
		for rs in row_segs:
			for cs in col_segs:
				var mask = 0
				for s in rs: mask |= (1 << all_stones.find(s))
				for s in cs: mask |= (1 << all_stones.find(s))
				if not l_move_masks.has(mask) and not normal_move_masks.has(mask):
					l_move_masks.append(mask)

	# Bomba Etki Alanları
	for bomb in bomb_stones:
		if is_instance_valid(bomb):
			var bomb_id = all_stones.find(bomb)
			var mask = (1 << bomb_id)
			for dir in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
				var neighbor = get_stone_at_full(bomb.row_index + dir.x, bomb.col_index + dir.y)
				if neighbor:
					mask |= (1 << all_stones.find(neighbor))
			bomb_move_masks.append(mask)
			bomb_stone_ids.append(bomb_id)
			
	var count_bits = func(m):
		var c = 0
		var temp = m
		while temp > 0:
			c += temp & 1
			temp >>= 1
		return c
		
	normal_move_masks.sort_custom(func(a, b): return count_bits.call(a) > count_bits.call(b))
	l_move_masks.sort_custom(func(a, b): return count_bits.call(a) > count_bits.call(b))
	
	build_adj_masks()
	if current_level == 7:
		build_ultimate_move_masks()

func build_ultimate_move_masks():
	ultimate_move_masks.clear()
	var seen = {}
	for i in range(all_stones.size()):
		_dfs_ultimate(i, 1 << i, seen)
	for mask in seen.keys():
		if not normal_move_masks.has(mask) and not l_move_masks.has(mask):
			ultimate_move_masks.append(mask)

func _dfs_ultimate(curr: int, mask: int, seen: Dictionary):
	if not seen.has(mask):
		seen[mask] = true
	var adj = adj_masks[curr]
	for next_node in range(all_stones.size()):
		if (adj & (1 << next_node)) != 0:
			if (mask & (1 << next_node)) == 0:
				_dfs_ultimate(next_node, mask | (1 << next_node), seen)

func get_stone_at_full(r: int, c: int):
	for s in all_stones:
		if is_instance_valid(s) and not s.is_queued_for_deletion():
			if s.row_index == r and s.col_index == c: return s
	return null

func _on_stone_clicked(row_index, col_index, stone):
	if current_turn != "Player": return
	
	if stone.is_selected:
		stone.deselect()
		selected_stones.erase(stone)
		if selected_stones.size() <= 1:
			selection_mode = "none"
		return
		
	if selected_stones.size() == 0 and bomb_stones.has(stone):
		detonate_bomb(stone)
		return
		
	var new_selected = selected_stones.duplicate()
	new_selected.append(stone)
	
	if new_selected.size() == 1:
		stone.select()
		selected_stones.append(stone)
		return
		
	var mode = selection_mode
	if mode == "none":
		if row_index == selected_stones[0].row_index: mode = "row"
		elif col_index == selected_stones[0].col_index: mode = "col"
		else: return

	if mode == "row" and row_index != selected_stones[0].row_index: return
	if mode == "col" and col_index != selected_stones[0].col_index: return
		
	if not is_contiguous(new_selected, mode):
		print("Bitişik seçmelisiniz!")
		return
		
	selection_mode = mode
	stone.select()
	selected_stones.append(stone)

func is_contiguous(stones_arr: Array, mode: String) -> bool:
	if stones_arr.size() <= 1: return true
	var indices = []
	for s in stones_arr:
		if mode == "row": indices.append(s.col_index)
		else: indices.append(s.row_index)
	indices.sort()
	
	var min_idx = indices[0]
	var max_idx = indices[indices.size()-1]
	
	if max_idx - min_idx != indices.size() - 1:
		return false
	return true

func end_turn():
	if selected_stones.size() == 0: return
		
	var to_free = []
	for stone in selected_stones:
		var s_id = all_stones.find(stone)
		if (current_armor_state & (1 << s_id)) != 0:
			current_armor_state &= ~(1 << s_id)
			stone.base_color = Color(1, 1, 1) # Zırhı kırıldı, temeli beyaza dön
			stone.modulate = Color(1, 1, 1) # Beyaza dön
			stone.deselect()
		else:
			to_free.append(stone)
			
	for stone in to_free:
		if is_instance_valid(stone): stone.queue_free()
		
	selected_stones.clear()
	selection_mode = "none"
	
	await get_tree().process_frame
	if check_win_condition(): return
	
	current_turn = "Enemy"
	play_enemy_turn()

func detonate_bomb(bomb):
	current_turn = "Exploding"
	$EndTurnButton.disabled = true
	print("BOMBA PATLADI!")
	
	var to_destroy = [bomb]
	for dir in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		var neighbor = get_stone_at_full(bomb.row_index + dir.x, bomb.col_index + dir.y)
		if neighbor and is_instance_valid(neighbor) and not neighbor.is_queued_for_deletion():
			to_destroy.append(neighbor)
			
	for s in to_destroy:
		s.modulate = Color(1, 0.2, 0.2)
	
	await get_tree().create_timer(0.4).timeout
	
	for s in to_destroy:
		if not is_instance_valid(s): continue
		
		var s_id = all_stones.find(s)
		if s != bomb and (current_armor_state & (1 << s_id)) != 0:
			current_armor_state &= ~(1 << s_id)
			s.base_color = Color(1, 1, 1) # Zırh kırıldı
			s.modulate = Color(1, 1, 1)
			s.deselect()
		else:
			s.queue_free()
			
	await get_tree().process_frame
	if check_win_condition(): return
	
	current_turn = "Enemy"
	play_enemy_turn()

func check_win_condition() -> bool:
	var remaining = 0
	for s in all_stones:
		if is_instance_valid(s) and not s.is_queued_for_deletion(): remaining += 1
		
	if remaining == 0:
		print(current_turn + " kaybetti! (Son taşı alan kaybeder)")
		$HUD/GameOverPanel.show()
		if current_turn == "Player":
			$HUD/GameOverPanel/GameOverLabel.text = "KAYBETTİN!\n(Son Taşı Alan Kaybeder)"
			$HUD/GameOverPanel/GameOverLabel.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		else:
			$HUD/GameOverPanel/GameOverLabel.text = "KAZANDIN!\nZürafa Kaybetti!"
			$HUD/GameOverPanel/GameOverLabel.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
		return true
	return false

func play_enemy_turn():
	$EndTurnButton.disabled = true
	await get_tree().create_timer(1.0).timeout
	if current_turn != "Enemy": return
	
	var current_board_state = 0
	var stones_left = 0
	for i in range(all_stones.size()):
		var s = all_stones[i]
		if is_instance_valid(s) and not s.is_queued_for_deletion():
			current_board_state |= (1 << i)
			stones_left += 1
			
	var max_depth = 10
	if stones_left <= 10: max_depth = 30
	elif stones_left <= 12: max_depth = 20
	elif stones_left <= 15: max_depth = 12
	elif stones_left <= 18: max_depth = 8
	
	memo.clear()
	var best_move_mask = get_best_move_mask(current_board_state, current_armor_state, max_depth, ai_special_uses_left, ai_ultimate_uses_left)
	
	if best_move_mask == 0:
		print("Yapay Zeka hamle bulamadı!")
		current_turn = "Player"
		$EndTurnButton.disabled = false
		return
		
	var final_move = []
	for i in range(all_stones.size()):
		if (best_move_mask & (1 << i)) != 0:
			if is_instance_valid(all_stones[i]) and not all_stones[i].is_queued_for_deletion():
				final_move.append(all_stones[i])
			
	var is_bomb_detonation = false
	for i in range(bomb_move_masks.size()):
		if best_move_mask == (current_board_state & bomb_move_masks[i]):
			if not normal_move_masks.has(best_move_mask):
				is_bomb_detonation = true
				break
				
	if is_bomb_detonation:
		print("Yapay Zeka BOMBA PATLATTI!")
		for s in final_move:
			if is_instance_valid(s): s.modulate = Color(1, 0.2, 0.2)
		await get_tree().create_timer(0.4).timeout
	else:
		if ai_ultimate_uses_left > 0 and ultimate_move_masks.has(best_move_mask):
			ai_ultimate_uses_left -= 1
			$HUD/AILabel.text = "Zürafa Boss 'L' Hakkı: " + str(ai_special_uses_left) + "\nZürafa 'Nihai Atak' Hakkı: " + str(ai_ultimate_uses_left)
			print("Zürafa Boss 'Nihai Atak' özel yeteneğini kullandı!")
		elif ai_special_uses_left > 0 and l_move_masks.has(best_move_mask):
			ai_special_uses_left -= 1
			if ai_ultimate_uses_left > 0:
				$HUD/AILabel.text = "Zürafa Boss 'L' Hakkı: " + str(ai_special_uses_left) + "\nZürafa 'Nihai Atak' Hakkı: " + str(ai_ultimate_uses_left)
			else:
				$HUD/AILabel.text = "Zürafa Boss 'L' Hakkı: " + str(ai_special_uses_left)
			print("Zürafa Boss 'L Alma' özel yeteneğini kullandı! (Kalan hak: ", ai_special_uses_left, ")")
		print("Yapay Zeka ", final_move.size(), " taşı hedef aldı. (Derinlik: ", max_depth, ")")
		for s in final_move:
			if is_instance_valid(s) and not s.is_queued_for_deletion():
				s.select()
				await get_tree().create_timer(0.3).timeout
				
	for s in final_move:
		var s_id = all_stones.find(s)
		if (current_armor_state & (1 << s_id)) != 0:
			current_armor_state &= ~(1 << s_id)
			if is_instance_valid(s): 
				s.base_color = Color(1, 1, 1)
				s.modulate = Color(1, 1, 1)
				s.deselect()
		else:
			if is_instance_valid(s): s.queue_free()
			
	await get_tree().process_frame
	if check_win_condition(): return
	
	current_turn = "Player"
	$EndTurnButton.disabled = false
	print("Sıra sende!")

var search_node_count: int = 0

func get_best_move_mask(board_state: int, armor_state: int, max_depth: int, special_uses: int, ultimate_uses: int) -> int:
	search_node_count = 0
	var best_score: float = -9999.0
	var best_moves = []
	var alpha: float = -9999.0
	var beta: float = 9999.0
	
	var available_moves = []
	for m in normal_move_masks:
		if (board_state & m) == m: available_moves.append(m)
		
	for i in range(bomb_move_masks.size()):
		var b_id = bomb_stone_ids[i]
		if (board_state & (1 << b_id)) != 0:
			available_moves.append(board_state & bomb_move_masks[i])
			
	var special_moves = []
	if special_uses > 0:
		for m in l_move_masks:
			if (board_state & m) == m: special_moves.append(m)
			
	var ultimate_moves = []
	if ultimate_uses > 0:
		for m in ultimate_move_masks:
			if (board_state & m) == m: ultimate_moves.append(m)
			
	var all_moves = []
	if current_level == 7:
		# KESİN EMİR: Eğer Nihai Atak varsa, sadece Nihai Atakları düşün! L varsa sadece L'leri düşün!
		if ultimate_uses > 0 and ultimate_moves.size() > 0:
			all_moves = ultimate_moves.duplicate()
		elif special_uses > 0 and special_moves.size() > 0:
			all_moves = special_moves.duplicate()
		else:
			all_moves = available_moves.duplicate()
	else:
		all_moves = available_moves.duplicate()
		all_moves.append_array(special_moves)
		all_moves.append_array(ultimate_moves)
		
	if all_moves.size() == 0: return 0
	
	for move in all_moves:
		var hit_armored = move & armor_state
		var destroyed = move & ~armor_state
		var new_state = board_state & ~destroyed
		var new_armor = armor_state & ~hit_armored
		
		var is_special_used = special_uses > 0 and special_moves.has(move)
		var new_special_uses = special_uses - 1 if is_special_used else special_uses
		
		var is_ultimate_used = ultimate_uses > 0 and ultimate_moves.has(move)
		var new_ultimate_uses = ultimate_uses - 1 if is_ultimate_used else ultimate_uses
		
		# --- KESİN KAZANÇ KOMUTLARI OVERRIDE ---
		var remaining_check = new_state
		var sizes = []
		while remaining_check > 0:
			var i = 0
			while (remaining_check & (1 << i)) == 0: i += 1
			var comp_mask = (1 << i)
			var frontier = comp_mask
			while frontier > 0:
				var next_frontier = 0
				var temp = frontier
				while temp > 0:
					var bit = 0
					while (temp & (1 << bit)) == 0: bit += 1
					next_frontier |= (adj_masks[bit] & remaining_check)
					temp &= ~(1 << bit)
				next_frontier &= ~comp_mask
				comp_mask |= next_frontier
				frontier = next_frontier
			var v = 0
			var temp_comp = comp_mask
			while temp_comp > 0:
				var bit = 0
				while (temp_comp & (1 << bit)) == 0: bit += 1
				v += 1
				if (new_armor & (1 << bit)) != 0: v += 1
				temp_comp &= ~(1 << bit)
			sizes.append(v)
			remaining_check &= ~comp_mask
			
		var big_piles = 0
		var ones_count = 0
		var nim_sum = 0
		for s in sizes:
			nim_sum ^= s
			if s > 1: big_piles += 1
			else: ones_count += 1
			
		# KOMUT 1: Sadece tekli taşlar kalıyorsa ve sayısı TEK ise kesin kazanırız.
		var is_guaranteed_win = false
		if big_piles == 0 and ones_count % 2 == 1:
			if current_level != 7: return move
			else: is_guaranteed_win = true
			
		# KOMUT 2: Birden fazla büyük grup varsa ve Nim-Sum 0 ise kesin kazanırız. (Örn: [2, 2] bırakmak)
		elif big_piles > 1 and nim_sum == 0:
			if current_level != 7: return move
			else: is_guaranteed_win = true
		# ------------------------------------
		
		var score = 0.0
		if is_guaranteed_win:
			score = 0.8
		else:
			score = minimax(new_state, new_armor, max_depth - 1, alpha, beta, false, new_special_uses, new_ultimate_uses)
		
		# Boss Desperation Mechanic: Eğer yapay zeka yenildiğini anlıyorsa, özel güçlerini harcamayı tercih eder!
		if score < -0.5:
			if is_ultimate_used: score += 0.5
			elif is_special_used: score += 0.3
			
		# Kibir Mekaniği (Sadece Level 7): Boss gösteriş yapmak için mükemmel stratejiyi feda edip özelliklerini GÖZÜ KAPALI kullanır!
		if current_level == 7:
			if is_ultimate_used: score += 10.0 + randf() # Nihai Atağı kesin ve rastgele bir yere atar! (Oyuncuya kazanma şansı doğar)
			elif is_special_used: score += 5.0 + randf() # L'leri kesin ve rastgele atar!
			
		if score > best_score:
			best_score = score
			best_moves = [move]
		elif score == best_score:
			best_moves.append(move)
			
		alpha = max(alpha, best_score)
			
	# Level 7 Yorgunluk Mekaniği: Boss o kadar şov yaptıktan sonra BİTKİN düşer! %40 ihtimalle mükemmel hamleyi göremez ve rastgele, saçma sapan bir hata yapar!
	if current_level == 7 and special_uses == 0 and ultimate_uses == 0:
		if randf() < 0.40:
			print("Zürafa Boss YORULDU ve hata yaptı!")
			return all_moves[randi() % all_moves.size()]
			
	return best_moves[randi() % best_moves.size()]

func minimax(board_state: int, armor_state: int, depth: int, alpha: float, beta: float, is_ai_turn: bool, special_uses: int, ultimate_uses: int) -> float:
	var original_alpha = alpha
	var original_beta = beta
	search_node_count += 1
	if board_state == 0:
		return (1.0 + depth * 0.01) if is_ai_turn else -(1.0 + depth * 0.01)
	if depth <= 0 or search_node_count > 200000:
		var remaining = board_state
		var sizes = []
		while remaining > 0:
			var i = 0
			while (remaining & (1 << i)) == 0:
				i += 1
			var comp_mask = (1 << i)
			var frontier = comp_mask
			while frontier > 0:
				var next_frontier = 0
				var temp = frontier
				while temp > 0:
					var bit = 0
					while (temp & (1 << bit)) == 0: bit += 1
					next_frontier |= (adj_masks[bit] & remaining)
					temp &= ~(1 << bit)
				next_frontier &= ~comp_mask
				comp_mask |= next_frontier
				frontier = next_frontier
			var v = 0
			var temp_comp = comp_mask
			while temp_comp > 0:
				var bit = 0
				while (temp_comp & (1 << bit)) == 0: bit += 1
				v += 1
				if (armor_state & (1 << bit)) != 0: v += 1
				temp_comp &= ~(1 << bit)
			sizes.append(v)
			remaining &= ~comp_mask
		var max_size = 0
		var nim_sum = 0
		for s in sizes:
			if s > max_size: max_size = s
			nim_sum ^= s
		var score_val = 0.0
		if max_size <= 1:
			score_val = 0.8 if sizes.size() % 2 == 0 else -0.8
		else:
			score_val = 0.8 if nim_sum != 0 else -0.8
			
		var ai_perspective = score_val if is_ai_turn else -score_val
		if current_level == 7:
			ai_perspective -= 0.05 * special_uses
			ai_perspective -= 0.05 * ultimate_uses
		else:
			ai_perspective += 0.001 * special_uses
			ai_perspective += 0.001 * ultimate_uses
		
		var stones_count = 0
		var temp_rem = board_state
		while temp_rem > 0:
			stones_count += temp_rem & 1
			temp_rem >>= 1
		ai_perspective += 0.005 * stones_count
		
		ai_perspective += randf_range(-0.0001, 0.0001)
		return ai_perspective
		
	var key = board_state | (armor_state << 35) | ((1 if is_ai_turn else 0) << 60) | (special_uses << 61) | (ultimate_uses << 63)
	if memo.has(key):
		var stored = memo[key]
		if stored.depth >= depth:
			if stored.bound == 0: return stored.score
			elif stored.bound == 1: alpha = max(alpha, stored.score)
			elif stored.bound == -1: beta = min(beta, stored.score)
			if alpha >= beta: return stored.score
		
	var available_moves = []
	for m in normal_move_masks:
		if (board_state & m) == m: available_moves.append(m)
		
	for i in range(bomb_move_masks.size()):
		var b_id = bomb_stone_ids[i]
		if (board_state & (1 << b_id)) != 0:
			available_moves.append(board_state & bomb_move_masks[i])
			
	var special_moves = []
	if is_ai_turn and special_uses > 0:
		for m in l_move_masks:
			if (board_state & m) == m: special_moves.append(m)
			
	var ultimate_moves = []
	if is_ai_turn and ultimate_uses > 0:
		for m in ultimate_move_masks:
			if (board_state & m) == m: ultimate_moves.append(m)
			
	var all_moves = available_moves.duplicate()
	all_moves.append_array(special_moves)
	all_moves.append_array(ultimate_moves)
	
	if is_ai_turn:
		var max_eval: float = -9999.0
		for move in all_moves:
			var hit_armored = move & armor_state
			var destroyed = move & ~armor_state
			var new_state = board_state & ~destroyed
			var new_armor = armor_state & ~hit_armored
			
			var is_special_used = special_uses > 0 and special_moves.has(move)
			var new_special_uses = special_uses - 1 if is_special_used else special_uses
			var is_ultimate_used = ultimate_uses > 0 and ultimate_moves.has(move)
			var new_ultimate_uses = ultimate_uses - 1 if is_ultimate_used else ultimate_uses
			
			var eval = minimax(new_state, new_armor, depth - 1, alpha, beta, false, new_special_uses, new_ultimate_uses)
			max_eval = max(max_eval, eval)
			alpha = max(alpha, eval)
			if beta <= alpha:
				break
		var bound = 0
		if max_eval <= original_alpha: bound = -1
		elif max_eval >= original_beta: bound = 1
		memo[key] = {"depth": depth, "score": max_eval, "bound": bound}
		return max_eval
	else:
		var min_eval: float = 9999.0
		for move in all_moves:
			var hit_armored = move & armor_state
			var destroyed = move & ~armor_state
			var new_state = board_state & ~destroyed
			var new_armor = armor_state & ~hit_armored
			
			var eval = minimax(new_state, new_armor, depth - 1, alpha, beta, true, special_uses, ultimate_uses)
			min_eval = min(min_eval, eval)
			beta = min(beta, eval)
			if beta <= alpha:
				break
		var bound = 0
		if min_eval <= original_alpha: bound = -1
		elif min_eval >= original_beta: bound = 1
		memo[key] = {"depth": depth, "score": min_eval, "bound": bound}
		return min_eval
