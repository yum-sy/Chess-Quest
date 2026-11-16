extends RefCounted
static func success(r, m: Dictionary, move: String, before: Array) -> bool:
	var a=r.square(move.substr(0,2))
	var b=r.square(move.substr(2,2))
	var o=m.objective
	if o.piece!="" and before[a].to_lower()!=o.piece: return false
	var target=r.square(o.target) if o.target!="" else -1
	match m.type:
		"MOVE": return o.destination=="" or b==r.square(o.destination)
		"CAPTURE": return before[b]!="" and r.color(before[b])=="b" and (target<0 or b==target)
		"ATTACK": return target>=0 and r.color(r.cells[target])=="b" and r.attacks(b,target)
		"SAFE_MOVE": return not r.attacked(b,"b")
		"PROTECT":
			if target<0 or r.color(r.cells[target])!="w" or not r.attacks(b,target): return false
			# Require an actual legal capture threat and a legal recapture, not just an extra defender.
			var original=r.fen()
			var threats=0
			for reply in r.legal():
				if r.square(reply.substr(2,2))!=target: continue
				threats+=1
				r.apply_raw(reply)
				var recapture=false
				for answer in r.legal():
					if r.square(answer.substr(0,2))==b and r.square(answer.substr(2,2))==target: recapture=true
				r.load_fen(original,r.n)
				if not recapture:return false
			return threats>0
		"FORK":
			var count=0
			for j in range(r.n*r.n):
				if r.color(r.cells[j])=="b" and r.attacks(b,j):count+=1
			return count>=2
		"CHECK": return r.check("b")
		"ESCAPE_CHECK": return not r.check("w")
		"CHECKMATE", "GAME": return r.check("b") and r.legal().is_empty()
	return false
static func solutions(r,m: Dictionary) -> Array:
	var out=[]
	var f=r.fen()
	var before=r.cells.duplicate()
	for move in r.legal():
		r.apply_raw(move)
		if success(r,m,move,before):out.append(move)
		r.load_fen(f,r.n)
	return out
