extends SceneTree
const Rules=preload("res://scripts/rules.gd")
const Goals=preload("res://scripts/objectives.gd")
const Learn=preload("res://scripts/learning.gd")
var failures=0
var checks=0
func expect(ok:bool,label:String):
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+label)
func perft(r,depth:int)->int:
	if depth==0:return 1
	var f=r.fen();var count=0
	for m in r.legal():
		r.apply_raw(m);count+=perft(r,depth-1);r.load_fen(f)
	return count
func _initialize():
	var r=Rules.new()
	expect(r.legal().size()==20,"start legal")
	expect(perft(r,3)==8902,"start perft 3")
	r.load_fen("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1")
	expect(perft(r,2)==2039,"kiwipete perft 2")
	r.load_fen("4k3/P7/8/8/8/8/8/4K3 w - - 0 1")
	for p in ["q","r","b","n"]:expect("a7a8"+p in r.legal(),"promotion "+p)
	r.load_fen("k3r3/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
	expect(not "e5d6" in r.legal(),"pinned en passant")
	r.load_fen("k7/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
	expect(r.play("e5d6") and r.cells[r.square("d5")]=="","en passant capture")
	r.undo();expect(r.ep==r.square("d6"),"undo ep")
	r.load_fen("7k/5Q2/6K1/8/8/8/8/8 b - - 0 1")
	expect(r.status()=="stalemate","stalemate")
	r.load_fen("7k/6Q1/6K1/8/8/8/8/8 b - - 0 1")
	expect(r.status()=="checkmate","checkmate")
	r.load_fen("7k/8/6K1/8/8/8/8/8 w - - 100 1")
	expect(r.status()=="fifty_move","50 move")
	r=Rules.new()
	for m in ["g1f3","g8f6","f3g1","f6g8","g1f3","g8f6","f3g1","f6g8"]:expect(r.play(m),"repeat legal")
	expect(r.status()=="repetition","threefold repetition")
	var missions=JSON.parse_string(FileAccess.get_file_as_string("res://data/missions.json"))
	expect(missions.size()==56,"56 missions")
	var counts={}
	for m in missions:
		counts[m.chapter]=counts.get(m.chapter,0)+1
		r=Rules.new();r.load_fen(m.initialPosition,int(m.boardSize))
		expect(r.legal().size()>0,"legal start "+m.id)
		if m.type!="GAME":
			var sol=Goals.solutions(r,m)
			expect(not sol.is_empty(),"solvable "+m.id)
			m.acceptedSolutions=sol
			print(m.id," ",m.type," solutions ",sol.size())
		for id in m.englishExpressionIds:expect(FileAccess.file_exists("res://assets/audio/"+id+".wav"),"audio "+id)
	for c in counts:expect(counts[c]==8,"8 per chapter")
	var output=FileAccess.open("res://data/missions.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(missions,"  "));output.close()
	var l=Learn.new();l.path="user://test-save.json"
	var m=missions[0]
	l.expose(m.englishExpressionIds[0]);l.complete(m,true,true)
	expect(l.record(m.englishExpressionIds[0]).independentSuccessCount==0,"hinted not independent")
	l.save();var restored=Learn.new();restored.path=l.path;restored.load_save()
	expect(restored.data.completed.has(m.id),"save roundtrip")
	print("CHECKS ",checks," FAILURES ",failures)
	quit(1 if failures else 0)
