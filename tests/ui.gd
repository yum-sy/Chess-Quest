extends SceneTree
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	if not ok:failures+=1;printerr("FAIL ",label)
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g)
	await process_frame;await process_frame
	g.learner.path="user://ui-test.json"
	g.start_mission(0);g.action("begin")
	check(g.audio.playing,"mission voice playing")
	var p=g.point(1,1);g.tap(p);check(g.selected==5,"touch selected b2")
	g.tap(g.point(1,2))
	await create_timer(.8).timeout
	check(g.modal=="success","touch completed first mission")
	check(g.learner.data.completed.has("1-1"),"saved completion")
	g.action("next");g.modal=""
	check(g.index==1,"next mission")
	g.start_mission(2);g.modal=""
	g.player_move("b2b3")
	await create_timer(2.5).timeout
	check(g.rules.fen()==g.missions[2].initialPosition,"wrong move restores original")
	check(g.hints>=2,"hint escalation")
	for n in [4,6,8]:
		g.start_mission(0 if n==4 else 16 if n==6 else 48);g.modal=""
		await process_frame
		for i in range(n*n):check(Geometry2D.is_point_in_polygon(g.point(i%n,i/n),g.poly(i)),"touch center")
	g.start_mission(53);g.modal="";g.player_move("e2e4")
	await create_timer(1.4).timeout
	check(g.rules.turn=="w" and g.rules.history.size()==2,"AI legal response")
	g.action("undo");check(g.rules.fen()==g.Rules.START,"undo turn pair")
	var saved=g.learner.data.current.duplicate(true)
	var last=g.learner.data.lastMission
	g.review=true;g.start_mission(0);g.persist()
	check(g.learner.data.current==saved and g.learner.data.lastMission==last,"review preserves campaign save")
	g.action("home");g.action("settings");g.action("back")
	check(g.screen=="home","settings returns to originating screen")
	await create_timer(2).timeout
	print("UI FAILURES ",failures)
	quit(1 if failures else 0)
