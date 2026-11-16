extends SceneTree
const R=preload("res://scripts/rules.gd")
const O=preload("res://scripts/objectives.gd")
func _initialize():
	var ms=JSON.parse_string(FileAccess.get_file_as_string("res://data/missions.json"))
	var fails=0;var checked=0
	for m in ms:
		if m.chapter!=4 or int(m.id.split("-")[1])<3:continue
		var r=R.new();r.load_fen(m.initialPosition,6)
		var a=r.square(m.threat[0]);var b=r.square(m.threat[1]);var bishop=r.cells.find("B")
		if not r.attacks(a,b):fails+=1;printerr("No real initial threat ",m.id)
		if m.type=="PROTECT" and r.attacks(bishop,b):fails+=1;printerr("Already protected ",m.id)
		if m.type=="SAFE_MOVE" and not r.attacked(bishop,"b"):fails+=1
		var sol=O.solutions(r,m)
		if sol.is_empty():fails+=1
		if m.type=="CAPTURE":
			for move in sol:
				if move.substr(2,2)!=m.objective.target:fails+=1
		for move in sol:
			var before=r.cells.duplicate();r.apply_raw(move)
			if not O.success(r,m,move,before):fails+=1
			r.load_fen(m.initialPosition,6)
		checked+=1
		print(m.id," ",m.type," real threat ",m.threat," solutions ",sol)
	print("TEMPLE ",checked," redesigned missions; failures ",fails)
	quit(1 if fails else 0)
