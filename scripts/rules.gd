extends RefCounted
# Training rules and native rules mirror. Web standard games use vendored chess.js.
const START = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
var n = 8
var cells: Array = []
var turn = "w"
var rights = "KQkq"
var ep = -1
var half = 0
var full = 1
var history: Array = []
var positions: Array = []
var notation: Array = []
var bridge = false
func _init():
	load_fen(START)
func load_fen(fen: String, size: int = 8):
	n = size
	cells.resize(n*n)
	cells.fill("")
	var parts = fen.split(" ")
	var rows = parts[0].split("/")
	for y in range(n):
		var x = 0
		for c in rows[n-1-y]:
			if c.is_valid_int(): x += int(c)
			else:
				cells[y*n+x] = c
				x += 1
	turn = parts[1] if parts.size()>1 else "w"
	rights = parts[2] if parts.size()>2 else "-"
	ep = square(parts[3]) if parts.size()>3 and parts[3]!="-" else -1
	half = int(parts[4]) if parts.size()>4 else 0
	full = int(parts[5]) if parts.size()>5 else 1
func fen() -> String:
	var rows: Array = []
	for y in range(n-1,-1,-1):
		var row = ""
		var empty = 0
		for x in range(n):
			var p = cells[y*n+x]
			if p == "": empty += 1
			else:
				if empty: row += str(empty)
				empty = 0
				row += p
		if empty: row += str(empty)
		rows.append(row)
	return "/".join(rows)+" "+turn+" "+(rights if rights!="" else "-")+" "+(coord(ep) if ep>=0 else "-")+" "+str(half)+" "+str(full)
func square(s: String) -> int:
	return "abcdefgh".find(s[0])+(int(s.substr(1))-1)*n
func coord(i: int) -> String:
	return "abcdefgh"[i%n]+str(i/n+1)
func color(p: String) -> String:
	return "" if p=="" else ("w" if p==p.to_upper() else "b")
func other(c: String) -> String: return "b" if c=="w" else "w"
func attacks(a: int, b: int) -> bool:
	var p: String = cells[a].to_lower()
	if p=="" or a==b: return false
	var dx = b%n-a%n
	var dy = b/n-a/n
	if p=="p": return abs(dx)==1 and dy==(1 if color(cells[a])=="w" else -1)
	if p=="n": return abs(dx)*abs(dy)==2
	if p=="k": return maxi(abs(dx),abs(dy))==1
	if not ((p in ["r","q"] and (dx==0 or dy==0)) or (p in ["b","q"] and abs(dx)==abs(dy))): return false
	var step = int(sign(dx))+int(sign(dy))*n
	var t = a+step
	while t!=b:
		if cells[t]!="": return false
		t+=step
	return true
func attacked(s: int, by: String) -> bool:
	for i in range(n*n):
		if color(cells[i])==by and attacks(i,s): return true
	return false
func check(c: String) -> bool:
	var k = cells.find("K" if c=="w" else "k")
	return k>=0 and attacked(k,other(c))
func raw_moves() -> Array:
	var out: Array = []
	for a in range(n*n):
		if color(cells[a])!=turn: continue
		var p: String = cells[a].to_lower()
		for b in range(n*n):
			if color(cells[b])==turn or cells[b].to_lower()=="k": continue
			var valid = false
			if p=="p":
				var d = 1 if turn=="w" else -1
				valid = (b==a+d*n and cells[b]=="") or (attacks(a,b) and (cells[b]!="" or (n==8 and b==ep)))
				if a/n==(1 if turn=="w" else n-2) and b==a+2*d*n and cells[b]=="" and cells[a+d*n]=="": valid=true
			else: valid=attacks(a,b)
			if valid:
				if n==8 and p=="p" and b/n in [0,n-1]:
					for promo in ["q","r","b","n"]: out.append(coord(a)+coord(b)+promo)
				else: out.append(coord(a)+coord(b))
		if n==8 and p=="k" and a==(4 if turn=="w" else 60) and not check(turn):
			for king_side in [true,false]:
				var letter = ("K" if king_side else "Q") if turn=="w" else ("k" if king_side else "q")
				var r = a+3 if king_side else a-4
				var d = 1 if king_side else -1
				if not letter in rights or cells[r]!=("R" if turn=="w" else "r"): continue
				var clear = true
				for j in range(a+d,r,d):
					if cells[j]!="": clear=false
				if clear and not attacked(a+d,other(turn)) and not attacked(a+2*d,other(turn)): out.append(coord(a)+coord(a+2*d))
	return out
func legal() -> Array:
	if n==8 and bridge and OS.has_feature("web"):
		return JSON.parse_string(JavaScriptBridge.eval("CQ.legal("+JSON.stringify(fen())+")"))
	var out: Array = []
	var original = fen()
	var who = turn
	for m in raw_moves():
		apply_raw(m)
		if not check(who): out.append(m)
		load_fen(original,n)
	return out
func apply_raw(m: String):
	var a = square(m.substr(0,2))
	var b = square(m.substr(2,2))
	var p: String = cells[a]
	var capture = cells[b]!=""
	if p.to_lower()=="p" and b==ep and cells[b]=="":
		cells[b+(-n if turn=="w" else n)]=""
		capture=true
	if p.to_lower()=="k" and abs(b-a)==2:
		var r = a+3 if b>a else a-4
		cells[a+(1 if b>a else -1)] = cells[r]
		cells[r]=""
	for key in {0:"Q",7:"K",56:"q",63:"k"}:
		if a==key or b==key: rights=rights.replace({0:"Q",7:"K",56:"q",63:"k"}[key],"")
	if p=="K": rights=rights.replace("K","").replace("Q","")
	if p=="k": rights=rights.replace("k","").replace("q","")
	cells[b]=p if m.length()==4 else (m[4].to_upper() if turn=="w" else m[4])
	cells[a]=""
	ep=(a+b)/2 if n==8 and p.to_lower()=="p" and abs(b-a)==2*n else -1
	half=0 if capture or p.to_lower()=="p" else half+1
	if turn=="b": full+=1
	turn=other(turn)
func play(m: String) -> bool:
	if not m in legal(): return false
	history.append(fen())
	positions.append(position_key())
	if n==8 and bridge and OS.has_feature("web"):
		var result = JSON.parse_string(JavaScriptBridge.eval("CQ.move("+JSON.stringify(fen())+","+JSON.stringify(m)+")"))
		load_fen(result.fen)
		notation.append(result.san)
	else:
		apply_raw(m)
		notation.append(m)
	return true
func undo():
	if history.is_empty(): return
	load_fen(history.pop_back(),n)
	positions.pop_back()
	notation.pop_back()
func position_key() -> String:
	var f = fen().split(" ")
	# Include en passant only if a legal capture actually exists.
	var active_ep = "-"
	if ep>=0:
		for m in legal():
			if square(m.substr(2,2))==ep and cells[square(m.substr(0,2))].to_lower()=="p": active_ep=coord(ep)
	return f[0]+" "+f[1]+" "+f[2]+" "+active_ep
func status() -> String:
	var moves = legal()
	if moves.is_empty(): return "checkmate" if check(turn) else "stalemate"
	if n<8: return "playing"
	if half>=100: return "fifty_move"
	if positions.count(position_key())>=2: return "repetition"
	var minors: Array = []
	for i in range(64):
		if cells[i].to_lower() in ["p","r","q"]: return "playing"
		if cells[i].to_lower() in ["b","n"]: minors.append(i)
	if minors.size()<=1: return "material"
	var bishops_only = true
	var shades: Array = []
	for i in minors:
		if cells[i].to_lower()!="b": bishops_only=false
		shades.append((i%8+i/8)%2)
	if bishops_only and (shades.count(0)==shades.size() or shades.count(1)==shades.size()): return "material"
	return "playing"
func choose_ai(helpful: bool = false) -> String:
	var moves=legal()
	if moves.is_empty(): return ""
	if not helpful: return moves.pick_random()
	var original=fen()
	var best=moves[0]
	var score=-1e9
	for m in moves:
		var b=square(m.substr(2,2))
		var value={"":0,"p":1,"n":3,"b":3,"r":5,"q":9,"k":0}[cells[b].to_lower()]
		apply_raw(m)
		var s=value*10+(2 if check(turn) else 0)
		if check(turn) and legal().is_empty(): s=10000
		if attacked(b,turn): s-=5
		if s>score: score=s; best=m
		load_fen(original,n)
	return best
