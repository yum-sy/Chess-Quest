extends RefCounted
var data = {"version":3,"completed":[],"english":{},"chess":{},"rewards":[],"settings":{"korean":true,"motion":true,"sound":true,"theme":0},"current":{},"lastMission":0}
var save_error = false
var path="user://quest-v3.json"
func read_document(file_path:String):
	var doc=JSON.new()
	return doc.data if doc.parse(FileAccess.get_file_as_string(file_path))==OK else null
func load_save():
	if not FileAccess.file_exists(path):return
	var parsed=read_document(path)
	if not parsed is Dictionary:
		if FileAccess.file_exists(path+".bak"):parsed=read_document(path+".bak")
	if parsed is Dictionary:
		for k in data:
			if parsed.has(k):data[k]=parsed[k]
		data.version=3
		for k in {"korean":true,"motion":true,"sound":true,"theme":0}:
			if not data.settings.has(k):data.settings[k]={"korean":true,"motion":true,"sound":true,"theme":0}[k]
func save():
	var f=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if not f:save_error=true;return
	f.store_string(JSON.stringify(data));f.close()
	if FileAccess.file_exists(path):DirAccess.copy_absolute(path,path+".bak")
	save_error=DirAccess.rename_absolute(path+".tmp",path)!=OK
func record(id: String) -> Dictionary:
	if not data.english.has(id):
		data.english[id]={"expressionId":id,"familiarityState":"NEW","exposureCount":0,"replayCount":0,"assistedSuccessCount":0,"independentSuccessCount":0,"lastReviewedAt":0,"nextReviewAt":0,"contexts":[],"targetSelections":0,"audioHeard":false,"koreanUsed":false,"visualHint":true}
	return data.english[id]
func expose(id: String, replay=false, heard=true):
	var e=record(id)
	e.exposureCount+=1 if heard and not replay else 0
	if not heard:e["textExposureCount"]=e.get("textExposureCount",0)+1
	e.replayCount+=1 if replay else 0
	e.audioHeard=heard
	e.lastReviewedAt=Time.get_unix_time_from_system()
	if e.nextReviewAt<=e.lastReviewedAt:e.nextReviewAt=e.lastReviewedAt+86400
	if e.familiarityState=="NEW":e.familiarityState="LEARNING"
func chess(id: String) -> Dictionary:
	if not data.chess.has(id):data.chess[id]={"missionId":id,"attemptCount":0,"legalMoveCount":0,"tacticalSuccessCount":0,"hintCount":0,"wrongCount":0,"checkDefenseCount":0,"checkmateCount":0,"completedAt":0}
	return data.chess[id]
func selected(id: String, assisted: bool, korean: bool):
	var e=record(id)
	e.targetSelections+=1
	e.visualHint=assisted
	e.koreanUsed=korean
func complete(m: Dictionary, assisted: bool, korean: bool):
	var c=chess(m.id)
	c.tacticalSuccessCount+=1;c.completedAt=Time.get_unix_time_from_system()
	if m.type=="ESCAPE_CHECK":c.checkDefenseCount+=1
	if m.type in ["CHECKMATE","GAME"]:c.checkmateCount+=1
	var e=record(m.englishExpressionIds[0])
	# Only repeated, audible, unassisted action evidence in distinct layouts counts.
	if assisted or korean or not e.audioHeard:e.assistedSuccessCount+=1
	else:
		e.independentSuccessCount+=1
		if not m.initialPosition in e.contexts:e.contexts.append(m.initialPosition)
	e.familiarityState="FAMILIAR" if e.contexts.size()>=3 and e.independentSuccessCount>=3 else "PRACTICING" if e.exposureCount>=2 else "LEARNING"
	e.lastReviewedAt=Time.get_unix_time_from_system()
	e.nextReviewAt=e.lastReviewedAt+86400*(7 if e.familiarityState=="FAMILIAR" else 1)
	if not m.id in data.completed:data.completed.append(m.id)
	if not m.rewardId in data.rewards:data.rewards.append(m.rewardId)
	save()
func review_ids() -> Array:
	var ids=data.english.keys()
	for id in ids:priority(id)
	ids.sort_custom(func(a,b):return priority(a)>priority(b))
	return ids
func priority(id: String) -> float:
	var e=record(id)
	if e.nextReviewAt>0 and e.nextReviewAt<Time.get_unix_time_from_system():e.familiarityState="REVIEW"
	return e.assistedSuccessCount*4+ (20 if e.familiarityState=="REVIEW" else 0)+(8 if e.independentSuccessCount==0 else 0)-e.lastReviewedAt/1e12

func reset_progress()->bool:
	var previous=data.duplicate(true)
	var fresh=get_script().new()
	for key in ["sound","korean","motion"]:fresh.data.settings[key]=data.settings.get(key,true)
	data=fresh.data.duplicate(true)
	save()
	if save_error:
		data=previous
		return false
	# The recovery copy must also be clean; old progress must not reappear.
	if DirAccess.copy_absolute(path,path+".bak")!=OK:DirAccess.remove_absolute(path+".bak")
	return true
