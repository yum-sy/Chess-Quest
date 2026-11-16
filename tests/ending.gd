extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g)
	await process_frame;g.learner.path="user://ending-test.json"
	g.start_mission(55);g.modal=""
	var traces=JSON.parse_string(FileAccess.get_file_as_string("res://tests/campaign.json"))
	var t=traces[-1]
	for move in t.moves.slice(0,-1):g.rules.play(move)
	g.player_move(t.moves[-1]);await create_timer(.7).timeout
	var ok=g.modal=="success" and g.learner.data.completed.has("7-8")
	g.action("next");ok=ok and g.screen=="ending"
	g.action("free");ok=ok and g.rules.fen()==g.Rules.START and g.free_play
	print("ENDING + FREE PLAY ","PASS" if ok else "FAIL")
	await create_timer(2).timeout
	g.queue_free();await process_frame
	quit(0 if ok else 1)
