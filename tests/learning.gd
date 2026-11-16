extends SceneTree
func _initialize():
	var L=load("res://scripts/learning.gd");var l=L.new();l.path="user://learning-test.json"
	var missions=JSON.parse_string(FileAccess.get_file_as_string("res://data/missions.json"))
	var base=missions[2].duplicate(true);var id=base.englishExpressionIds[0];var failed=0
	for i in range(3):
		base.initialPosition=str(i);l.expose(id);l.selected(id,false,false);l.complete(base,false,false)
	if l.record(id).familiarityState!="FAMILIAR":failed+=1
	l.record(id).nextReviewAt=1
	if l.review_ids()[0]!=id or l.record(id).familiarityState!="REVIEW":failed+=1
	l.record(id).audioHeard=false;var before=l.record(id).independentSuccessCount;l.complete(base,false,false)
	if l.record(id).independentSuccessCount!=before:failed+=1
	var c=l.chess(base.id);var old=c.tacticalSuccessCount
	l.selected(id,false,false)
	if c.tacticalSuccessCount!=old:failed+=1
	l.save();l.save()
	var f=FileAccess.open(l.path,FileAccess.WRITE);f.store_string("corrupt");f.close()
	var restored=L.new();restored.path=l.path;restored.load_save()
	if not restored.data.completed.has(base.id):failed+=1
	f=FileAccess.open(l.path,FileAccess.WRITE);f.store_string('{"version":1,"completed":["1-1"],"settings":{"sound":false}}');f.close()
	restored=L.new();restored.path=l.path;restored.load_save()
	if restored.data.version!=3 or not restored.data.settings.has("motion") or restored.data.settings.sound:failed+=1
	print("LEARNING migration, backup, mastery, audio evidence, due review, separation: FAILURES ",failed)
	quit(1 if failed else 0)
