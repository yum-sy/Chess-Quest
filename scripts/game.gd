extends Node2D
const Rules=preload("res://scripts/rules.gd")
const Goals=preload("res://scripts/objectives.gd")
const Learning=preload("res://scripts/learning.gd")
var font=FontVariation.new()
var missions: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/missions.json"))
var chapters: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapters.json"))
var expressions: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/expressions.json"))
var learner=Learning.new()
var rules=Rules.new()
var screen="home"
var buttons: Array=[]
var index=0
var chapter=1
var selected=-1
var hints=0
var mistakes=0
var busy=false
var feedback=""
var modal=""
var review=false
var was_assisted=false
var korean_used=false
var audio=AudioStreamPlayer.new()
var clock=0.0
var status_tick=0
var board_origin=Vector2.ZERO
var tile=Vector2(70,35)
var panel=Rect2()
var promotion: Array=[]
var anim_from=-1
var anim_to=-1
var anim_piece=""
var anim_t=1.0
var last_move=""
var generation=0
var book_page=0
var map_page=0
var free_play=false
var target_evidence=false
var introducing=""
var last_review_word=""
const THEME_COLORS=["eddcba","b7d3ba","b9ccd9","d6c7e4","e8c5c6","d8d8ea","d3bfdf","f1d78f"]
const THEME_NAMES=["정원","다리","마법의 탑","사원","궁전","왕의 성","검은 성","왕관"]
var cream=Color("fff6df")
var ink=Color("263e45")
var gold=Color("e8b35d")
var teal=Color("367f7b")
var muted=Color("71877e")
func _ready():
	font.base_font=preload("res://assets/font-medium.ttf")
	font.variation_opentype={"wght":550}
	get_window().size_changed.connect(responsive)
	responsive()
	add_child(audio)
	learner.load_save()
	rules.bridge=true
	index=clampi(int(learner.data.lastMission),0,55)
	set_process(true)
func responsive():
	var actual=get_window().size
	get_window().content_scale_size=Vector2i(720,1280) if actual.y>actual.x else Vector2i(1280,800)
func _process(delta):
	clock+=delta
	if OS.has_feature("web") and int(clock*2)>status_tick:
		status_tick=int(clock*2)
		var state={"screen":screen,"mission":missions[index].id,"modal":modal,"completed":learner.data.completed.size(),"turn":rules.turn,"audioPlaying":audio.playing,"busy":busy,"fen":rules.fen()}
		JavaScriptBridge.eval("window.CQ.state="+JSON.stringify(state))
	if anim_t<1:anim_t=minf(1,anim_t+delta*2.5)
	queue_redraw()
func size_now()->Vector2:return get_viewport_rect().size
func text(s:String,p:Vector2,fs:int=22,col:Color=Color("263e45")):
	draw_string(font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,col)
func centered(s:String,p:Vector2,fs:int,col:Color):
	text(s,p-Vector2(font.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x/2,0),fs,col)
func box(r:Rect2,c:Color,radius=18.0,border:Color=Color.TRANSPARENT):
	var style=StyleBoxFlat.new()
	style.bg_color=c
	style.set_corner_radius_all(int(radius))
	style.border_color=border
	style.set_border_width_all(2 if border.a else 0)
	draw_style_box(style,r)
func button(label:String,r:Rect2,action:String,accent=false,disabled=false):
	box(r,Color("d8dfd4") if disabled else teal if accent else cream,14)
	centered(label,r.get_center()+Vector2(0,8),28 if size_now().x<1050 else 22,Color("82928a") if disabled else cream if accent else ink)
	buttons.append({"r":r,"action":action,"disabled":disabled})
func _draw():
	buttons.clear()
	var s=size_now()
	draw_rect(Rect2(Vector2.ZERO,s),Color("e8efdc"))
	# Quiet illustrated fantasy landscape; entirely original vector artwork.
	for i in range(7):
		var p=Vector2(i*s.x/6,s.y*.73+sin(i*1.9)*55)
		draw_circle(p,180,Color("d7e4ce"))
	for i in range(16):
		var x=fmod(i*173.0+30,s.x)
		var y=fmod(i*137.0+80,s.y)
		draw_circle(Vector2(x,y),2,Color("ffffff90"))
	if screen=="home":draw_home(s)
	elif screen=="map":draw_map(s)
	elif screen=="play":draw_play(s)
	elif screen=="book":draw_book(s)
	elif screen=="settings":draw_settings(s)
	elif screen=="ending":draw_ending(s)
	if modal!="":draw_modal(s)
	if learner.save_error:text("저장 공간을 확인해 주세요. 이번 진행을 저장하지 못했어요.",Vector2(20,s.y-16),18,Color("a13d38"))
func draw_home(s:Vector2):
	text("A LITTLE MOVE. A GRAND ADVENTURE.",Vector2(60,68),18,teal)
	text("CHESS",Vector2(58,173),88,ink)
	text("QUEST",Vector2(58,264),88,ink)
	text("T H E  L O S T  C R O W N",Vector2(66,311),23,teal)
	text("잃어버린 왕관을 찾아서",Vector2(66,365),28,ink)
	text("영어를 듣고, 체스를 움직이며, 모험을 완성해요.",Vector2(66,410),21,muted)
	button("모험 계속하기  →" if learner.data.completed.size()>0 else "모험 시작하기  →",Rect2(64,458,310,64),"continue",true)
	button("왕국 지도",Rect2(64,540,145,56),"map")
	button("영어 도감",Rect2(225,540,149,56),"book")
	button("설정",Rect2(64,614,145,52),"settings")
	text("7개의 왕국  ·  56개의 모험  ·  나만의 속도로",Vector2(64,716),18,muted)
	var center=Vector2(s.x*.73,405)
	if s.x<1100:center=Vector2(s.x*.5,s.y*.78)
	draw_circle(center,220,Color("d1dfbd"))
	for i in range(3):
		var x=center.x-160+i*155
		box(Rect2(x-45,center.y-165,90,245),Color("b5cab6"),8)
		for j in range(3):box(Rect2(x-45+j*33,center.y-185,23,36),Color("b5cab6"),4)
	piece("K",center+Vector2(0,80),2.3)
	piece("P",center+Vector2(-140,110),1.6)
	piece("N",center+Vector2(140,110),1.6)
	book(center+Vector2(0,-190),1.3)
func header(title:String,sub:String,s:Vector2):
	text(title,Vector2(44,57),30)
	text(sub,Vector2(46,88),17,muted)
	button("처음",Rect2(s.x-142,28,100,52),"home")
func draw_map(s:Vector2):
	header("우리의 왕국 지도",str(learner.data.completed.size())+" / 56 모험 완료 · 힌트는 언제나 무료예요",s)
	var narrow=s.x<1050
	var cols=2 if narrow else 4
	var w=(s.x-100)/cols
	var offset=map_page*4 if narrow else 0
	for local in range(mini(4,7-offset) if narrow else 7):
		var c=local+offset
		var x=44+(local%cols)*w
		var y=125+(local/cols)*(500 if narrow else 235)
		var unlocked=c==0 or learner.data.completed.has(str(c)+"-8")
		box(Rect2(x,y,w-18,480 if narrow else 213),cream if unlocked else Color("dce2d3"),22)
		text("0"+str(c+1)+" / "+chapters[c].subtitle,Vector2(x+18,y+34),16,teal)
		text(chapters[c].title,Vector2(x+18,y+72),22)
		for j in range(8):
			var done=learner.data.completed.has(str(c+1)+"-"+str(j+1))
			var open=unlocked and (j==0 or learner.data.completed.has(str(c+1)+"-"+str(j)))
			var cells_per_row=2 if narrow else 4
			button(("★" if done else "B" if j>=5 else str(j+1)),Rect2(x+16+(j%cells_per_row)*((w-50)/cells_per_row),y+94+(j/cells_per_row)*(94 if narrow else 52),(w-65)/cells_per_row,88 if narrow else 44),"mission:"+str(c*8+j),done,not open)
	if narrow:
		button("도감",Rect2(44,s.y-110,190,88),"book",true)
		button("설정",Rect2(250,s.y-110,190,88),"settings")
		button("다음 지도",Rect2(456,s.y-110,220,88),"mappage")
	else:
		button("영어 도감 & 복습",Rect2(44,s.y-78,250,54),"book",true)
		button("꾸미기 / 설정",Rect2(312,s.y-78,220,54),"settings")
	if learner.data.completed.has("7-8"):button("자유 체스",Rect2(44+w,745,w-18,88) if narrow else Rect2(550,s.y-78,200,54),"free",true)
func layout_board(s:Vector2):
	var narrow=s.x<1050
	var area=Rect2(30,150,s.x-60,minf(s.y*.30,400)) if narrow else Rect2(25,150,s.x*.66-30,s.y-220)
	var tw=minf(area.size.x/(rules.n*2+1),area.size.y/(rules.n+2.4))
	tile=Vector2(tw,tw*.52)
	board_origin=Vector2(area.get_center().x,area.position.y+90)
	panel=Rect2(30,area.end.y+15,s.x-60,s.y-area.end.y-40) if narrow else Rect2(s.x*.68,140,s.x*.29,s.y-174)
func point(file:float,rank:float)->Vector2:
	var row=rules.n-1-rank
	return board_origin+Vector2((file-row)*tile.x,(file+row)*tile.y)
func poly(i:int)->PackedVector2Array:
	var p=point(i%rules.n,i/rules.n)
	return PackedVector2Array([p+Vector2(0,-tile.y),p+Vector2(tile.x,0),p+Vector2(0,tile.y),p+Vector2(-tile.x,0)])
func draw_play(s:Vector2):
	var m=missions[index]
	header("CHESS QUEST   /   "+chapters[m.chapter-1].title,("도감 복습" if review else "모험 "+str(index%8+1)+" / 8")+"  ·  "+str(rules.n)+" × "+str(rules.n)+(" 훈련 보드" if rules.n<8 else " 정식 체스")+("  ·  왕관 수호자" if m.boss else ""),s)
	layout_board(s)
	var base=PackedVector2Array([point(0,rules.n-1)+Vector2(-tile.x,0),point(rules.n-1,rules.n-1)+Vector2(tile.x,0),point(rules.n-1,0)+Vector2(tile.x,0),point(0,0)+Vector2(-tile.x,0)])
	var shadow=PackedVector2Array()
	for p in base:shadow.append(p+Vector2(0,25))
	draw_colored_polygon(shadow,Color("a9b8a0"))
	draw_colored_polygon(base,Color("976238"))
	var legal=rules.legal() if selected>=0 and not busy else []
	var destinations=[]
	for move in legal:
		if rules.square(move.substr(0,2))==selected:destinations.append(rules.square(move.substr(2,2)))
	var solution=[]
	if hints>=3 and m.type!="GAME":solution=Goals.solutions(rules,m)
	for depth in range(rules.n*2-1):
		for x in range(rules.n):
			var row=depth-x
			if row<0 or row>=rules.n:continue
			var i=x+(rules.n-1-row)*rules.n
			var p=poly(i)
			var c=Color("eddcba") if (x+row)%2==0 else Color("b99168")
			var theme_idx=clampi(int(learner.data.settings.theme),0,7)
			if theme_idx>0:c=c.lerp(Color(THEME_COLORS[theme_idx]),.35)
			if selected==i:c=Color("6daec6")
			if rules.cells[i].to_lower()=="k" and rules.check(rules.color(rules.cells[i])):c=Color("d56c5d")
			draw_colored_polygon(p,c)
			draw_polyline(PackedVector2Array([p[0],p[1],p[2],p[3],p[0]]),Color("c8a46b"),1.5,true)
			var at=point(x,rules.n-1-row)
			if i in destinations:
				draw_circle(at,tile.y*.29,Color("397e68") if rules.cells[i]=="" else Color("b44842"))
				draw_arc(at,tile.y*.5,0,TAU,24,cream,2,true)
			if hints>0 and m.objective.target!="" and i==rules.square(m.objective.target):draw_arc(at,tile.y*.8,0,TAU,32,gold,4,true)
			if not rules.cells[i].is_empty() and not (i==anim_to and anim_t<1):piece(rules.cells[i],at,tile.x/54.0)
	if last_move.length()>=4 and learner.data.rewards.size()>0 and learner.data.settings.motion:
		var end=rules.square(last_move.substr(2,2));var at=point(end%rules.n,end/rules.n)
		for j in range(5):draw_circle(at+Vector2(cos(clock+j*1.2)*tile.x*.45,sin(clock+j*1.2)*tile.y*.45-12),2.5,gold)
	if solution.size()>0:
		var a=rules.square(solution[0].substr(0,2));var b=rules.square(solution[0].substr(2,2))
		draw_line(point(a%rules.n,a/rules.n),point(b%rules.n,b/rules.n),Color("f8d76a"),6,true)
	if anim_t<1:
		var a=point(anim_from%rules.n,anim_from/rules.n)
		var b=point(anim_to%rules.n,anim_to/rules.n)
		var moving=a.lerp(b,anim_t)
		if anim_piece.to_lower() in ["n","p"]:moving+=Vector2(0,-sin(anim_t*PI)*(40 if anim_piece.to_lower()=="n" else 17))
		if anim_piece.to_lower() in ["q","b"]:draw_line(a,moving,Color("fff7c080"),5,true)
		piece(anim_piece,moving,tile.x/54.0)
	for x in range(rules.n):text("abcdefgh"[x],point(x,0)+Vector2(0,tile.y+25),15,muted)
	for r in range(rules.n):text(str(r+1),point(0,r)+Vector2(-tile.x-20,7),15,muted)
	var px=panel.position.x;var py=panel.position.y;var pw=panel.size.x
	box(panel,Color("fff9e9"),24)
	book(Vector2(px+pw/2,py+56),.8)
	text("THE MAGIC CHESSBOOK",Vector2(px+24,py+115),15,teal)
	if introducing!="":text(introducing,Vector2(px+24,py+205),20,teal)
	var expr=expression(m.englishExpressionIds[0])
	wrapped(expr.wordOrSentence,Rect2(px+24,py+138,pw-48,100),30,ink)
	var body=m.hints[mini(maxi(hints-1,0),2)] if hints else (expr.meaning if learner.data.settings.korean else "Listen. Think. Move.")
	wrapped(body,Rect2(px+24,py+232,pw-48,100),20,muted)
	var by=py+335
	var bh=88 if s.x<1050 else 50
	var gap=100 if s.x<1050 else 62
	button("▶ 다시 듣기",Rect2(px+20,by,(pw-48)/2,bh),"listen")
	button("느리게",Rect2(px+28+(pw-48)/2,by,(pw-48)/2,bh),"slow")
	button("힌트",Rect2(px+20,by+gap,(pw-48)/2,bh),"hint",true)
	button("↶ 무르기" if m.type=="GAME" else "다시 시작",Rect2(px+28+(pw-48)/2,by+gap,(pw-48)/2,bh),"undo" if m.type=="GAME" else "restart")
	button("지도",Rect2(px+20,by+gap*2,(pw-48)/2,bh),"map")
	button("설정",Rect2(px+28+(pw-48)/2,by+gap*2,(pw-48)/2,bh),"settings")
	wrapped(feedback,Rect2(44,s.y-78,s.x-88 if s.x<1050 else s.x*.62,64),20,teal)
	if rules.n==8 and rules.notation.size()>0:text("기보  "+" ".join(rules.notation.slice(maxi(0,rules.notation.size()-8))),Vector2(44,s.y-20),16,muted)
func wrapped(value:String,r:Rect2,fs:int,col:Color):
	var line="";var y=r.position.y
	for word in value.split(" "):
		if font.get_string_size(line+word,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x>r.size.x:
			text(line,Vector2(r.position.x,y),fs,col);y+=fs*1.5;line=""
		line+=word+" "
	text(line,Vector2(r.position.x,y),fs,col)
func piece(p:String,at:Vector2,scale_value:float):
	# Original layered vector characters: recognizable silhouettes, expressive faces.
	var white=p==p.to_upper()
	var body=Color("fff4d6") if white else Color("555067")
	var shade=Color("dbca9f") if white else Color("373448")
	var trim=Color("5794a6") if white else Color("bd7085")
	if white and learner.data.settings.get("gold_skin",false):trim=gold
	var t=Transform2D(0,Vector2(scale_value,scale_value),0,at)
	draw_set_transform_matrix(t)
	oval(Vector2(0,6),Vector2(28,10),Color("333c4730"))
	var bounce=sin(clock*2+at.x*.01)*1.5 if learner.data.settings.motion else 0.0
	draw_set_transform_matrix(Transform2D(0,Vector2(scale_value,scale_value),0,at+Vector2(0,bounce)))
	oval(Vector2(0,0),Vector2(24,9),shade)
	box(Rect2(-21,-9,42,10),shade,4)
	draw_colored_polygon(PackedVector2Array([Vector2(-15,-13),Vector2(-10,-42),Vector2(10,-42),Vector2(15,-13)]),body)
	draw_colored_polygon(PackedVector2Array([Vector2(4,-42),Vector2(21,-14),Vector2(6,-10)]),trim)
	oval(Vector2(0,-11),Vector2(21,7),body)
	var kind=p.to_lower()
	if kind=="n":
		draw_colored_polygon(PackedVector2Array([Vector2(-14,-29),Vector2(-7,-58),Vector2(-13,-72),Vector2(4,-67),Vector2(17,-54),Vector2(21,-42),Vector2(4,-39),Vector2(8,-28)]),body)
		draw_line(Vector2(-9,-57),Vector2(-14,-31),trim,6,true)
	elif kind=="r":
		box(Rect2(-18,-57,36,25),body,5)
		for x in [-17,-4,9]:box(Rect2(x,-66,9,16),body,2)
	elif kind=="b":
		draw_colored_polygon(PackedVector2Array([Vector2(0,-76),Vector2(-16,-51),Vector2(0,-36),Vector2(16,-51)]),body)
		draw_line(Vector2(4,-66),Vector2(-3,-55),shade,3,true)
		draw_circle(Vector2(0,-74),4,gold)
	else:
		draw_circle(Vector2(0,-48),17,shade)
		draw_circle(Vector2(-2,-51),16,body)
		if kind in ["q","k"]:
			draw_colored_polygon(PackedVector2Array([Vector2(-18,-61),Vector2(-19,-76),Vector2(-8,-69),Vector2(0,-82),Vector2(8,-69),Vector2(19,-76),Vector2(17,-61)]),gold)
			if kind=="k":draw_line(Vector2(0,-88),Vector2(0,-74),gold,5,true);draw_line(Vector2(-6,-83),Vector2(6,-83),gold,4,true)
	# Eyes and a tiny smile.
	for x in [-6,6]:
		draw_circle(Vector2(x,-49),4,Color("ffffff"))
		draw_circle(Vector2(x+1,-49),2.3,ink)
	draw_arc(Vector2(0,-43),4,.15,PI-.15,12,ink,1.8,true)
	draw_circle(Vector2(-13,-43),3,Color("edb0a280"))
	box(Rect2(-13,-33,26,5),trim,2)
	draw_set_transform_matrix(Transform2D.IDENTITY)
func oval(p:Vector2,r:Vector2,c:Color):
	var pts=PackedVector2Array()
	for i in range(40):pts.append(p+Vector2(cos(i*TAU/40),sin(i*TAU/40))*r)
	draw_colored_polygon(pts,c)
func book(at:Vector2,z:float):
	var bob=sin(clock*2)*5 if learner.data.settings.motion else 0
	draw_set_transform_matrix(Transform2D(0,Vector2(z,z),0,at+Vector2(0,bob)))
	oval(Vector2(0,36),Vector2(43,7),Color("354f4220"))
	box(Rect2(-51,-29,102,61),gold,11)
	box(Rect2(-44,-24,42,49),cream,5)
	box(Rect2(2,-24,42,49),cream,5)
	draw_line(Vector2(0,-24),Vector2(0,28),Color("a87840"),3)
	for x in [-20,20]:draw_circle(Vector2(x,-2),6,ink);draw_circle(Vector2(x-2,-4),2,Color.WHITE)
	draw_arc(Vector2(0,5),10,.1,PI-.1,16,ink,3,true)
	draw_set_transform_matrix(Transform2D.IDENTITY)
func draw_book(s:Vector2):
	header("마법의 영어 도감", "행동으로 익힌 표현 · 기록은 이해도의 추정이며 시험 점수가 아니에요",s)
	var ids=learner.review_ids()
	if ids.is_empty():text("첫 모험에서 마법책과 함께 영어를 만나 보세요!",Vector2(60,180),26)
	var cols=3 if s.x>1100 else 2
	var w=(s.x-90)/cols
	var narrow=s.x<1050
	var page_size=6 if narrow else 9
	var visible=ids.slice(book_page*page_size,book_page*page_size+page_size)
	for j in range(visible.size()):
		var e=expression(visible[j]);var record=learner.record(visible[j])
		var x=40+(j%cols)*w;var y=125+(j/cols)*(250 if narrow else 155)
		box(Rect2(x,y,w-16,230 if narrow else 140),cream,18)
		wrapped(e.wordOrSentence,Rect2(x+16,y+35,w-48,70),24 if narrow else 22,ink)
		text(record.familiarityState+" · 듣기 "+str(record.exposureCount)+" · 독립 "+str(record.independentSuccessCount),Vector2(x+16,y+(105 if narrow else 65)),15,muted)
		button("듣기",Rect2(x+14,y+(126 if narrow else 82),90,88 if narrow else 42),"audio:"+visible[j])
		button("행동 복습",Rect2(x+116,y+(126 if narrow else 82),w-148,88 if narrow else 42),"review:"+visible[j],true)
	button("왕국 지도",Rect2(40,s.y-70,200,50),"map")
	if ids.size()>page_size:button("다음 페이지",Rect2(260,s.y-70,200,50),"bookpage")
func draw_settings(s:Vector2):
	header("나에게 맞는 모험", "설정과 진행은 이 기기의 저장 공간에 자동 저장돼요",s)
	var opts=[["sound","영어 음성"],["korean","한국어 도움말"],["motion","캐릭터 애니메이션"]]
	for i in range(opts.size()):
		text(opts[i][1],Vector2(80,180+i*84),26)
		button("켜짐" if learner.data.settings[opts[i][0]] else "꺼짐",Rect2(400,140+i*84,140,56),"toggle:"+opts[i][0],learner.data.settings[opts[i][0]])
	text("모은 보상  "+str(learner.data.rewards.size())+" / 56",Vector2(80,440),25)
	text("일반 미션: 빛의 이동 효과 · 보스: 골드 장식 · 챕터: 지도와 테마",Vector2(80,480),20,muted)
	for t in range(8):
		button(THEME_NAMES[t],Rect2(80+(t%4)*135,510+(t/4)*60,125,50),"theme:"+str(t),int(learner.data.settings.theme)==t,t>0 and not learner.data.completed.has(str(t)+"-8"))
	button("골드 장식 "+("ON" if learner.data.settings.get("gold_skin",false) else "OFF"),Rect2(80,640,250,54),"skin",false,not learner.data.completed.has("1-6"))
	button("돌아가기",Rect2(350,640,220,56),"back",true)
	text("작은 보드: 첫 두 칸 전진 가능 / 승격·캐슬링·앙파상 없음",Vector2(80,720),18,muted)
func draw_ending(s:Vector2):
	book(Vector2(s.x/2,150),1.5)
	centered("왕관의 빛이 돌아왔어요!",Vector2(s.x/2,290),46,ink)
	centered("듣고, 생각하고, 움직인 모든 순간이 왕국을 구했어요.",Vector2(s.x/2,355),24,teal)
	piece("K",Vector2(s.x/2,535),2.1)
	button("자유 체스 대전",Rect2(s.x/2-240,610,230,60),"free",true)
	button("왕국으로 돌아가기",Rect2(s.x/2+10,610,230,60),"map")
func draw_modal(s:Vector2):
	draw_rect(Rect2(Vector2.ZERO,s),Color("203b4580"))
	var w=minf(650,s.x-60);var r=Rect2((s.x-w)/2,s.y/2-200,w,400)
	box(r,cream,28)
	var x=r.position.x;var y=r.position.y
	if modal=="intro":
		centered(chapters[chapter-1].title,Vector2(s.x/2,y+64),32,ink)
		wrapped(chapters[chapter-1].intro,Rect2(x+44,y+127,w-88,100),25,teal)
		button("함께 출발!",Rect2(x+44,y+290,w-88,60),"begin",true)
	elif modal=="success":
		centered("멋진 모험이었어!",Vector2(s.x/2,y+70),36,ink)
		wrapped(chapters[chapter-1].outro if index%8==7 else "새로운 빛을 모았어요. 다음 모험에서도 함께해요!",Rect2(x+44,y+140,w-88,100),25,teal)
		button("다음 모험  →",Rect2(x+44,y+290,w-88,60),"next",true)
	elif modal=="promotion":
		centered("폰이 자랐어요! 새 기물을 골라요.",Vector2(s.x/2,y+70),28,ink)
		for j in range(promotion.size()):button({"q":"퀸","r":"룩","b":"비숍","n":"나이트"}[promotion[j][4]],Rect2(x+30+j*(w-60)/4,y+170,(w-80)/4,70),"promote:"+promotion[j],true)
	else:
		centered("다시 도전해 볼까요?",Vector2(s.x/2,y+70),32,ink)
		wrapped(feedback,Rect2(x+44,y+140,w-88,100),24,teal)
		button("다시 시작",Rect2(x+44,y+290,w-88,60),"restart",true)
func expression(id:String)->Dictionary:
	for e in expressions:
		if e.expressionId==id:return e
	return {}
func say_id(id:String,slow=false,replay=false):
	audio.stop()
	var path="res://assets/audio/"+id+".wav"
	var heard=learner.data.settings.sound and ResourceLoader.exists(path)
	if heard:
		audio.stream=load(path);audio.pitch_scale=.82 if slow else 1.0;audio.play()
	if not expression(id).is_empty():learner.expose(id,replay,heard)
	learner.save()
func speak_mission():
	var token=generation
	var words=[]
	for e in expressions:
		if int(e.get("chapter",0))==chapter:words.append(e.expressionId)
	var word=""
	if words.size()>0:word=words[(index%8)%words.size()]
	# Due vocabulary is reviewed in later missions without repeating it back-to-back.
	if index%8>=4:
		for id in learner.review_ids():
			var e=expression(id)
			if e.has("chapter") and int(e.chapter)<=chapter and id!=last_review_word:
				word=id;break
	if word!="":
		introducing=expression(word).wordOrSentence+"  ·  "+expression(word).meaning
		say_id(word);last_review_word=word
		await get_tree().create_timer(1.8).timeout
		if token!=generation:return
	introducing=""
	say_id(missions[index].englishExpressionIds[0])
func start_mission(i:int,resume=false):
	generation+=1;busy=false;index=i;chapter=int(missions[i].chapter)
	selected=-1;mistakes=0;feedback="";modal="";promotion=[];anim_t=1;target_evidence=false;last_move="";introducing=""
	rules=Rules.new();rules.bridge=true
	var m=missions[i]
	rules.load_fen(m.initialPosition,int(m.boardSize))
	var e=learner.record(m.englishExpressionIds[0])
	e.audioHeard=false
	hints=0 if e.familiarityState in ["PRACTICING","FAMILIAR","REVIEW"] else 1
	was_assisted=hints>0;korean_used=learner.data.settings.korean
	if resume and learner.data.current.get("id","")==m.id:
		var saved=learner.data.current
		rules.load_fen(saved.fen,int(m.boardSize))
		rules.history=saved.get("history",[]);rules.positions=saved.get("positions",[]);rules.notation=saved.get("notation",[])
	screen="play";learner.data.lastMission=index
	if i%8==0 and not resume:modal="intro"
	else:speak_mission()
	persist()
	if rules.turn=="b" and m.type=="GAME":ai_turn()
func persist():
	learner.data.current={"id":missions[index].id,"fen":rules.fen(),"history":rules.history,"positions":rules.positions,"notation":rules.notation}
	learner.save()
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:tap(event.position)
	elif event is InputEventScreenTouch and event.pressed:tap(event.position)
func tap(p:Vector2):
	for i in range(buttons.size()-1,-1,-1):
		var b=buttons[i]
		if b.r.has_point(p):
			if not b.disabled:
				if modal!="" and not (b.action in ["begin","next","restart"] or b.action.begins_with("promote:")):return
				action(b.action)
			return
	if screen!="play" or modal!="" or busy or rules.turn!="w":return
	for i in range(rules.n*rules.n):
		if Geometry2D.is_point_in_polygon(p,poly(i)):
			var current=missions[index]
			var target=current.objective.target
			var identified=(target!="" and i==rules.square(target)) or (current.type=="CAPTURE" and rules.cells[i]=="p")
			if identified:
				learner.selected(current.englishExpressionIds[0],was_assisted,korean_used);target_evidence=true;learner.save()
			if rules.color(rules.cells[i])=="w":
				selected=i
				var m=missions[index]
				if m.type in ["MOVE","SAFE_MOVE","ESCAPE_CHECK"] and m.objective.piece!="" and rules.cells[i].to_lower()==m.objective.piece:
					learner.selected(m.englishExpressionIds[0],was_assisted,korean_used);target_evidence=true
				return
			if selected>=0:
				var options=[]
				for move in rules.legal():
					if rules.square(move.substr(0,2))==selected and rules.square(move.substr(2,2))==i:options.append(move)
				if options.size()>1:promotion=options;modal="promotion"
				elif options.size()==1:player_move(options[0])
				else:feedback="그 칸으로 갈 수 없어요. 초록 점을 살펴보세요.";learner.chess(missions[index].id).wrongCount+=1
			return
func action(a:String):
	if a=="home":screen="home";modal=""
	elif a=="continue":review=false;free_play=false;start_mission(int(learner.data.lastMission),true)
	elif a=="map":screen="map";modal="";map_page=0 if chapter<=4 else 1
	elif a=="mappage":map_page=1-map_page
	elif a=="book":screen="book";modal="";book_page=0
	elif a=="bookpage":book_page=(book_page+1)%int(ceil(learner.review_ids().size()/(6.0 if size_now().x<1050 else 9.0)))
	elif a=="settings":screen="settings"
	elif a=="back":screen="play" if learner.data.current.size()>0 else "home"
	elif a.begins_with("mission:"):review=false;free_play=false;start_mission(int(a.split(":")[1]))
	elif a=="begin":modal="";speak_mission()
	elif a in ["listen","slow"]:say_id(missions[index].englishExpressionIds[0],a=="slow",true)
	elif a=="hint":
		hints=mini(3,hints+1);was_assisted=true;learner.chess(missions[index].id).hintCount+=1
		if missions[index].type=="GAME":feedback="추천하는 수: "+rules.choose_ai(true)
		elif hints>=2:
			var sol=Goals.solutions(rules,missions[index])
			if sol.size():selected=rules.square(sol[0].substr(0,2))
		learner.save()
	elif a=="restart":start_mission(index)
	elif a=="undo" and not busy:
		rules.undo()
		if rules.turn=="b":rules.undo()
		selected=-1;feedback="천천히 다시 생각해 보세요.";was_assisted=true;persist()
	elif a=="next":
		modal=""
		if review:screen="book"
		elif index==55:screen="ending"
		else:start_mission(index+1)
	elif a.begins_with("promote:"):modal="";player_move(a.split(":")[1])
	elif a.begins_with("audio:"):say_id(a.substr(6),false,true)
	elif a.begins_with("review:"):
		var id=a.substr(7)
		var expr=expression(id)
		if expr.has("practiceMission"):
			review=true;start_mission(int(expr.practiceMission));say_id(id,false,true);return
		for i in range(missions.size()):
			if id in missions[i].englishExpressionIds and missions[i].type!="GAME":review=true;start_mission(i);break
	elif a.begins_with("toggle:"):
		var key=a.substr(7);learner.data.settings[key]=not learner.data.settings[key];learner.save()
		if key=="sound" and not learner.data.settings.sound:audio.stop()
		if key=="korean" and learner.data.settings.korean:korean_used=true
	elif a=="skin":learner.data.settings.gold_skin=not learner.data.settings.get("gold_skin",false);learner.save()
	elif a.begins_with("theme:"):learner.data.settings.theme=int(a.substr(6));learner.save()
	elif a=="free":review=true;free_play=true;start_mission(55)
func animate(move:String,p:String):
	anim_from=rules.square(move.substr(0,2));anim_to=rules.square(move.substr(2,2));anim_piece=p
	anim_t=0 if learner.data.settings.motion else 1
func player_move(move:String):
	if busy:return
	var m=missions[index];var token=generation
	var before=rules.cells.duplicate();var old=rules.fen()
	var c=learner.chess(m.id);c.attemptCount+=1
	var p=rules.cells[rules.square(move.substr(0,2))]
	if m.type=="CAPTURE" and before[rules.square(move.substr(2,2))]=="p":
		learner.selected(m.englishExpressionIds[0],was_assisted,korean_used);target_evidence=true
	if not rules.play(move):return
	c.legalMoveCount+=1;selected=-1;busy=true
	animate(move,p);last_move=move
	await get_tree().create_timer(.5).timeout
	if token!=generation:return
	if m.type=="GAME":
		persist()
		if finish_game():busy=false;return
		await ai_turn();return
	if Goals.success(rules,m,move,before):win();busy=false;return
	c.wrongCount+=1;mistakes+=1
	var replies=rules.legal()
	if replies.size():
		var reply=replies.pick_random()
		for candidate in replies:
			if rules.cells[rules.square(candidate.substr(2,2))]!="":reply=candidate;break
		var enemy=rules.cells[rules.square(reply.substr(0,2))]
		rules.play(reply);animate(reply,enemy)
		feedback="상대의 가능한 응수를 살펴보세요. 아직 미션 목표를 이루지 못했어요."
	else:feedback="이 배치는 "+("체크메이트" if rules.check("b") else "더 움직일 수 없는 상태")+"예요. 이번 미션의 목표를 다시 살펴봐요."
	say_id("retry")
	await get_tree().create_timer(1.8).timeout
	if token!=generation:return
	rules.load_fen(old,rules.n);rules.history.clear();rules.positions.clear();rules.notation.clear()
	hints=mini(3,1+mistakes);was_assisted=true;busy=false;anim_t=1
	persist()
func ai_turn():
	busy=true
	var token=generation
	await get_tree().create_timer(.65).timeout
	if token!=generation:return
	var move=rules.choose_ai(false)
	if move!="":
		var p=rules.cells[rules.square(move.substr(0,2))]
		rules.play(move);animate(move,p)
	persist();busy=false
	if not finish_game() and rules.check("w"):feedback="왕이 체크를 받았어요! 왕을 지켜 주세요.";say_id("check")
func finish_game()->bool:
	var status=rules.status()
	if status=="playing":return false
	if status=="checkmate" and rules.turn=="b":win()
	else:
		feedback="왕이 체크메이트 되었어요. 다시 도전해요!" if status=="checkmate" else "무승부예요 ("+status+"). 다시 도전해요!"
		modal="retry"
	return true
func win():
	generation+=1
	introducing=""
	if not free_play:learner.complete(missions[index],was_assisted or not target_evidence,korean_used)
	if not review:learner.data.lastMission=mini(55,index+1)
	learner.data.current={};learner.save()
	modal="success";feedback="Great move!";say_id("praise")
