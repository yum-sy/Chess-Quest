extends SceneTree
func _initialize():
	var r=load("res://scripts/rules.gd").new()
	var fixtures=JSON.parse_string(FileAccess.get_file_as_string("res://tests/oracle.json"))
	var fail=0
	for f in fixtures:
		r.load_fen(f.fen);var actual=r.legal();actual.sort()
		if actual!=f.moves:fail+=1;printerr("MISMATCH ",f.fen,"\n",actual,"\n",f.moves)
	print("ORACLE POSITIONS ",fixtures.size()," FAILURES ",fail)
	quit(1 if fail else 0)
