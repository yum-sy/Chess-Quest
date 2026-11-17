extends SceneTree
const R=preload("res://scripts/rules.gd")
const O=preload("res://scripts/objectives.gd")
func _initialize():
	var ms=JSON.parse_string(FileAccess.get_file_as_string("res://data/missions.json"))
	var fails=0;var kinds=[]
	for m in ms:
		if m.chapter!=4:continue
		var r=R.new();r.load_fen(m.initialPosition,int(m.boardSize))
		if m.has("threat") and not r.attacks(r.square(m.threat[0]),r.square(m.threat[1])):fails+=1
		var sol=O.solutions(r,m)
		if sol.is_empty():fails+=1
		if not m.type in kinds:kinds.append(m.type)
		print(m.id," ",m.type," solutions ",sol)
	if kinds.size()<7:fails+=1
	print("TEMPLE 8 distinct bishop lessons; failures ",fails)
	quit(1 if fails else 0)
