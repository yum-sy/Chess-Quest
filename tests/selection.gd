extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g)
	await process_frame
	g.learner.path="user://selection-test.json";g.learner.data.settings.sound=false;g.learner.data.settings.motion=false
	var fails=0;var count=0
	for viewport_size in [Vector2i(1280,800),Vector2i(720,1280)]:
		root.size=viewport_size;g.responsive()
		for index in [0,26,48,49,50,51,52,53]:
			g.start_mission(index);g.modal="";g.layout_board(g.size_now())
			g.board_view.update_position(g.rules.cells,-1,[],false,false)
			g.board_view.animate(0)
			await process_frame
			for i in g.board_view.pieces:
				var p=g.board_view.portrait_rect(i).get_center()
				if g.board_view.pick_actor(p)!=i:fails+=1;printerr("PICK ",viewport_size," ",index," ",i)
				if g.rules.color(g.rules.cells[i])=="w":
					g.selected=-1;g.tap(p)
					if g.selected!=i:fails+=1;printerr("TAP ",i)
				count+=1
			for i in range(g.rules.n*g.rules.n):
				if not Geometry2D.is_point_in_polygon(g.point(i%g.rules.n,i/g.rules.n),g.poly(i)):fails+=1
	# Reduced motion must freeze idle pose and eye state, not disable selection.
	g.selected=4;g.board_view.update_position(g.rules.cells,4,[4],false,false)
	g.board_view.animate(.1)
	if g.board_view.pieces[4].get_node("Portrait").frame!=11:fails+=1
	g.board_view.gold_skin=true;g.board_view.update_position(g.rules.cells,4,[],false,false)
	if not g.board_view.pieces[4].has_node("RewardRing"):fails+=1
	print("SELECTION ",count," character centers across three sizes and two viewports; failures ",fails)
	await create_timer(2).timeout
	quit(1 if fails else 0)
