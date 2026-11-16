extends SceneTree
const R=preload("res://scripts/rules.gd")
const L=preload("res://scripts/learning.gd")
const O=preload("res://scripts/objectives.gd")
func _initialize():
	var missions=JSON.parse_string(FileAccess.get_file_as_string("res://data/missions.json"))
	var traces=JSON.parse_string(FileAccess.get_file_as_string("res://tests/campaign.json"))
	var l=L.new();l.path="user://campaign-test.json"
	var failures=0;var plies=0
	for m in missions:
		var r=R.new();r.load_fen(m.initialPosition,int(m.boardSize))
		var success=false
		if m.type=="GAME":
			for t in traces:
				if t.id!=m.id:continue
				for move in t.moves:
					if not r.play(move):failures+=1;printerr("ILLEGAL ",m.id," ",move)
					plies+=1
				success=r.status()=="checkmate" and r.turn=="b"
		else:
			var sol=O.solutions(r,m);var before=r.cells.duplicate()
			if sol.size():r.play(sol[0]);success=O.success(r,m,sol[0],before);plies+=1
		if not success:failures+=1;printerr("UNSOLVED ",m.id)
		else:l.complete(m,true,true)
	var restored=L.new();restored.path=l.path;restored.load_save()
	if restored.data.completed.size()!=56:failures+=1
	print("CAMPAIGN completed ",restored.data.completed.size(),"/56; legal plies ",plies,"; failures ",failures)
	quit(1 if failures else 0)
