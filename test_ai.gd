extends SceneTree

func _init():
	var gm = preload("res://Scripts/GameManager.gd").new()
	gm.current_level = 5
	var s1 = Node2D.new(); s1.row_index = 1; s1.col_index = 1
	var s2 = Node2D.new(); s2.row_index = 2; s2.col_index = 0
	var s3 = Node2D.new(); s3.row_index = 2; s3.col_index = 1
	gm.all_stones = [s1, s2, s3]
	gm.generate_all_move_masks()
	
	var board_state = 7 # bits 0, 1, 2
	var armor_state = 0
	var max_depth = 12
	var special_uses = 0
	
	var best_move = gm.get_best_move_mask(board_state, armor_state, max_depth, special_uses)
	print("BEST MOVE MASK: ", best_move)
	quit()
