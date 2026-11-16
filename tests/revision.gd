extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g)
	await process_frame
	g.learner.path="user://revision-test.json";g.learner.data.settings.sound=false
	g.learner.data.completed=["4-2"]
	g.learner.data.current={"id":"4-3","fen":"6/4r1/6/6/1B4/6 w - - 0 1"}
	g.start_mission(26,true)
	var ok=g.rules.fen()==g.missions[26].initialPosition and g.learner.data.completed.has("4-2")
	g.selected=g.rules.square("c1");g.player_move("c1f4")
	await create_timer(.7).timeout
	ok=ok and g.modal=="success" and g.learner.data.completed.has("4-3")
	print("TEMPLE save revision + capture UI ","PASS" if ok else "FAIL")
	await create_timer(2).timeout
	quit(0 if ok else 1)
