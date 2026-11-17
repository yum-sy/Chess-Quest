extends RefCounted
# Safety means a legal capture next turn, including en passant; pinned pieces
# still control king squares, so rules.attacked must retain its usual semantics.
static func can_capture(r, square: int) -> bool:
	for reply in r.legal():
		var a=r.square(reply.substr(0,2));var b=r.square(reply.substr(2,2))
		var victim=b
		if r.cells[a].to_lower()=="p" and b==r.ep and r.cells[b]=="":victim=b+(-r.n if r.turn=="w" else r.n)
		if victim==square:return true
	return false
static func threat(r, a:int, b:int)->bool:
	if not r.attacks(a,b):return false
	if r.cells[b].to_lower()=="k":return true
	var original=r.fen();r.turn="w";r.ep=-1
	var valid=false
	for move in r.legal():
		if r.square(move.substr(0,2))==a and r.square(move.substr(2,2))==b:valid=true;break
	r.load_fen(original,r.n)
	return valid
static func line_through(r,a:int,front:int,rear:int)->bool:
	var ax=a%r.n;var ay=a/r.n;var fx=front%r.n;var fy=front/r.n;var rx=rear%r.n;var ry=rear/r.n
	return (fx-ax)*(ry-ay)==(fy-ay)*(rx-ax) and (fx-ax)*(rx-fx)+(fy-ay)*(ry-fy)>0
static func fork(r,b:int,targets:Array)->bool:
	if can_capture(r,b):return false
	if not targets.is_empty():
		for square in targets:
			var t=r.square(square)
			if r.color(r.cells[t])!="b" or not threat(r,b,t):return false
		return targets.size()>=2
	var count=0
	for j in range(r.n*r.n):
		if r.color(r.cells[j])=="b" and threat(r,b,j):count+=1
	return count>=2
static func success(r, m: Dictionary, move: String, before: Array) -> bool:
	var a=r.square(move.substr(0,2));var b=r.square(move.substr(2,2));var o=m.objective
	if o.piece!="" and before[a].to_lower()!=o.piece:return false
	if o.destination!="" and b!=r.square(o.destination):return false
	if o.get("safeMove",false) and can_capture(r,b):return false
	var target=r.square(o.target) if o.target!="" else -1
	match m.type:
		"MOVE":return true
		"CAPTURE":return before[b]!="" and r.color(before[b])=="b" and (target<0 or b==target) and (not o.get("safeCapture",false) or not can_capture(r,b))
		"ATTACK":return target>=0 and r.color(r.cells[target])=="b" and threat(r,b,target) and not can_capture(r,b)
		"EN_PASSANT":return before[a]=="P" and before[b]=="" and abs(a%r.n-b%r.n)==1 and target==b-r.n and before[target]=="p" and r.cells[target]==""
		"PROMOTION":return before[a]=="P" and move.length()==5 and (o.get("promotion","")=="" or move[4]==o.promotion) and (not o.has("forkTargets") or fork(r,b,o.forkTargets))
		"CASTLE":
			if before[a]!="K" or a!=r.square("e1") or b not in [r.square("g1"),r.square("c1")]:return false
			var start=r.square("h1" if b>a else "a1");var end=r.square("f1" if b>a else "d1")
			return before[start]=="R" and r.cells[start]=="" and r.cells[end]=="R"
		"SAFE_MOVE":
			if o.get("requireThreatened",false):
				var after=r.cells;r.cells=before
				var threatened=r.attacked(a,"b");r.cells=after
				if not threatened:return false
			return not can_capture(r,b)
		"PROTECT":
			if target<0 or r.color(r.cells[target])!="w" or not r.attacks(b,target):return false
			if o.get("requireNewDefense",false):
				var after=r.cells;r.cells=before
				var already=r.attacks(a,target);r.cells=after
				if already:return false
			if can_capture(r,b):return false
			var original=r.fen();var threats=0
			for reply in r.legal():
				if r.square(reply.substr(2,2))!=target:continue
				threats+=1;r.apply_raw(reply)
				var recapture=false
				for answer in r.legal():
					if r.square(answer.substr(0,2))==b and r.square(answer.substr(2,2))==target:recapture=true
				r.load_fen(original,r.n)
				if not recapture:return false
			return threats>0
		"BATTERY":
			var ally=r.square(o.ally)
			return r.color(r.cells[ally])=="w" and r.attacks(b,ally) and threat(r,ally,target) and line_through(r,b,ally,target) and not can_capture(r,b)
		"DISCOVERED_ATTACK":
			var ally=r.square(o.ally)
			var after=r.cells;r.cells=before;var already=r.attacks(ally,target);r.cells=after
			return not already and threat(r,ally,target) and not can_capture(r,b) and not can_capture(r,ally)
		"PIN","SKEWER":
			var rear=r.square(o.rear)
			if r.color(r.cells[target])!="b" or r.color(r.cells[rear])!="b" or not r.attacks(b,target) or not line_through(r,b,target,rear) or can_capture(r,b):return false
			if m.type=="PIN" and (r.cells[rear]!="k" or r.cells[target]=="k"):return false
			if m.type=="SKEWER" and (r.cells[target]!="k" or r.cells[rear]=="k"):return false
			var front=r.cells[target];r.cells[target]="";var revealed=r.attacks(b,rear);r.cells[target]=front
			return revealed
		"FORK":return fork(r,b,o.get("targets",[]))
		"CHECK":return r.check("b")
		"ESCAPE_CHECK","BLOCK_CHECK":
			var after=r.cells;r.cells=before;var was_check=r.check("w");r.cells=after
			if not was_check or r.check("w"):return false
			if m.type=="BLOCK_CHECK":return before[a].to_lower()!="k" and before[b]==""
			return not o.get("captureChecker",false) or (b==target and r.color(before[b])=="b")
		"CHECKMATE", "GAME":return r.check("b") and r.legal().is_empty()
	return false
static func solutions(r,m: Dictionary) -> Array:
	var out=[];var f=r.fen();var before=r.cells.duplicate()
	for move in r.legal():
		r.apply_raw(move)
		if success(r,m,move,before):out.append(move)
		r.load_fen(f,r.n)
	return out
