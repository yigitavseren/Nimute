extends Node2D

var stone_scene = preload("res://Scenes/Stone.tscn")
var all_stones = []
var selected_stones = []
var current_turn = "Player"
var selection_mode = "none"
var ai_special_uses_left = 0
var ai_ultimate_uses_left = 0
var current_level: int = 1

var normal_move_masks = []
var l_move_masks = []
var ai_diagonal_move_masks = []
var ultimate_move_masks = []
var memo = {}

var special_moves = []
var bomb_stones = []
var bomb_move_masks = []
var bomb_stone_ids = []
var adj_masks = []

var armored_stone_ids = []
var current_armor_state: int = 0
var lily_pad_ids = []
var lily_pad_queue = []
var lifebuoy_ids = []
var piranha_ids = []

var player_special_uses_left: int = 0

func _ready():
	$EndTurnButton.pressed.connect(end_turn)
	$MainMenuButton.pressed.connect(show_main_menu)
	$HUD/FastForwardButton.toggled.connect(func(pressed): Engine.time_scale = 4.0 if pressed else 1.0)
	$HUD/ToggleLMoveButton.toggled.connect(func(pressed):
		for s in selected_stones: s.deselect()
		selected_stones.clear()
		validate_selection()
	)
	$LevelSelectUI/Panel/Part1Button.pressed.connect(func():
		$LevelSelectUI/Panel/Part1LevelButtons.show()
		$LevelSelectUI/Panel/Part2LevelButtons.hide()
		$LevelSelectUI/Panel/Part1Button.hide()
		$LevelSelectUI/Panel/Part2Button.hide()
	)
	$LevelSelectUI/Panel/Part2Button.pressed.connect(func():
		$LevelSelectUI/Panel/Part2LevelButtons.show()
		$LevelSelectUI/Panel/Part1LevelButtons.hide()
		$LevelSelectUI/Panel/Part1Button.hide()
		$LevelSelectUI/Panel/Part2Button.hide()
	)
	$LevelSelectUI/Panel/Part1LevelButtons/BackButton.pressed.connect(func():
		$LevelSelectUI/Panel/Part1LevelButtons.hide()
		$LevelSelectUI/Panel/Part1Button.show()
		$LevelSelectUI/Panel/Part2Button.show()
	)
	$LevelSelectUI/Panel/Part2LevelButtons/BackButton2.pressed.connect(func():
		$LevelSelectUI/Panel/Part2LevelButtons.hide()
		$LevelSelectUI/Panel/Part1Button.show()
		$LevelSelectUI/Panel/Part2Button.show()
	)
	$LevelSelectUI/Panel/Part1LevelButtons/Level1Button.pressed.connect(func(): start_level(1))
	$LevelSelectUI/Panel/Part1LevelButtons/Level2Button.pressed.connect(func(): start_level(2))
	$LevelSelectUI/Panel/Part1LevelButtons/Level3Button.pressed.connect(func(): start_level(3))
	$LevelSelectUI/Panel/Part1LevelButtons/Level4Button.pressed.connect(func(): start_level(4))
	$LevelSelectUI/Panel/Part1LevelButtons/Level5Button.pressed.connect(func(): start_level(5))
	$LevelSelectUI/Panel/Part1LevelButtons/Level6Button.pressed.connect(func(): start_level(6))
	$LevelSelectUI/Panel/Part1LevelButtons/Level7Button.pressed.connect(func(): start_level(7))
	
	$LevelSelectUI/Panel/Part2LevelButtons/Level8Button.pressed.connect(func(): start_level(8))
	$LevelSelectUI/Panel/Part2LevelButtons/Level9Button.pressed.connect(func(): start_level(9))
	$LevelSelectUI/Panel/Part2LevelButtons/Level10Button.pressed.connect(func(): start_level(10))
	
	if has_node("LevelSelectUI/Panel/Part2LevelButtons/Level11Button"):
		get_node("LevelSelectUI/Panel/Part2LevelButtons/Level11Button").pressed.connect(func(): start_level(11))
	else:
		var l11 = Button.new()
		l11.text = "Level 4: Piranha"
		l11.name = "Level11Button"
		l11.add_theme_font_size_override("font_size", 24)
		l11.position = Vector2(100, 210)
		l11.size = Vector2(250, 40)
		l11.pressed.connect(func(): start_level(11))
		$LevelSelectUI/Panel/Part2LevelButtons.add_child(l11)
		
	if has_node("LevelSelectUI/Panel/Part2LevelButtons/Level12Button"):
		get_node("LevelSelectUI/Panel/Part2LevelButtons/Level12Button").pressed.connect(func(): start_level(12))
	else:
		var l12 = Button.new()
		l12.text = "Level 5: Deniz Sefası"
		l12.name = "Level12Button"
		l12.add_theme_font_size_override("font_size", 24)
		l12.position = Vector2(100, 260)
		l12.size = Vector2(250, 40)
		l12.pressed.connect(func(): start_level(12))
		$LevelSelectUI/Panel/Part2LevelButtons.add_child(l12)
		
	if has_node("LevelSelectUI/Panel/Part2LevelButtons/Level13Button"):
		get_node("LevelSelectUI/Panel/Part2LevelButtons/Level13Button").pressed.connect(func(): start_level(13))
	else:
		var l13 = Button.new()
		l13.text = "Level 6: Bombala"
		l13.name = "Level13Button"
		l13.add_theme_font_size_override("font_size", 24)
		l13.position = Vector2(100, 310)
		l13.size = Vector2(250, 40)
		l13.pressed.connect(func(): start_level(13))
		$LevelSelectUI/Panel/Part2LevelButtons.add_child(l13)
	
	# Bütün level butonlarını ortala ve boyutlarını eşitle
	var btn_w = 260
	var p_width = 400
	for p in [$LevelSelectUI/Panel/Part1LevelButtons, $LevelSelectUI/Panel/Part2LevelButtons]:
		for btn in p.get_children():
			if btn is Button and not btn.name.begins_with("Back"):
				btn.size.x = btn_w
				btn.position.x = (p_width - btn_w) / 2.0
	
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
	
	$LevelSelectUI/Panel/Part1Button.add_theme_stylebox_override("normal", title_normal)
	$LevelSelectUI/Panel/Part1Button.add_theme_stylebox_override("hover", title_hover)
	
	var title2_normal = btn_normal.duplicate()
	title2_normal.bg_color = Color(0.3, 0.6, 0.8) # Light blue
	var title2_hover = title2_normal.duplicate()
	title2_hover.bg_color = Color(0.4, 0.7, 0.9)
	
	$LevelSelectUI/Panel/Part2Button.add_theme_stylebox_override("normal", title2_normal)
	$LevelSelectUI/Panel/Part2Button.add_theme_stylebox_override("hover", title2_hover)
	
	for btn in $LevelSelectUI/Panel/Part1LevelButtons.get_children():
		if btn is Button:
			btn.add_theme_stylebox_override("normal", btn_normal)
			btn.add_theme_stylebox_override("hover", btn_hover)
			
	for btn in $LevelSelectUI/Panel/Part2LevelButtons.get_children():
		if btn is Button:
			btn.add_theme_stylebox_override("normal", btn_normal)
			btn.add_theme_stylebox_override("hover", btn_hover)
			
	var back_normal = btn_normal.duplicate()
	back_normal.bg_color = Color(0.6, 0.2, 0.2)
	var back_hover = back_normal.duplicate()
	back_hover.bg_color = Color(0.8, 0.3, 0.3)
	$LevelSelectUI/Panel/Part1LevelButtons/BackButton.add_theme_stylebox_override("normal", back_normal)
	$LevelSelectUI/Panel/Part1LevelButtons/BackButton.add_theme_stylebox_override("hover", back_hover)
	$LevelSelectUI/Panel/Part2LevelButtons/BackButton2.add_theme_stylebox_override("normal", back_normal)
	$LevelSelectUI/Panel/Part2LevelButtons/BackButton2.add_theme_stylebox_override("hover", back_hover)
	# -----------------
	
	show_main_menu()

func show_main_menu():
	$LevelSelectUI.show()
	$LevelSelectUI/Panel/Part1Button.show()
	$LevelSelectUI/Panel/Part2Button.show()
	$LevelSelectUI/Panel/Part1LevelButtons.hide()
	$LevelSelectUI/Panel/Part2LevelButtons.hide()
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
	
	for q in lily_pad_queue:
		if is_instance_valid(q.label_node): q.label_node.queue_free()
	lily_pad_queue.clear()
	lily_pad_ids.clear()
	lifebuoy_ids.clear()
	piranha_ids.clear()
	selection_mode = "none"
	current_turn = "Player"
	$EndTurnButton.disabled = false
	
	if current_level == 9 or current_level >= 10:
		$Background.color = Color(0.05, 0.4, 0.6) # Okyanus Mavisi
	else:
		$Background.color = Color(0.08, 0.08, 0.08) # Varsayılan koyu gri
		
	if has_node("HUD/PiranhaSign"):
		get_node("HUD/PiranhaSign").queue_free()
		
	if current_level >= 11:
		var sign_panel = PanelContainer.new()
		sign_panel.name = "PiranhaSign"
		sign_panel.position = Vector2(20, 100)
		var s_style = StyleBoxFlat.new()
		s_style.bg_color = Color(0.35, 0.2, 0.1)
		s_style.border_width_left = 4
		s_style.border_width_right = 4
		s_style.border_width_top = 4
		s_style.border_width_bottom = 4
		s_style.border_color = Color(0.15, 0.08, 0.04)
		sign_panel.add_theme_stylebox_override("panel", s_style)
		var sign_lbl = Label.new()
		sign_lbl.text = " DİKKAT! \n Bu sularda \n PİRANA \n çıkabilir! >:< "
		sign_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sign_lbl.add_theme_font_size_override("font_size", 20)
		sign_lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		sign_panel.add_child(sign_lbl)
		$HUD.add_child(sign_panel)
	
	if current_level >= 8: player_special_uses_left = 1
	else: player_special_uses_left = 0
	
	if current_level >= 4 and current_level <= 7: ai_special_uses_left = 2
	elif current_level < 4: ai_special_uses_left = 1
	else: ai_special_uses_left = 2 
	
	if current_level == 7: ai_ultimate_uses_left = 1
	else: ai_ultimate_uses_left = 0
	
	if current_level == 7 or current_level >= 8:
		$Board.scale = Vector2(0.85, 0.85)
	else:
		$Board.scale = Vector2(1.0, 1.0)
		
	if current_level >= 8:
		$HUD/AILabel.text = "Düşman: Yelkenci\nÇapraz Hakkı: 2"
		$HUD/ToggleLMoveButton.show()
		$HUD/ToggleLMoveButton.button_pressed = false
		$HUD/ToggleLMoveButton.text = "L Hamlesi Kullan (1 Kaldı)"
		$HUD/ToggleLMoveButton.disabled = false
	else:
		$HUD/ToggleLMoveButton.hide()
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
			
	elif current_level == 8:
		# Level 8 (Kısım 2 - Level 1): Yelkenci (Çapraz Harita) - 56 Taş (Duble)
		var start_y = -100 # Shifted up slightly to center the double height
		var start_x = 0
		var base_coords = [
			# Center column (c = 0)
			Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0),
			
			# Left side
			Vector2(0, -1), # c = -1
			Vector2(-1, -2), Vector2(0, -2), Vector2(1, -2), # c = -2
			Vector2(-2, -3), Vector2(-1, -3), Vector2(0, -3), Vector2(1, -3), Vector2(2, -3), # c = -3
			Vector2(-1, -4), Vector2(0, -4), Vector2(1, -4), # c = -4
			Vector2(0, -5), # c = -5
			
			# Right side
			Vector2(0, 1), # c = 1
			Vector2(-1, 2), Vector2(0, 2), Vector2(1, 2), # c = 2
			Vector2(-2, 3), Vector2(-1, 3), Vector2(0, 3), Vector2(1, 3), Vector2(2, 3), # c = 3
			Vector2(-1, 4), Vector2(0, 4), Vector2(1, 4), # c = 4
			Vector2(0, 5) # c = 5
		]
		
		var coords = []
		for pos in base_coords:
			if not coords.has(pos):
				coords.append(pos)
			
			var bottom_pos = pos + Vector2(4, 0)
			if not coords.has(bottom_pos):
				coords.append(bottom_pos)
		
		for pos in coords:
			spawn_stone(int(pos.x), int(pos.y), start_x + pos.y * 50, start_y + pos.x * 50)
			
	elif current_level == 9:
		# Level 9 (Kısım 2 - Level 2): Okyanus & Nilüfer Yaprakları
		var start_y = 0
		var start_x = 0
		var grid_size = 55
		
		var bomb_coords = [Vector2(0, -6), Vector2(0, 6)]
		var armored_coords = [
			Vector2(-2, -3), Vector2(-1, -3), Vector2(1, -3), Vector2(2, -3),
			Vector2(-2, 3), Vector2(-1, 3), Vector2(1, 3), Vector2(2, 3)
		]
		var lily_coords = [
			Vector2(-2, -4), Vector2(-2, -2), Vector2(2, -4), Vector2(2, -2),
			Vector2(0, 0),
			Vector2(-2, 2), Vector2(-2, 4), Vector2(2, 2), Vector2(2, 4)
		]
		var white_coords = [
			Vector2(0, -7), Vector2(-1, -6), Vector2(1, -6),
			Vector2(-2, -5), Vector2(-1, -5), Vector2(0, -5), Vector2(1, -5), Vector2(2, -5),
			Vector2(0, 7), Vector2(-1, 6), Vector2(1, 6),
			Vector2(-2, 5), Vector2(-1, 5), Vector2(0, 5), Vector2(1, 5), Vector2(2, 5)
		]
		
		var all_c = []
		all_c.append_array(bomb_coords)
		all_c.append_array(armored_coords)
		all_c.append_array(lily_coords)
		all_c.append_array(white_coords)
		
		for pos in all_c:
			var s = spawn_stone(int(pos.x), int(pos.y), start_x + pos.y * grid_size, start_y + pos.x * grid_size)
			if bomb_coords.has(pos):
				make_bomb(s)
			elif armored_coords.has(pos):
				make_armored(s)
			elif lily_coords.has(pos):
				lily_pad_ids.append(all_stones.size() - 1)
				s.set_type("lily_pad")

	elif current_level == 10:
		var start_y = 0
		var start_x = 0
		var grid_size = 65
		
		var l10_armored = []
		var l10_bomb = []
		var l10_lily = []
		var l10_lifebuoy = []
		var l10_white = []
		
		# Sol Haç (Merkez: -4, 0)
		l10_white.append_array([Vector2(-4, -2), Vector2(-4, -1)])
		l10_white.append(Vector2(-5, 0))
		l10_lifebuoy.append(Vector2(-4, 0))
		l10_white.append(Vector2(-3, 0))
		l10_armored.append_array([Vector2(-4, 1), Vector2(-4, 2), Vector2(-4, 3)])
		
		# Sağ Haç (Merkez: 4, 0)
		l10_armored.append_array([Vector2(4, -3), Vector2(4, -2), Vector2(4, -1)])
		l10_white.append(Vector2(3, 0))
		l10_lifebuoy.append(Vector2(4, 0))
		l10_white.append(Vector2(5, 0))
		l10_white.append_array([Vector2(4, 1), Vector2(4, 2)])
		
		# Merkez Elmas
		l10_lily.append(Vector2(0, -3))
		l10_white.append_array([Vector2(-1, -2), Vector2(1, -2)])
		l10_lily.append(Vector2(0, -2))
		l10_white.append_array([Vector2(-2, -1), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), Vector2(2, -1)])
		
		l10_lifebuoy.append(Vector2(-2, 0))
		l10_white.append(Vector2(-1, 0))
		l10_bomb.append(Vector2(0, 0))
		l10_white.append(Vector2(1, 0))
		l10_lifebuoy.append(Vector2(2, 0))
		
		l10_white.append_array([Vector2(-2, 1), Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1), Vector2(2, 1)])
		l10_white.append_array([Vector2(-1, 2), Vector2(1, 2)])
		l10_lily.append(Vector2(0, 2))
		l10_lily.append(Vector2(0, 3))
		
		var all_c = []
		all_c.append_array(l10_armored)
		all_c.append_array(l10_bomb)
		all_c.append_array(l10_lily)
		all_c.append_array(l10_lifebuoy)
		all_c.append_array(l10_white)
		
		for pos in all_c:
			var s = spawn_stone(int(pos.x), int(pos.y), start_x + pos.x * grid_size, start_y + pos.y * grid_size)
			if l10_bomb.has(pos):
				make_bomb(s)
			elif l10_armored.has(pos):
				make_armored(s)
			elif l10_lily.has(pos):
				lily_pad_ids.append(all_stones.size() - 1)
				s.set_type("lily_pad")
			elif l10_lifebuoy.has(pos):
				lifebuoy_ids.append(all_stones.size() - 1)
				s.set_type("lifebuoy")

	elif current_level == 11:
		var start_y = 0
		var start_x = 0
		var grid_size = 65
		
		var l11_white = []
		var l11_armored = []
		var l11_lily = []
		
		# Center column
		l11_white.append_array([Vector2(0, -1), Vector2(0, -2), Vector2(0, -3), Vector2(0, 0), Vector2(0, 1), Vector2(0, 2)])
		l11_armored.append_array([Vector2(0, -4), Vector2(0, -5), Vector2(0, -6)])
		l11_armored.append_array([Vector2(0, 3), Vector2(0, 4), Vector2(0, 5), Vector2(-1, 4), Vector2(1, 4)])
		
		# Left branch
		l11_white.append_array([Vector2(-1, 0), Vector2(-2, 0), Vector2(-3, 0), Vector2(-3, -1), Vector2(-3, -2)])
		l11_armored.append_array([Vector2(-3, -3), Vector2(-4, -3), Vector2(-4, -2)])
		
		# Right branch
		l11_white.append_array([Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(3, -1), Vector2(3, -2)])
		l11_armored.append_array([Vector2(3, -3), Vector2(4, -3), Vector2(4, -2)])
		
		# Lily pads
		l11_lily.append_array([Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)])
		
		var all_c = []
		all_c.append_array(l11_white)
		all_c.append_array(l11_armored)
		all_c.append_array(l11_lily)
		
		for pos in all_c:
			var s = spawn_stone(int(pos.x), int(pos.y), start_x + pos.x * grid_size, start_y + pos.y * grid_size)
			if l11_armored.has(pos):
				make_armored(s)
			elif l11_lily.has(pos):
				lily_pad_ids.append(all_stones.size() - 1)
				s.set_type("lily_pad")

	elif current_level == 12:
		var start_y = 0
		var start_x = 0
		var grid_size = 50
		
		var l12_white = []
		var l12_armored = []
		var l12_bomb = []
		
		# Sol Küme (Bomba ve Beyazlar) Merkez: (-7, 0)
		l12_bomb.append(Vector2(-7, 0))
		l12_white.append_array([Vector2(-7, -1), Vector2(-7, 1), Vector2(-8, 0), Vector2(-6, 0)])
		
		# Sağ Üst Küme (Tamamı Zırhlı) Merkez: (7, -4)
		l12_armored.append_array([Vector2(7, -4), Vector2(7, -5), Vector2(7, -3), Vector2(6, -4), Vector2(8, -4)])
		
		# Sağ Alt Küme (Beyazlar ve Can Simidi) Merkez: (7, 4)
		l12_white.append_array([Vector2(7, 4), Vector2(7, 3), Vector2(7, 5), Vector2(6, 4), Vector2(8, 4)])
		# (6,4) ve (7,4) kırmızı çizgi (Can Simidi) -> döngüden sonra ayarlayacağız.
		
		# Merkez Şekil 
		# Elmas Üst Kısım
		l12_white.append_array([Vector2(0, -4), Vector2(-1, -3), Vector2(1, -3), Vector2(0, -2)])
		
		# İç Zırhlılar
		l12_armored.append_array([Vector2(0, 0), Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)])
		
		# Sol Dikey Sütun (x = -2)
		l12_white.append_array([Vector2(-2, -2), Vector2(-2, -1), Vector2(-2, 0), Vector2(-2, 1), Vector2(-2, 2), Vector2(-2, 3), Vector2(-2, 4)])
		
		# Sağ Dikey Sütun (x = 2)
		l12_white.append_array([Vector2(2, -2), Vector2(2, -1), Vector2(2, 0), Vector2(2, 1), Vector2(2, 2), Vector2(2, 3), Vector2(2, 4)])
		
		# Sol Kanat
		l12_white.append_array([Vector2(-3, -2), Vector2(-3, -3), Vector2(-4, -3)])
		
		# Sağ Kanat
		l12_white.append_array([Vector2(3, -2), Vector2(3, -3), Vector2(4, -3)])
		
		var all_c = []
		all_c.append_array(l12_white)
		all_c.append_array(l12_armored)
		all_c.append_array(l12_bomb)
		
		for pos in all_c:
			var s = spawn_stone(int(pos.x), int(pos.y), start_x + pos.x * grid_size, start_y + pos.y * grid_size)
			if l12_armored.has(pos):
				make_armored(s)
			elif l12_bomb.has(pos):
				make_bomb(s)
				
		# Can simitlerini oluştur (ID bulmamız gerektiği için hepsi oluştuktan sonra)
		
		# Sağ Alt Küme: Sadece tam ortadaki (7, 4) can simidi olacak
		var lb_center = get_stone_at_full(7, 4)
		if lb_center:
			lifebuoy_ids.append(all_stones.find(lb_center))
			lb_center.set_type("lifebuoy")
			
		# Merkez Şekil Can Simitleri: Sadece kırmızı çizgili Beyaz taşlar
		var center_lbs = [Vector2(-2, -1), Vector2(-2, 1), Vector2(2, -1), Vector2(2, 1)]
		for pos in center_lbs:
			var s = get_stone_at_full(int(pos.x), int(pos.y))
			if s:
				lifebuoy_ids.append(all_stones.find(s))
				s.set_type("lifebuoy")

	elif current_level == 13:
		var start_y = 0
		var start_x = 0
		var grid_size = 45
		
		var l13_white = []
		var l13_bomb = []
		
		# Merkez ve İç Haç (Tamamı Beyaz, sadece merkez Bomba)
		l13_bomb.append(Vector2(0, 0))
		l13_white.append_array([Vector2(0, -1), Vector2(0, -2), Vector2(0, 1), Vector2(0, 2), Vector2(-1, 0), Vector2(-2, 0), Vector2(1, 0), Vector2(2, 0)])
		
		# Kare Üst Kenar (y=-3)
		l13_white.append_array([Vector2(-3, -3), Vector2(-1, -3), Vector2(1, -3), Vector2(3, -3)])
		l13_bomb.append_array([Vector2(-2, -3), Vector2(0, -3), Vector2(2, -3)])
		
		# Kare Alt Kenar (y=3)
		l13_white.append_array([Vector2(-3, 3), Vector2(-1, 3), Vector2(1, 3), Vector2(3, 3)])
		l13_bomb.append_array([Vector2(-2, 3), Vector2(0, 3), Vector2(2, 3)])
		
		# Kare Sol Kenar İç Kısmı (x=-3)
		l13_white.append_array([Vector2(-3, -1), Vector2(-3, 1)])
		l13_bomb.append_array([Vector2(-3, -2), Vector2(-3, 0), Vector2(-3, 2)])
		
		# Kare Sağ Kenar İç Kısmı (x=3)
		l13_white.append_array([Vector2(3, -1), Vector2(3, 1)])
		l13_bomb.append_array([Vector2(3, -2), Vector2(3, 0), Vector2(3, 2)])
		
		# Dış Kollar (5 birim uzaklıkta sonlanan bombalar ve çengeller)
		l13_white.append_array([Vector2(0, -4), Vector2(-1, -5)]) # Üst kol
		l13_bomb.append(Vector2(0, -5))
		
		l13_white.append_array([Vector2(0, 4), Vector2(1, 5)]) # Alt kol
		l13_bomb.append(Vector2(0, 5))
		
		l13_white.append_array([Vector2(-4, 0), Vector2(-5, 1)]) # Sol kol
		l13_bomb.append(Vector2(-5, 0))
		
		l13_white.append_array([Vector2(4, 0), Vector2(5, -1)]) # Sağ kol
		l13_bomb.append(Vector2(5, 0))
		
		var all_c = []
		all_c.append_array(l13_white)
		all_c.append_array(l13_bomb)
		
		for pos in all_c:
			var s = spawn_stone(int(pos.x), int(pos.y), start_x + pos.x * grid_size, start_y + pos.y * grid_size)
			if l13_bomb.has(pos):
				make_bomb(s)

	if current_level >= 11:
		spawn_piranhas()
		
	generate_all_move_masks()

func spawn_stone(r, c, x, y):
	var stone = stone_scene.instantiate()
	stone.position = Vector2(x, y)
	stone.row_index = r
	stone.col_index = c
	stone.stone_clicked.connect(_on_stone_clicked)
	$Board.add_child(stone)
	all_stones.append(stone)
	return stone

func spawn_piranhas():
	var num_piranhas = 4 if current_level >= 13 else ((randi() % 2) + 1)
	
	var candidates = []
	for i in range(all_stones.size()):
		var s = all_stones[i]
		if bomb_stones.has(s) or armored_stone_ids.has(i) or lifebuoy_ids.has(i) or lily_pad_ids.has(i):
			continue
		var neighbors = 0
		for dir in [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1), Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)]:
			var neighbor = get_stone_at_full(s.row_index + int(dir.x), s.col_index + int(dir.y))
			if neighbor and is_instance_valid(neighbor) and not neighbor.is_queued_for_deletion():
				neighbors += 1
		candidates.append({"index": i, "density": neighbors})
		
	candidates.sort_custom(func(a, b): return a.density > b.density)
	
	var top_candidates = candidates.slice(0, min(5, candidates.size()))
	top_candidates.shuffle()
	
	for i in range(min(num_piranhas, top_candidates.size())):
		var idx = top_candidates[i].index
		piranha_ids.append(idx)
		all_stones[idx].set_type("piranha")

func make_bomb(stone):
	bomb_stones.append(stone)
	stone.set_type("bomb")

func make_armored(stone):
	var id = all_stones.find(stone)
	armored_stone_ids.append(id)
	current_armor_state |= (1 << id)
	stone.set_type("armored")

func build_adj_masks():
	adj_masks.clear()
	for i in range(all_stones.size()):
		var mask = 0
		if not is_instance_valid(all_stones[i]) or all_stones[i].is_queued_for_deletion():
			adj_masks.append(0)
			continue
			
		var r_i = all_stones[i].row_index
		var c_i = all_stones[i].col_index
		for j in range(all_stones.size()):
			if i == j: continue
			if not is_instance_valid(all_stones[j]) or all_stones[j].is_queued_for_deletion(): continue
			
			var r_j = all_stones[j].row_index
			var c_j = all_stones[j].col_index
			if (r_i == r_j and abs(c_i - c_j) == 1) or (c_i == c_j and abs(r_i - r_j) == 1):
				mask |= (1 << j)
		adj_masks.append(mask)

func advance_timers():
	var still_waiting = []
	var respawned_any = false
	for lp in lily_pad_queue:
		lp.turns_left -= 1
		
		var display_turns = ceil(lp.turns_left / 2.0)
		if is_instance_valid(lp.label_node):
			lp.label_node.text = str(display_turns)
			
		if lp.turns_left <= 0:
			respawn_lily_pad(lp)
			respawned_any = true
			if is_instance_valid(lp.label_node): lp.label_node.queue_free()
		else:
			still_waiting.append(lp)
	lily_pad_queue = still_waiting
	if respawned_any:
		generate_all_move_masks()

func has_non_lily_pads() -> bool:
	for i in range(all_stones.size()):
		var s = all_stones[i]
		if is_instance_valid(s) and not s.is_queued_for_deletion():
			if not lily_pad_ids.has(i) and not piranha_ids.has(i):
				return true
	return false

func destroy_stone(stone, permanent=false):
	var s_idx = all_stones.find(stone)
	if lily_pad_ids.has(s_idx) and has_non_lily_pads() and not permanent:
		var lbl = Label.new()
		lbl.text = "2"
		lbl.position = stone.position - Vector2(10, 10)
		lbl.add_theme_color_override("font_color", Color(0.1, 0.8, 0.2)) # Green label
		$Board.add_child(lbl)
		lily_pad_queue.append({
			"index": s_idx,
			"row": stone.row_index,
			"col": stone.col_index,
			"x": stone.position.x,
			"y": stone.position.y,
			"turns_left": 4,
			"label_node": lbl
		})
	stone.queue_free()

func respawn_lily_pad(info):
	var s = stone_scene.instantiate()
	s.position = Vector2(info.x, info.y)
	s.row_index = info.row
	s.col_index = info.col
	s.stone_clicked.connect(_on_stone_clicked)
	s.set_type("lily_pad")
	$Board.add_child(s)
	all_stones[info.index] = s

func generate_all_move_masks():
	normal_move_masks.clear()
	ai_diagonal_move_masks.clear()
	special_moves.clear()
	bomb_move_masks.clear()
	bomb_stone_ids.clear()
	
	# Normal segmentler (Düz ve Çapraz)
	var normal_dirs = [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]
		
	for s in all_stones:
		if not is_instance_valid(s) or s.is_queued_for_deletion(): continue
		var s_idx = all_stones.find(s)
		if piranha_ids.has(s_idx) or (lifebuoy_ids.has(s_idx) and not is_lifebuoy_isolated(s_idx)): continue
		
		for d in normal_dirs:
			var current_seg = [s]
			var mask = (1 << s_idx)
			if not normal_move_masks.has(mask): normal_move_masks.append(mask)
				
			var r = s.row_index
			var c = s.col_index
			while true:
				r += int(d.x)
				c += int(d.y)
				var next_s = get_stone_at_full(r, c)
				if next_s and is_instance_valid(next_s) and not next_s.is_queued_for_deletion():
					var next_idx = all_stones.find(next_s)
					if piranha_ids.has(next_idx) or (lifebuoy_ids.has(next_idx) and not is_lifebuoy_isolated(next_idx)): break
					
					current_seg.append(next_s)
					mask |= (1 << all_stones.find(next_s))
					if not normal_move_masks.has(mask): normal_move_masks.append(mask)
				else:
					break
					
	if current_level >= 8:
		var diag_dirs = [Vector2(1,1), Vector2(-1,-1), Vector2(1,-1), Vector2(-1,1)]
		for s in all_stones:
			if not is_instance_valid(s) or s.is_queued_for_deletion(): continue
			var s_idx = all_stones.find(s)
			if piranha_ids.has(s_idx) or (lifebuoy_ids.has(s_idx) and not is_lifebuoy_isolated(s_idx)): continue
			
			for d in diag_dirs:
				var current_seg = [s]
				var mask = (1 << s_idx)
				var r = s.row_index
				var c = s.col_index
				while true:
					r += int(d.x)
					c += int(d.y)
					var next_s = get_stone_at_full(r, c)
					if next_s and is_instance_valid(next_s) and not next_s.is_queued_for_deletion():
						var next_idx = all_stones.find(next_s)
						if piranha_ids.has(next_idx) or (lifebuoy_ids.has(next_idx) and not is_lifebuoy_isolated(next_idx)): break
						
						current_seg.append(next_s)
						mask |= (1 << next_idx)
						if not ai_diagonal_move_masks.has(mask): ai_diagonal_move_masks.append(mask)
					else:
						break
					
	# L şekli segmentler
	var ortho_pairs = [
		[Vector2(1,0), Vector2(0,1)], [Vector2(1,0), Vector2(0,-1)],
		[Vector2(-1,0), Vector2(0,1)], [Vector2(-1,0), Vector2(0,-1)]
	]
	if current_level >= 8:
		# L move uses orthogonal components
		ortho_pairs = [
			[Vector2(1,0), Vector2(0,1)], [Vector2(1,0), Vector2(0,-1)],
			[Vector2(-1,0), Vector2(0,1)], [Vector2(-1,0), Vector2(0,-1)]
		]
		
	for corner in all_stones:
		if not is_instance_valid(corner) or corner.is_queued_for_deletion(): continue
		var corner_idx = all_stones.find(corner)
		if piranha_ids.has(corner_idx) or (lifebuoy_ids.has(corner_idx) and not is_lifebuoy_isolated(corner_idx)): continue
		
		for pair in ortho_pairs:
			var m1s = []
			var m1 = (1 << corner_idx)
			var r = corner.row_index
			var c = corner.col_index
			while true:
				r += int(pair[0].x)
				c += int(pair[0].y)
				var next_s = get_stone_at_full(r, c)
				if next_s and is_instance_valid(next_s) and not next_s.is_queued_for_deletion():
					var next_idx = all_stones.find(next_s)
					if piranha_ids.has(next_idx) or (lifebuoy_ids.has(next_idx) and not is_lifebuoy_isolated(next_idx)): break
					
					m1 |= (1 << next_idx)
					m1s.append(m1)
				else: break
				
			var m2s = []
			var m2 = (1 << all_stones.find(corner))
			r = corner.row_index
			c = corner.col_index
			while true:
				r += int(pair[1].x)
				c += int(pair[1].y)
				var next_s = get_stone_at_full(r, c)
				if next_s and is_instance_valid(next_s) and not next_s.is_queued_for_deletion():
					var next_idx = all_stones.find(next_s)
					if piranha_ids.has(next_idx) or (lifebuoy_ids.has(next_idx) and not is_lifebuoy_isolated(next_idx)): break
					
					m2 |= (1 << next_idx)
					m2s.append(m2)
				else: break
				
			for mask1 in m1s:
				for mask2 in m2s:
					var final_mask = mask1 | mask2
					if not l_move_masks.has(final_mask) and not normal_move_masks.has(final_mask):
						l_move_masks.append(final_mask)

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
	if piranha_ids.has(all_stones.find(stone)): return
	
	if stone.is_selected:
		stone.deselect()
		selected_stones.erase(stone)
		validate_selection()
		return
		
	if selected_stones.size() == 0 and bomb_stones.has(stone):
		detonate_bomb(stone)
		return
		
	stone.select()
	selected_stones.append(stone)
	validate_selection()


func validate_selection():
	var mask = 0
	for s in selected_stones:
		mask |= (1 << all_stones.find(s))
		
	var is_valid = false
	if mask == 0:
		is_valid = false
	elif normal_move_masks.has(mask):
		is_valid = true
	elif current_level >= 8 and player_special_uses_left > 0 and $HUD/ToggleLMoveButton.button_pressed:
		if l_move_masks.has(mask):
			is_valid = true
			
	$EndTurnButton.disabled = not is_valid
	if mask > 0 and not is_valid:
		$EndTurnButton.text = "Geçersiz Seçim!"
	else:
		$EndTurnButton.text = "Turu Bitir"

func end_turn():
	if selected_stones.size() == 0: return
	
	var mask = 0
	for s in selected_stones:
		mask |= (1 << all_stones.find(s))
		
	if current_level >= 8 and player_special_uses_left > 0 and $HUD/ToggleLMoveButton.button_pressed:
		if l_move_masks.has(mask):
			player_special_uses_left -= 1
			$HUD/ToggleLMoveButton.set_pressed_no_signal(false)
			$HUD/ToggleLMoveButton.text = "L Hamlesi Kullan (" + str(player_special_uses_left) + " Kaldı)"
			if player_special_uses_left == 0:
				$HUD/ToggleLMoveButton.disabled = true
		
	var to_free = []
	for stone in selected_stones:
		var s_id = all_stones.find(stone)
		if (current_armor_state & (1 << s_id)) != 0:
			current_armor_state &= ~(1 << s_id)
			stone.set_type("normal") # Zırh kırıldı, temeli beyaza dön
			stone.modulate = Color(1, 1, 1) # Beyaza dön
			stone.deselect()
		else:
			to_free.append(stone)
			
	for stone in to_free:
		if is_instance_valid(stone): destroy_stone(stone)
		
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
			s.set_type("normal") # Zırh kırıldı
			s.modulate = Color(1, 1, 1)
			s.deselect()
		else:
			destroy_stone(s)
			
	await get_tree().process_frame
	if check_win_condition(): return
	
	current_turn = "Enemy"
	play_enemy_turn()

func check_lifebuoy_sinks():
	pass # Can simitleri artık kendi kendine batmıyor.

func is_lifebuoy_isolated(s_idx: int) -> bool:
	var s = all_stones[s_idx]
	if not is_instance_valid(s) or s.is_queued_for_deletion(): return true
	for dir in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		var neighbor = get_stone_at_full(s.row_index + dir.x, s.col_index + dir.y)
		if neighbor and is_instance_valid(neighbor) and not neighbor.is_queued_for_deletion():
			var n_idx = all_stones.find(neighbor)
			if not lifebuoy_ids.has(n_idx) and not piranha_ids.has(n_idx):
				return false # Destek var, izole DEĞİL
	return true # Destek yok, izole!

func check_win_condition() -> bool:
	check_lifebuoy_sinks()
	
	var remaining = 0
	for i in range(all_stones.size()):
		var s = all_stones[i]
		if is_instance_valid(s) and not s.is_queued_for_deletion():
			if not piranha_ids.has(i):
				remaining += 1
		
	if remaining == 0:
		print(current_turn + " kaybetti! (Son taşı alan kaybeder)")
		$HUD/GameOverPanel.show()
		if current_turn == "Player":
			$HUD/GameOverPanel/GameOverLabel.text = "KAYBETTİN!\n(Son Taşı Alan Kaybeder)"
			$HUD/GameOverPanel/GameOverLabel.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		else:
			if current_level >= 8:
				$HUD/GameOverPanel/GameOverLabel.text = "KAZANDIN!\nYelkenci Kaybetti!"
			else:
				$HUD/GameOverPanel/GameOverLabel.text = "KAZANDIN!\nZürafa Kaybetti!"
			$HUD/GameOverPanel/GameOverLabel.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
		return true
	return false

func play_enemy_turn():
	$EndTurnButton.disabled = true
	await get_tree().create_timer(1.0).timeout
	if current_turn != "Enemy": return
	
	advance_timers()
	
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
		current_turn = "Piranha"
		play_piranha_turn()
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
		elif ai_special_uses_left > 0 and (l_move_masks.has(best_move_mask) or ai_diagonal_move_masks.has(best_move_mask)):
			ai_special_uses_left -= 1
			if current_level >= 8:
				$HUD/AILabel.text = "Düşman: Yelkenci\nÇapraz Hakkı: " + str(ai_special_uses_left)
				print("Yelkenci 'Çapraz' özel yeteneğini kullandı! (Kalan hak: ", ai_special_uses_left, ")")
			else:
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
				s.set_type("normal")
				s.modulate = Color(1, 1, 1)
				s.deselect()
		else:
			if is_instance_valid(s): destroy_stone(s)
			
	await get_tree().process_frame
	if check_win_condition(): return
	
	advance_timers()
	
	current_turn = "Piranha"
	play_piranha_turn()

var search_node_count: int = 0

func get_valid_prey() -> Array:
	var prey = []
	for i in range(all_stones.size()):
		var s = all_stones[i]
		if is_instance_valid(s) and not s.is_queued_for_deletion():
			if not piranha_ids.has(i) and not (lifebuoy_ids.has(i) and not is_lifebuoy_isolated(i)):
				prey.append(s)
	return prey

func get_stone_density(s) -> int:
	var count = 0
	var dirs = [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1), Vector2(1,1), Vector2(-1,-1), Vector2(1,-1), Vector2(-1,1)]
	for dir in dirs:
		var neighbor = get_stone_at_full(s.row_index + int(dir.x), s.col_index + int(dir.y))
		if neighbor and is_instance_valid(neighbor) and not neighbor.is_queued_for_deletion():
			count += 1
	return count

func play_piranha_turn():
	if current_level < 11 or piranha_ids.is_empty():
		end_piranha_turn()
		return
		
	print("Piranalar hareket ediyor!")
	var ate_anything = false
	var moved_anything = false
	
	for p_idx in piranha_ids:
		var piranha = all_stones[p_idx]
		if not is_instance_valid(piranha): continue
		
		var targets = []
		var dirs = [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1), Vector2(1,1), Vector2(-1,-1), Vector2(1,-1), Vector2(-1,1)]
		for dir in dirs:
			var target = get_stone_at_full(piranha.row_index + int(dir.x), piranha.col_index + int(dir.y))
			if target and is_instance_valid(target) and not target.is_queued_for_deletion():
				var t_idx = all_stones.find(target)
				if not piranha_ids.has(t_idx) and not (lifebuoy_ids.has(t_idx) and not is_lifebuoy_isolated(t_idx)):
					targets.append(target)
					
		if targets.size() > 0:
			targets.shuffle()
			var victim = targets[0]
			
			var target_pos = victim.position
			var target_r = victim.row_index
			var target_c = victim.col_index
			
			destroy_stone(victim, true) # Permanent kill
			ate_anything = true
			
			var tween = get_tree().create_tween()
			tween.tween_property(piranha, "position", target_pos, 0.3).set_trans(Tween.TRANS_SINE)
			piranha.row_index = target_r
			piranha.col_index = target_c
		else:
			# Pathfinding
			var all_prey = get_valid_prey()
			if all_prey.is_empty(): continue
			
			var min_dist = 9999
			var closest_prey = []
			
			for prey in all_prey:
				# Chebyshev distance for 8-way movement
				var dist = max(abs(piranha.row_index - prey.row_index), abs(piranha.col_index - prey.col_index))
				if dist < min_dist:
					min_dist = dist
					closest_prey = [prey]
				elif dist == min_dist:
					closest_prey.append(prey)
					
			if closest_prey.size() > 1:
				var max_density = -1
				var dense_prey = []
				for prey in closest_prey:
					var density = get_stone_density(prey)
					if density > max_density:
						max_density = density
						dense_prey = [prey]
					elif density == max_density:
						dense_prey.append(prey)
				closest_prey = dense_prey
				
			closest_prey.shuffle()
			var target_prey = closest_prey[0]
			
			var dr = target_prey.row_index - piranha.row_index
			var dc = target_prey.col_index - piranha.col_index
			
			var possible_moves = []
			if dr != 0 and dc != 0: possible_moves.append(Vector2(sign(dr), sign(dc)))
			if dr != 0: possible_moves.append(Vector2(sign(dr), 0))
			if dc != 0: possible_moves.append(Vector2(0, sign(dc)))
			
			if possible_moves.size() > 0:
				possible_moves.shuffle()
				var move = possible_moves[0]
				var new_r = piranha.row_index + int(move.x)
				var new_c = piranha.col_index + int(move.y)
				
				# Level 11 layout uses: x = r * 65, y = c * 65
				var target_pos = piranha.position + Vector2(move.x * 65, move.y * 65)
				
				var tween = get_tree().create_tween()
				tween.tween_property(piranha, "position", target_pos, 0.3).set_trans(Tween.TRANS_SINE)
				piranha.row_index = new_r
				piranha.col_index = new_c
				moved_anything = true
			
	if ate_anything or moved_anything:
		await get_tree().create_timer(0.5).timeout
		generate_all_move_masks()
		if check_win_condition(): return
		
	end_piranha_turn()

func end_piranha_turn():
	current_turn = "Player"
	$EndTurnButton.disabled = false
	print("Sıra sende!")

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
		if current_level >= 8:
			for m in ai_diagonal_move_masks:
				if (board_state & m) == m: special_moves.append(m)
		else:
			for m in l_move_masks:
				if (board_state & m) == m: special_moves.append(m)
			
	var ultimate_moves = []
	if ultimate_uses > 0:
		for m in ultimate_move_masks:
			if (board_state & m) == m: ultimate_moves.append(m)
			
	var all_moves = []
	if current_level == 7 or current_level == 8:
		# KESİN EMİR: Eğer Nihai Atak varsa, sadece Nihai Atakları düşün! L (veya Çapraz) varsa sadece onları düşün!
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
			if current_level != 7 and current_level < 8: return move
			else: is_guaranteed_win = true
			
		# KOMUT 2: Birden fazla büyük grup varsa ve Nim-Sum 0 ise kesin kazanırız. (Örn: [2, 2] bırakmak)
		elif big_piles > 1 and nim_sum == 0:
			if current_level != 7 and current_level != 8: return move
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
			
		# Kibir Mekaniği (Level 7 ve Level 8+): Boss gösteriş yapmak için mükemmel stratejiyi feda edip özelliklerini GÖZÜ KAPALI kullanır!
		if current_level == 7:
			if is_ultimate_used: score += 10.0 + randf() # Nihai Atağı kesin ve rastgele bir yere atar! (Oyuncuya kazanma şansı doğar)
			elif is_special_used: score += 5.0 + randf() # L'leri kesin ve rastgele atar!
		elif current_level >= 8:
			if is_special_used: score += 5.0 + randf() # Yelkenci çaprazları aktif olarak savurur! (Oyuncunun sinirini bozmak için)
			
		if score > best_score:
			best_score = score
			best_moves = [move]
		elif score == best_score:
			best_moves.append(move)
			
		alpha = max(alpha, best_score)
			
	# Level 7 ve 8+ Yorgunluk Mekaniği: Boss o kadar şov yaptıktan sonra BİTKİN düşer! %40 ihtimalle mükemmel hamleyi göremez ve rastgele, saçma sapan bir hata yapar!
	if (current_level == 7 or current_level >= 8) and special_uses == 0 and ultimate_uses == 0:
		if randf() < 0.40:
			print("Boss YORULDU ve hata yaptı!")
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
		if current_level >= 8:
			for m in ai_diagonal_move_masks:
				if (board_state & m) == m: special_moves.append(m)
		else:
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
