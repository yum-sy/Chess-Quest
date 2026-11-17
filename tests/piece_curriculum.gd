extends SceneTree
const R=preload("res://scripts/rules.gd")
const O=preload("res://scripts/objectives.gd")
var checks=0
var fails=0
var ms=[]
func expect(ok,label):
	checks+=1
	if not ok:fails+=1;printerr("FAIL ",label)
func mission(id):
	for m in ms:
		if m.id==id:return m
	return {}
func position(id):
	var r=R.new();var m=mission(id);r.load_fen(m.initialPosition,int(m.boardSize));return r
func accepted(id,move):
	var r=position(id);var before=r.cells.duplicate()
	return r.play(move) and O.success(r,mission(id),move,before)
func _initialize():call_deferred("run")
func run():
	ms=JSON.parse_string(FileAccess.get_file_as_string("res://data/missions.json"))
	var safe_count=0
	for m in ms:
		if m.chapter>6:continue
		var r=position(m.id)
		for step in m.get("sequence",[{}]):
			var active=m.duplicate(true);active.objective.merge(step.get("objective",{}),true);active.type=step.get("type",m.type)
			var sol=O.solutions(r,active);expect(not sol.is_empty(),m.id+" every step solvable")
			if sol.is_empty():continue
			var original=r.fen()
			for move in sol:
				r.play(move)
				if active.type in ["ATTACK","FORK","DISCOVERED_ATTACK","PIN","SKEWER"]:
					expect(not O.can_capture(r,r.square(move.substr(2,2))),m.id+" safe "+move);safe_count+=1
				r.load_fen(original,r.n)
			r.play(sol[0]);r.turn="w"
	var r=position("1-7");var m=mission("1-7")
	r.load_fen(m.previousPosition);expect(r.play(m.previousMove),"previous double step legal")
	expect(r.fen()==m.initialPosition,"EP follows actual previous move")
	expect(accepted("1-7","e5d6"),"en passant accepted")
	r.play("e5d6");expect(r.cells[r.square("d5")]=="" and r.cells[r.square("d6")]=="P","EP removes adjacent pawn")
	expect(not "e5d6" in position("1-8").legal(),"expired EP disallowed")
	for promo in ["q","r","b","n"]:expect(accepted("1-6","b7b8"+promo),"promotion "+promo)
	expect(accepted("2-8","c7c8n") and not accepted("2-8","c7c8q"),"underpromotion fork specifically knight")
	expect(accepted("6-5","e1g1") and accepted("6-6","e1c1"),"both castles")
	expect(not "e1g1" in position("6-6").legal(),"cannot castle through attacked square")
	expect(not "e1g1" in position("6-7").legal(),"cannot castle out of check")
	for fen in ["6k1/8/8/8/8/8/8/4K2R w - - 0 1","6k1/8/8/8/8/8/8/4KB1R w K - 0 1","6rk/8/8/8/8/8/8/4K2R w K - 0 1"]:
		r.load_fen(fen);expect(not "e1g1" in r.legal(),"no rights / blocked / attacked destination")
	r=position("6-5")
	for move in ["h1g1","a8b8","g1h1","b8a8"]:expect(r.play(move),"rook round trip "+move)
	expect(not "e1g1" in r.legal(),"rook return does not restore rights")
	expect(not accepted("5-3","b2b4"),"queen attacking rook along rank is capturable")
	expect(accepted("5-3","b2b1"),"safe diagonal queen attack")
	expect(not accepted("5-7","g6f7") and accepted("5-7","g6g7"),"stalemate is not mate")
	r=position("4-5");r.play("c1g5")
	for move in r.legal():expect(not move.begins_with("f6"),"pinned knight cannot expose king")
	# A pinned rook still attacks king squares, but cannot legally capture this bishop.
	r.load_fen("4k3/4r3/8/1B6/8/8/8/K3R3 b - - 0 1")
	expect(r.attacked(r.square("b7"),"b"),"pinned piece controls squares")
	r.cells[r.square("b5")]="";r.cells[r.square("b7")]="B"
	expect(not O.can_capture(r,r.square("b7")),"illegal pinned capture not treated as legal reply")
	# En passant is a capture even though the destination is empty.
	r.load_fen("6k1/8/8/8/3pP3/8/8/6K1 b - e3 0 1")
	expect(O.can_capture(r,r.square("e4")),"safety includes opponent en passant")
	var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
	g.learner.path="user://piece-curriculum-test.json";g.learner.data.settings.sound=false
	for sample in [[6,"e5d6"],[12,"b1c3"],[15,"c7c8n"],[37,"d1a4"],[44,"e1g1"],[45,"e1c1"]]:
		g.start_mission(sample[0]);g.finish_demo();g.modal="";g.player_move(sample[1]);await create_timer(.65).timeout
		expect(g.modal=="success","UI special mission "+str(sample[0]))
	g.start_mission(39);g.modal="";g.player_move("d4c3");await create_timer(.65).timeout
	expect(g.lesson_step==1 and g.active_mission().type=="ATTACK","sequence changes objective type")
	var sol=O.solutions(g.rules,g.active_mission());g.player_move(sol[0]);await create_timer(.65).timeout
	expect(g.modal=="success","retreat then attack complete")
	g.start_mission(34);g.modal="";var initial=g.rules.fen();g.player_move("b2b4");await create_timer(.7).timeout
	expect(g.modal!="success" and g.rules.cells[g.rules.square("b4")]=="r","unsafe attack demonstrated by opponent capture")
	await create_timer(1.8).timeout
	expect(g.rules.fen()==initial,"unsafe attack retry restores position")
	print("PIECE CURRICULUM ",checks," checks; ",safe_count," safe tactical solutions; failures ",fails)
	quit(1 if fails else 0)
