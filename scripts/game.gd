extends Node2D
const Rules=preload("res://scripts/rules.gd")
const Goals=preload("res://scripts/objectives.gd")
const MAGIC_BOOK=preload("res://assets/characters/magic-book-v1.png")
const Learning=preload("res://scripts/learning.gd")
var font=FontVariation.new()
var missions: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/missions.json"))
var chapters: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapters.json"))
var expressions: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/expressions.json"))
var learner=Learning.new()
var rules=Rules.new()
var screen="home"
var settings_return="home"
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
var board_view=preload("res://scripts/board_3d.gd").new()
var board_area=Rect2()
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
var lesson_step=0
var demo=false
var demo_snapshot={}
var demo_text=""
var demo_heading=""
var demo_links=[]
var demo_focus=[]
var demo_waiting=false
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
	add_child(board_view)
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
		var state={"screen":screen,"mission":missions[index].id,"modal":modal,"completed":learner.data.completed.size(),"turn":rules.turn,"audioPlaying":audio.playing,"busy":busy,"demo":demo,"demoHeading":demo_heading,"demoWaiting":demo_waiting,"fen":rules.fen(),"selected":selected,"squares":square_centers(),"actors":actor_centers()}
		JavaScriptBridge.eval("window.CQ.state="+JSON.stringify(state))
	if anim_t<1:anim_t=minf(1,anim_t+delta*(.55 if demo else 2.5))
	board_view.moving_from=anim_from;board_view.moving_to=anim_to
	board_view.moving_progress=anim_t;board_view.moving_letter=anim_piece
	board_view.animate(delta)
	board_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS if screen in ["play","home","ending"] else SubViewport.UPDATE_DISABLED
	queue_redraw()
func square_centers()->Array:
	var result=[]
	if screen=="play":
		for i in range(rules.n*rules.n):
			var p=point(i%rules.n,i/rules.n);result.append([p.x,p.y])
	return result
func actor_centers()->Dictionary:
	var result={}
	if screen=="play":
		for i in board_view.pieces:
			var p=board_view.portrait_rect(i).get_center();result[str(i)]=[p.x,p.y]
	return result
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
func gem(at:Vector2,scale_value:float=1.0):
	var points=PackedVector2Array([at+Vector2(0,-7)*scale_value,at+Vector2(6,0)*scale_value,at+Vector2(0,7)*scale_value,at+Vector2(-6,0)*scale_value])
	draw_colored_polygon(points,Color("e8ba69"))
	draw_line(at+Vector2(0,-5)*scale_value,at+Vector2(-3,0)*scale_value,Color("fff1bd"),2,true)
func fantasy_panel(r:Rect2,muted_panel=false):
	# Rounded book-cover rim, raised parchment and brass corner fittings.
	box(Rect2(r.position+Vector2(0,6),r.size),Color("69553a25"),24)
	box(r,Color("8a6a4e") if not muted_panel else Color("a4aa91"),24)
	box(r.grow(-3),Color("e5bd7b") if not muted_panel else Color("c5c9ae"),21)
	box(r.grow(-7),Color("fff4d7") if not muted_panel else Color("e4e5d2"),18)
	box(Rect2(r.position+Vector2(12,11),Vector2(r.size.x-24,28)),Color("fffbee90"),12)
	for x in [r.position.x+12,r.end.x-12]:
		for y in [r.position.y+13,r.end.y-13]:
			draw_circle(Vector2(x,y),3.5,Color("a67842"));draw_circle(Vector2(x-1,y-1),1.5,Color("ffe5a3"))
	var middle=Vector2(r.get_center().x,r.position.y+5)
	gem(middle,.75)
func button(label:String,r:Rect2,action:String,accent=false,disabled=false):
	var edge=Color("a8af98") if disabled else Color("295b60") if accent else Color("a87b45")
	var face=Color("dce0cf") if disabled else Color("478d87") if accent else Color("f4dfaf")
	box(Rect2(r.position+Vector2(0,4),r.size),Color("5d574b20"),15)
	box(r,edge,15)
	box(Rect2(r.position+Vector2(2,2),r.size-Vector2(4,6)),face,13)
	draw_line(r.position+Vector2(14,5),Vector2(r.end.x-14,r.position.y+5),Color("ffffff50"),2,true)
	var fs=28 if size_now().x<1050 else 22
	while fs>14 and font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x>r.size.x-18:fs-=1
	centered(label,r.get_center()+Vector2(0,fs*.34-1),fs,Color("8b9380") if disabled else Color("fff6d9") if accent else Color("514630"))
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
	if learner.save_error:text("Could not save. Please check your device storage.",Vector2(20,s.y-16),18,Color("a13d38"))
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
	var hero_rect=Rect2(s.x*.42,270,s.x*.57,410) if s.x>=1050 else Rect2(20,s.y*.58,s.x-40,s.y*.38)
	board_view.configure(4,hero_rect,0)
	var cast=["R","N","B","Q","","P","K","","","","","","","","",""]
	board_view.update_position(cast,-1,[],false,learner.data.settings.motion)
	board_view.update_markers([],-1,-1)
	draw_texture_rect(board_view.get_texture(),hero_rect,false)
	book(center+Vector2(0,-173 if s.x<1100 else -190),1.3)
func header(title:String,sub:String,s:Vector2):
	box(Rect2(28,22,s.x-56,82),Color("fff4d7d9"),24,Color("d9bc82"))
	gem(Vector2(46,51),1.1)
	text(title,Vector2(64,57),30)
	text(sub,Vector2(46,88),15 if s.x<1050 else 17,muted)
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
		fantasy_panel(Rect2(x,y,w-18,480 if narrow else 213),not unlocked)
		text("0"+str(c+1)+" / "+chapters[c].subtitle,Vector2(x+18,y+34),16,teal)
		text(chapters[c].title,Vector2(x+18,y+72),22)
		for j in range(8):
			var done=learner.data.completed.has(str(c+1)+"-"+str(j+1))
			var open=unlocked and (j==0 or learner.data.completed.has(str(c+1)+"-"+str(j)))
			var cells_per_row=2 if narrow else 4
			button(("★" if done else "대국" if c==6 and j>=5 else str(j+1)),Rect2(x+16+(j%cells_per_row)*((w-50)/cells_per_row),y+94+(j/cells_per_row)*(94 if narrow else 52),(w-65)/cells_per_row,88 if narrow else 44),"mission:"+str(c*8+j),done,not open)
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
	board_area=Rect2(8,86,s.x-16,s.y-408) if narrow else Rect2(8,70,s.x-272,s.y-94)
	panel=Rect2(20,s.y-310,s.x-40,278) if narrow else Rect2(s.x-258,76,246,s.y-104)
	board_view.configure(rules.n,board_area,int(learner.data.settings.theme))
	tile=Vector2(board_area.size.x/(rules.n+1.0),board_area.size.y/(rules.n+1.0))
func point(file:float,rank:float)->Vector2:return board_view.projected(file,rank)
func poly(i:int)->PackedVector2Array:return board_view.polygon(i)
func active_mission()->Dictionary:
	var base=missions[index]
	if not base.has("sequence"):return base
	var m=base.duplicate();m.objective=base.objective.duplicate()
	var step=base.sequence[clampi(lesson_step,0,base.sequence.size()-1)]
	m.objective.merge(step.objective,true);m.briefing=step.briefing;m.type=step.get("type",base.type)
	return m
func puzzle_remaining()->int:
	return int(missions[index].get("mateLimit",0))-int((rules.history.size()+1)/2)
func puzzle_moves()->Array:
	var fields=rules.fen().split(" ")
	var key=" ".join(fields.slice(0,4))+"|"+str(puzzle_remaining())
	return missions[index].get("puzzleBook",{}).get(key,[])
func draw_play(s:Vector2):
	var m=active_mission()
	text(chapters[m.chapter-1].subtitle+" · QUEST "+str(index%8+1)+" / 8",Vector2(24,36),23,ink)
	button("Home",Rect2(s.x-104,12,88,42),"home")
	layout_board(s)
	var destinations=[]
	if selected>=0 and not busy:
		for move in rules.legal():
			if rules.square(move.substr(0,2))==selected:destinations.append(rules.square(move.substr(2,2)))
	var checked=[]
	for i in range(rules.cells.size()):
		if rules.cells[i].to_lower()=="k" and rules.check(rules.color(rules.cells[i])):checked.append(i)
	board_view.gold_skin=learner.data.settings.get("gold_skin",false)
	board_view.update_position(rules.cells,selected,checked,modal=="success",learner.data.settings.motion)
	var target=rules.square(m.objective.target) if hints>0 and m.objective.target!="" else -1
	board_view.update_markers(destinations,selected,target)
	draw_texture_rect(board_view.get_texture(),board_area,false)
	# Coordinates and badges stay in screen space, anchored to the actual 3D board.
	for x in range(rules.n):
		centered("abcdefgh"[x],point(x,-.69)+Vector2(0,6),16,Color("355f84"))
		var back_coord=point(x,rules.n-.31)-Vector2(0,(point(0,1)-point(0,0)).length()*.92 if rules.cells[(rules.n-1)*rules.n+x]!="" else 5)
		centered("abcdefgh"[x],back_coord,16,Color("355f84"))
	for rank in range(rules.n):
		centered(str(rank+1),point(-.70,rank)+Vector2(0,5),16,muted)
		centered(str(rank+1),point(rules.n-.30,rank)+Vector2(0,5),16,muted)
	# One unobtrusive forward arrow makes pawn direction explicit even in empty training boards.
	var arrow_start=point(-.92,.15);var arrow_end=point(-.92,1.1)
	draw_line(arrow_start,arrow_end,Color("468fc0"),3,true)
	var d=(arrow_end-arrow_start).normalized();var side=Vector2(-d.y,d.x)
	draw_colored_polygon(PackedVector2Array([arrow_end,arrow_end-d*12+side*6,arrow_end-d*12-side*6]),Color("468fc0"))
	if not demo and m.has("previousMove") and rules.history.is_empty():
		var a=rules.square(m.previousMove.substr(0,2));var b=rules.square(m.previousMove.substr(2,2))
		var start=point(a%rules.n,a/rules.n);var end=point(b%rules.n,b/rules.n)
		var direction=(end-start).normalized();var wing=Vector2(-direction.y,direction.x)
		draw_line(start,end,Color("b287df"),4,true)
		draw_colored_polygon(PackedVector2Array([end,end-direction*14+wing*7,end-direction*14-wing*7]),Color("b287df"))
	if not demo and hints>=3 and m.type!="GAME":
		var solution=Goals.solutions(rules,m)
		if solution.size()>0:
			var a=rules.square(solution[0].substr(0,2));var b=rules.square(solution[0].substr(2,2))
			draw_line(point(a%rules.n,a/rules.n),point(b%rules.n,b/rules.n),Color("ffe19c"),5,true)
	if hints>0 and m.has("threat"):
		var a=rules.square(m.threat[0]);var b=rules.square(m.threat[1])
		if rules.attacks(a,b):
			var start=point(a%rules.n,a/rules.n);var end=point(b%rules.n,b/rules.n)
			draw_line(start,end,Color("d66f4280"),3,true)
	if demo:
		for pair in demo_links:
			var start=point(pair[0]%rules.n,pair[0]/rules.n);var end=point(pair[1]%rules.n,pair[1]/rules.n)
			var direction=(end-start).normalized();var wing=Vector2(-direction.y,direction.x)
			draw_line(start,end,Color("fff1ba"),7,true);draw_line(start,end,Color("c48640"),3,true)
			draw_colored_polygon(PackedVector2Array([end,end-direction*16+wing*7,end-direction*16-wing*7]),gold)
		for square in demo_focus:
			var at=point(square%rules.n,square/rules.n)
			draw_arc(at,19,0,TAU,32,gold,3,true)
	var px=panel.position.x;var py=panel.position.y;var pw=panel.size.x
	fantasy_panel(panel)
	draw_line(Vector2(px+20,py+43),Vector2(px+pw-20,py+43),Color("dbbd7f"),1.5,true)
	var compact=s.x<1050
	var names={"p":"Pawn","n":"Knight","b":"Bishop","r":"Rook","q":"Queen","k":"King"}
	var caption=rules.coord(selected)+" · "+names.get(rules.cells[selected].to_lower(),"")+" selected" if selected>=0 else ("STEP "+str(lesson_step+1)+" / "+str(m.sequence.size()) if m.has("sequence") else "MATE IN "+str(maxi(0,puzzle_remaining())) if m.has("mateLimit") else m.get("topic","Choose a piece"))
	if demo:caption=demo_heading
	text(caption,Vector2(px+16,py+27),14 if selected<0 and m.has("topic") else 17,teal)
	var expr=expression(m.englishExpressionIds[0])
	wrapped(expr.wordOrSentence,Rect2(px+16,py+68,pw-32,90),24,ink)
	var body=m.hints[mini(maxi(hints-1,0),2)] if hints else (expr.meaning if learner.data.settings.korean else "Listen. Think. Move.")
	if learner.data.settings.korean and m.has("briefing") and hints<2:body=m.briefing
	if demo:body=demo_text
	wrapped(body,Rect2(px+16,py+(96 if compact else 154),pw-32,100),18,muted)
	var by=py+(148 if compact else 290)
	var labels=["▶ Listen","Slow","Hint","Undo" if m.type=="GAME" else "Restart","Map","Settings"]
	var actions=["listen","slow","hint","undo" if m.type=="GAME" else "restart","map","settings"]
	if has_demo():labels[1]="Watch";actions[1]="watch"
	if demo:
		labels=["Replay","Next","Try now"] if demo_heading!="YOUR TURN" else ["Replay","Try now"]
		actions=["watch","demo_next","practice"] if demo_heading!="YOUR TURN" else ["watch","practice"]
	var columns=3 if compact else 2
	var bw=(pw-32-(columns-1)*8)/columns
	for j in range(labels.size()):
		button(labels[j],Rect2(px+16+(j%columns)*(bw+8),by+(j/columns)*54,bw,46),actions[j],actions[j] in ["practice","demo_next","hint"],actions[j]=="demo_next" and not demo_waiting)
	wrapped(feedback,Rect2(px+16,py+266 if compact else by+192,pw-32,66),16,teal)
	if compact:book(Vector2(px+pw-48,py+37),.32)
	else:book(Vector2(px+pw*.5,panel.end.y-86),.65)
	if rules.n==8 and rules.notation.size()>0:text("Moves  "+" ".join(rules.notation.slice(maxi(0,rules.notation.size()-8))),Vector2(44,s.y-20),16,muted)
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
	var moving=learner.data.settings.motion
	var bob=sin(clock*1.7)*4 if moving else 0.0
	var tilt=sin(clock*1.15)*.025 if moving else 0.0
	draw_set_transform_matrix(Transform2D(0,Vector2(z,z),0,at))
	oval(Vector2(0,78),Vector2(34-bob*.4,5),Color("354f4218"))
	draw_circle(Vector2(0,2),62,Color("eac77d0c"))
	draw_set_transform_matrix(Transform2D(tilt,Vector2(z,z),0,at+Vector2(0,bob)))
	var extent=Vector2(160,160.0*MAGIC_BOOK.get_height()/MAGIC_BOOK.get_width())
	draw_texture_rect(MAGIC_BOOK,Rect2(-extent*.5,extent),false)
	for i in range(3):
		var phase=clock*.8+i*2.1 if moving else i*2.1
		var star=Vector2(-65+i*64,-34+sin(phase)*9)
		var glow=Color("e9bd65");glow.a=.25+(.15*(sin(phase)+1) if moving else .15)
		draw_line(star-Vector2(0,3),star+Vector2(0,3),glow,1.5,true)
		draw_line(star-Vector2(3,0),star+Vector2(3,0),glow,1.5,true)
	draw_set_transform_matrix(Transform2D.IDENTITY)
func draw_book(s:Vector2):
	header("마법의 영어 도감", "행동으로 익힌 표현 · 기록은 이해도의 추정이며 시험 점수가 아니에요",s)
	var ids=learner.review_ids()
	if ids.is_empty():
		fantasy_panel(Rect2(40,130,s.x-80,390))
		centered("첫 모험에서 새로운 말을 만나 보세요!",Vector2(s.x/2,185),25,teal)
		book(Vector2(s.x/2,305),.95)
		button("첫 표현 만나기",Rect2(s.x/2-130,432,260,56),"continue",true)
	var cols=3 if s.x>1100 else 2
	var w=(s.x-90)/cols
	var narrow=s.x<1050
	var page_size=6 if narrow else 9
	var visible=ids.slice(book_page*page_size,book_page*page_size+page_size)
	for j in range(visible.size()):
		var e=expression(visible[j]);var record=learner.record(visible[j])
		var x=40+(j%cols)*w;var y=125+(j/cols)*(250 if narrow else 155)
		fantasy_panel(Rect2(x,y,w-16,230 if narrow else 140))
		wrapped(e.wordOrSentence,Rect2(x+16,y+35,w-48,70),24 if narrow else 22,ink)
		text({"NEW":"처음 만난 말","LEARNING":"익히는 중","PRACTICING":"연습하는 말","FAMILIAR":"친숙한 말","REVIEW":"다시 만날 말"}.get(record.familiarityState,"연습하는 말")+" · 듣기 "+str(record.exposureCount)+" · 혼자 "+str(record.independentSuccessCount),Vector2(x+16,y+(105 if narrow else 65)),15,muted)
		button("듣기",Rect2(x+14,y+(126 if narrow else 82),90,88 if narrow else 42),"audio:"+visible[j])
		button("행동 복습",Rect2(x+116,y+(126 if narrow else 82),w-148,88 if narrow else 42),"review:"+visible[j],true)
	button("왕국 지도",Rect2(40,s.y-70,200,50),"map")
	if ids.size()>page_size:button("다음 페이지",Rect2(260,s.y-70,200,50),"bookpage")
func draw_settings(s:Vector2):
	header("모험가의 쉼터", "소리와 움직임을 고르고, 모은 보상으로 왕국을 꾸며요",s)
	var narrow=s.x<1050
	var left=Rect2(40,130,s.x-80 if narrow else s.x*.44,310)
	var right=Rect2(40 if narrow else s.x*.5,464 if narrow else 130,s.x-80 if narrow else s.x*.5-40,438)
	fantasy_panel(left);fantasy_panel(right)
	text("마법의 목소리와 도움말",left.position+Vector2(24,40),25,ink)
	var opts=[["sound","영어 음성"],["korean","한국어 도움말"],["motion","캐릭터 움직임"]]
	for i in range(opts.size()):
		var y=left.position.y+67+i*67
		text(opts[i][1],Vector2(left.position.x+24,y+34),23,ink)
		button("켜짐" if learner.data.settings[opts[i][0]] else "꺼짐",Rect2(left.end.x-146,y,120,49),"toggle:"+opts[i][0],learner.data.settings[opts[i][0]])
	text("AI 생성 음성 · OpenAI",left.position+Vector2(24,285),15,muted)
	if not narrow:book(Vector2(left.get_center().x,510),.72)
	text("나의 보물 상자",right.position+Vector2(24,40),25,ink)
	text("모은 보상  "+str(learner.data.rewards.size())+" / 56",right.position+Vector2(24,76),19,teal)
	wrapped("왕국을 완성하면 새 색이 열려요. 폰의 승격을 배우면 골드 장식을 얻어요.",Rect2(right.position+Vector2(24,110),Vector2(right.size.x-48,70)),18,muted)
	var cols=4;var width=(right.size.x-58)/cols
	for t in range(8):
		button(THEME_NAMES[t],Rect2(right.position.x+24+(t%cols)*(width+3),right.position.y+176+(t/cols)*62,width-3,52),"theme:"+str(t),int(learner.data.settings.theme)==t,t>0 and not learner.data.completed.has(str(t)+"-8"))
	button("골드 장식 "+("ON" if learner.data.settings.get("gold_skin",false) else "OFF"),Rect2(right.position.x+24,right.position.y+318,right.size.x-48,55),"skin",false,not learner.data.completed.has("1-6"))
	text("보상은 모험을 마칠 때마다 차곡차곡 쌓여요.",right.position+Vector2(24,409),17,muted)
	var reset=Rect2(40,932 if narrow else 598,s.x-80,158 if narrow else 112)
	fantasy_panel(reset)
	text("새로운 모험",reset.position+Vector2(24,35),23,ink)
	wrapped("완료 기록·학습 기록·보상을 지우고 처음부터 시작해요.",Rect2(reset.position+Vector2(24,65),Vector2(reset.size.x-48 if narrow else reset.size.x-310,60)),17,muted)
	button("진행도 초기화",Rect2(reset.position.x+24 if narrow else reset.end.x-248,reset.position.y+94 if narrow else reset.position.y+30,224,48),"reset_prompt")
	button("모험으로 돌아가기",Rect2(40,s.y-72,280,52),"back",true)
func draw_ending(s:Vector2):
	book(Vector2(s.x/2,150),1.5)
	centered("The crown shines again!",Vector2(s.x/2,290),46,ink)
	centered("You listened. You learned. You saved the kingdom!",Vector2(s.x/2,355),24,teal)
	var parade=Rect2(s.x/2-320,380,640,210)
	board_view.configure(4,parade,7)
	board_view.update_position(["R","N","B","Q","","P","K","","","","","","","","",""],-1,[],true,learner.data.settings.motion)
	board_view.update_markers([],-1,-1)
	draw_texture_rect(board_view.get_texture(),parade,false)
	button("Play chess",Rect2(s.x/2-240,610,230,60),"free",true)
	button("Back to the kingdom",Rect2(s.x/2+10,610,230,60),"map")
func popup_message(won:bool)->String:
	var m=missions[index]
	if won:
		var special={"1-2":"Two squares on the first move! Both squares must be clear.","1-5":"Pawns take pieces on a diagonal, not straight ahead.","1-8":"Too late for en passant! You used a normal pawn capture.","2-8":"A knight was the right choice! It checks the king and attacks the rook.","3-5":"Your rooks work together on one line.","3-6":"Your rook reached the seventh row. It can attack pawns from the side.","4-4":"Your pawn moved out of the way. Now your bishop can attack.","5-7":"Checkmate! Without check, a side with no legal move gets a draw.","6-6":"The king's path must be safe. You used the safe side.","6-7":"No castling while in check! You moved your king to safety."}
		if special.has(m.id):return special[m.id]
		if m.has("sequence"):return "You finished the path! Every step helped."
		return {"PROMOTION":"Your pawn has a new power! Choose the piece that helps your plan.","EN_PASSANT":"You caught the pawn just in time! En passant is only for the very next move.","CASTLE":"Your king and rook moved as a team. That was one move!","PIN":"The knight must stay. Moving it would leave its king in check.","FORK":"One piece, two threats! Your attacking piece is safe.","SKEWER":"The king must move away. Then you can take the piece behind it.","ATTACK":"You made a safe attack! The other side cannot take your piece next turn.","PROTECT":"Your friend has help! If it is taken, you can take that piece back.","CHECKMATE":"Checkmate! The king cannot escape. Great teamwork!","GAME":"You won! The lost crown is one step closer."}.get(m.type,"Great move! You found the way. Ready for the next adventure?")
	var stories=["The garden gate is shut. Help the little pawn carry a letter.","The bridge is broken. Our knight can jump across!","The magic tower needs help. Find a path for the rook.","Light the secret temple. Follow the bishop's path.","The queen is back! Help her friends reach the castle.","The king needs your help. Keep the castle safe.","The lost crown is near. Look for a clever plan!"]
	var goal="Look at the board. Find a safe move."
	if m.has("sequence"):goal="Follow the path. Finish each step."
	elif m.has("mateLimit"):goal="Win in "+str(m.mateLimit)+" moves or fewer."
	elif m.type=="MOVE":goal="Move to "+m.objective.destination+"."
	elif m.type=="CAPTURE":goal="Take the piece on "+m.objective.target+"." if m.objective.target!="" else "Take an enemy piece."
	else:goal={"PROMOTION":"Reach the last row. Choose a new piece.","EN_PASSANT":"Watch the pawn's special capture. Then try it!","CASTLE":"Watch the king and rook move together. Then try it!","PIN":"Can you keep the knight in front of its king?","FORK":"Attack two pieces with one safe move.","SKEWER":"Check the king. Find the piece behind it.","ATTACK":"Make an attack. Keep your piece safe.","PROTECT":"Help your friend. Be ready to take back.","CHECKMATE":"Put the king in check with no way out.","GAME":"Play a full game. Keep your king safe!"}.get(m.type,goal)
	return stories[int(m.chapter)-1]+" "+goal
func draw_modal(s:Vector2):
	draw_rect(Rect2(Vector2.ZERO,s),Color("203b4580"))
	var w=minf(650,s.x-60);var r=Rect2((s.x-w)/2,s.y/2-200,w,400)
	fantasy_panel(r)
	var x=r.position.x;var y=r.position.y
	if modal=="intro":
		centered(chapters[chapter-1].subtitle,Vector2(s.x/2,y+64),32,ink)
		wrapped(popup_message(false),Rect2(x+44,y+127,w-88,100),25,teal)
		button("Let’s go!",Rect2(x+44,y+290,w-88,60),"begin",true)
	elif modal=="success":
		centered("Great adventure!",Vector2(s.x/2,y+70),36,ink)
		wrapped(popup_message(true),Rect2(x+44,y+140,w-88,100),25,teal)
		button("Next quest  →",Rect2(x+44,y+290,w-88,60),"next",true)
	elif modal=="reset":
		centered("Start a new adventure?",Vector2(s.x/2,y+65),30,ink)
		wrapped("This will erase your progress, word practice, rewards, and current game. Your sound and help settings will stay. You cannot undo this.",Rect2(x+40,y+125,w-80,150),23,muted)
		button("Keep my progress",Rect2(x+32,y+300,(w-76)/2,58),"reset_cancel",true)
		button("Erase and start",Rect2(x+44+(w-76)/2,y+300,(w-76)/2,58),"reset_confirm")
	elif modal=="promotion":
		centered("Promotion! Choose a piece.",Vector2(s.x/2,y+70),28,ink)
		for j in range(promotion.size()):button({"q":"Queen","r":"Rook","b":"Bishop","n":"Knight"}[promotion[j][4]],Rect2(x+30+j*(w-60)/4,y+170,(w-80)/4,70),"promote:"+promotion[j],true)
	else:
		centered("Ready to try again?",Vector2(s.x/2,y+70),32,ink)
		wrapped("Your king needs help. Try a new plan." if rules.check("w") else "This game is a draw. Try again with a new plan.",Rect2(x+44,y+140,w-88,100),24,teal)
		button("Restart",Rect2(x+44,y+290,w-88,60),"restart",true)
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
		await get_tree().create_timer(maxf(1.8,audio.stream.get_length()+.15) if audio.playing else 1.8).timeout
		if token!=generation:return
	introducing=""
	say_id(missions[index].englishExpressionIds[0])
func start_mission(i:int,resume=false):
	demo=false;demo_snapshot={};demo_heading="";demo_links=[];demo_focus=[];demo_waiting=false
	generation+=1;lesson_step=0;busy=false;index=i;chapter=int(missions[i].chapter)
	selected=-1;mistakes=0;feedback="";modal="";promotion=[];anim_t=1;target_evidence=false;last_move="";introducing=""
	rules=Rules.new();rules.bridge=true
	var m=missions[i]
	rules.load_fen(m.initialPosition,int(m.boardSize))
	var e=learner.record(m.englishExpressionIds[0])
	e.audioHeard=false
	hints=0 if e.familiarityState in ["PRACTICING","FAMILIAR","REVIEW"] else 1
	was_assisted=hints>0;korean_used=learner.data.settings.korean
	if resume and learner.data.current.get("id","")==m.id and int(learner.data.current.get("revision",1))==int(m.get("revision",1)):
		var saved=learner.data.current
		lesson_step=clampi(int(saved.get("lessonStep",0)),0,m.get("sequence",[{}]).size()-1)
		rules.load_fen(saved.fen,int(m.boardSize))
		rules.history=saved.get("history",[]);rules.positions=saved.get("positions",[]);rules.notation=saved.get("notation",[])
	if not demo and m.has("previousMove") and rules.history.is_empty():
		last_move=m.previousMove
		feedback="LAST: "+last_move.substr(0,2)+" → "+last_move.substr(2,2)
	screen="play"
	if not review:learner.data.lastMission=index
	if m.get("storyBeat",i%8==0) and not resume:modal="intro"
	elif not (has_demo() and not m.id in learner.data.completed and rules.history.is_empty()):speak_mission()
	persist()
	if modal=="" and has_demo() and not m.id in learner.data.completed and rules.history.is_empty():start_demo()
	if rules.turn=="b" and m.type=="GAME":ai_turn()
func has_demo()->bool:
	return missions[index].id in ["1-7","6-5","6-6"] or missions[index].type in ["PROMOTION","PIN","FORK","SKEWER"]
func finish_demo():
	if not demo:return
	generation+=1
	rules.load_fen(demo_snapshot.fen,rules.n)
	rules.history=demo_snapshot.history.duplicate();rules.positions=demo_snapshot.positions.duplicate();rules.notation=demo_snapshot.notation.duplicate()
	demo=false;busy=false;anim_t=1;selected=-1;demo_heading="";demo_links=[];demo_focus=[];demo_waiting=false
	feedback="Your turn!";persist()
func demo_pause(seconds:float,token:int)->bool:
	await get_tree().create_timer(maxf(2.8,seconds*1.8)).timeout
	if not demo or generation!=token:return false
	demo_waiting=true;feedback="Take your time · Tap Next"
	while demo and generation==token and demo_waiting:
		await get_tree().process_frame
	return demo and generation==token
func start_demo():
	if busy and not demo:return
	if demo:finish_demo()
	if not has_demo():return
	generation+=1
	var token=generation
	demo_snapshot={"fen":rules.fen(),"history":rules.history.duplicate(),"positions":rules.positions.duplicate(),"notation":rules.notation.duplicate()}
	demo_links=[];demo_focus=[];demo_waiting=false;anim_t=1
	demo=true;busy=true;selected=-1;modal="";introducing="";audio.stop();feedback="Watch first · Then try"
	var m=missions[index]
	if m.id=="1-7":
		rules.load_fen(m.previousPosition)
		demo_heading="WATCH 1 / 3";demo_text="상대 폰이 처음 자리에서 두 칸 앞으로 와요."
		if not await demo_pause(1.2,token):return
		rules.apply_raw("d7d5");animate("d7d5","p")
		if not await demo_pause(1.8,token):return
		demo_heading="WATCH 2 / 3";demo_text="바로 이번 수! 우리 폰이 빈 대각선 칸 d6으로 가요."
		# Keep the victim visible until the capturing pawn lands.
		rules.cells[rules.square("e5")]="";rules.cells[rules.square("d6")]="P";animate("e5d6","P")
		if not await demo_pause(1.3,token):return
		rules.cells[rules.square("d5")]=""
		demo_heading="WATCH 3 / 3";demo_text="지나쳐 온 상대 폰이 잡혔어요. 이 특별한 포획은 바로 다음 수에만 가능해요."
	elif m.type=="CASTLE":
		rules.load_fen(m.initialPosition)
		var kingside=m.id=="6-5"
		var king_move="e1g1" if kingside else "e1c1"
		var rook_move="h1f1" if kingside else "a1d1"
		demo_heading="WATCH 1 / 3";demo_text="왕과 룩이 처음 자리예요. 사이가 비고 왕의 길도 안전해요."
		if not await demo_pause(1.5,token):return
		demo_heading="WATCH 2 / 3";demo_text="왕이 룩 쪽으로 두 칸 가요. 두 기물이 함께 움직이는 한 수예요."
		rules.cells[rules.square("e1")]="";rules.cells[rules.square(king_move.substr(2,2))]="K";animate(king_move,"K")
		if not await demo_pause(1.5,token):return
		demo_heading="WATCH 3 / 3";demo_text="룩은 왕을 넘어 바로 옆에 와요. 순서대로 보여줬지만 둘이 합쳐 한 수, 캐슬링이에요."
		rules.cells[rules.square(rook_move.substr(0,2))]="";rules.cells[rules.square(rook_move.substr(2,2))]="R";animate(rook_move,"R")
	else:
		rules.load_fen(m.initialPosition,int(m.boardSize))
		var solutions=Goals.solutions(rules,m)
		if solutions.is_empty():finish_demo();return
		var move=solutions[0]
		var a=rules.square(move.substr(0,2));var b=rules.square(move.substr(2,2));var piece_letter=rules.cells[a]
		demo_heading="WATCH 1 / 3";demo_focus=[a]
		if m.type=="PROMOTION":demo_text="폰이 끝줄에 닿으면 퀸·룩·비숍·나이트 중 하나로 바뀌어요."
		elif m.type=="FORK":demo_text="한 번 움직여 상대 둘을 동시에 노려요. 어느 칸일까요?"
		elif m.type=="PIN":demo_text="상대 나이트 뒤에 왕이 있어요. 둘을 한 대각선으로 묶어 볼까요?"
		else:demo_text="앞에는 왕, 뒤에는 강한 기물이 있어요. 같은 줄을 노려요."
		if not await demo_pause(1.5,token):return
		demo_heading="WATCH 2 / 3";demo_focus=[b]
		if m.type=="PROMOTION":
			rules.cells[a]="";rules.cells[b]="P";animate(move,"P")
			demo_text="끝줄에 도착했어요. 이제 새 기물을 골라요."
			if not await demo_pause(1.5,token):return
			rules.cells[b]=move[4].to_upper()
			demo_heading="WATCH 3 / 3"
			demo_text="이번에는 퀸! 앞으로는 퀸처럼 움직여요. 직접 풀 때 네 기물 중 고를 수 있어요."
			if move[4]=="n":
				demo_text="이번에는 나이트! L자 공격으로 왕과 룩을 동시에 노려요. 항상 퀸이 최선은 아니에요."
				for square in m.objective.forkTargets:demo_links.append([b,rules.square(square)])
		else:
			rules.apply_raw(move);animate(move,piece_letter)
			demo_text="새 자리에서 공격이 어떻게 이어지는지 보세요."
			if not await demo_pause(1.3,token):return
			if m.type=="FORK":
				for square in m.objective.targets:demo_links.append([b,rules.square(square)])
				demo_heading="WATCH 3 / 3";demo_text="공격선이 두 갈래예요! 한 기물로 둘을 동시에 공격하는 포크예요."
			elif m.type=="PIN":
				var front=rules.square(m.objective.target);var rear=rules.square(m.objective.rear)
				demo_links=[[b,front],[front,rear]];demo_focus=[front,rear]
				demo_heading="WATCH 3 / 3";demo_text="나이트가 비키면 뒤의 왕이 체크예요. 그래서 나이트는 움직일 수 없어요. 이것이 핀이에요."
			else:
				var front=rules.square(m.objective.target);var rear=rules.square(m.objective.rear)
				demo_links=[[b,front],[front,rear]];demo_focus=[front,rear]
				demo_text="앞의 왕에게 체크! 왕이 피하면 뒤의 기물이 드러나요."
				if not await demo_pause(1.8,token):return
				var reply=""
				for candidate in rules.legal():
					if rules.square(candidate.substr(0,2))==front:reply=candidate;break
				if reply!="":
					rules.apply_raw(reply);animate(reply,"k");demo_links=[[b,rear]]
					if not await demo_pause(1.3,token):return
					var capture=rules.coord(b)+rules.coord(rear)
					if capture in rules.legal():rules.apply_raw(capture);animate(capture,piece_letter)
					demo_links=[];demo_focus=[rear]
				demo_heading="WATCH 3 / 3";demo_text="왕이 피한 뒤 뒤쪽 기물을 잡았어요. 앞을 몰아내고 뒤를 잡는 꼬치 공격이에요."
	if not await demo_pause(2.4,token):return
	demo_heading="YOUR TURN";demo_text="이제 직접 해 볼까요? Try now를 누르면 원래 문제로 돌아가요. Replay로 다시 볼 수도 있어요."
	feedback="Replay · Try now"
func persist():
	if review or demo:return
	learner.data.current={"id":missions[index].id,"revision":missions[index].get("revision",1),"lessonStep":lesson_step,"fen":rules.fen(),"history":rules.history,"positions":rules.positions,"notation":rules.notation}
	learner.save()
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:tap(event.position)
	elif event is InputEventScreenTouch and event.pressed:tap(event.position)
func tap(p:Vector2):
	for i in range(buttons.size()-1,-1,-1):
		var b=buttons[i]
		if b.r.has_point(p):
			if not b.disabled:
				if modal!="" and not (b.action in ["begin","next","restart","reset_cancel","reset_confirm"] or b.action.begins_with("promote:")):return
				action(b.action)
			return
	if screen!="play" or modal!="" or busy or rules.turn!="w":return
	var actor_hit=board_view.pick_actor(p)
	for i in range(rules.n*rules.n):
		if i==actor_hit or (actor_hit<0 and Geometry2D.is_point_in_polygon(p,poly(i))):
			var current=active_mission()
			var target=current.objective.target
			var identified=(target!="" and i==rules.square(target)) or (current.type=="CAPTURE" and rules.cells[i]=="p")
			if identified:
				learner.selected(current.englishExpressionIds[0],was_assisted,korean_used);target_evidence=true;learner.save()
			if rules.color(rules.cells[i])=="w":
				selected=i
				var m=active_mission()
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
	if demo:
		if a=="watch":start_demo()
		elif a=="demo_next" and demo_waiting:demo_waiting=false;feedback="Watch the move"
		elif a=="practice":finish_demo();speak_mission()
		elif a in ["home","map"]:finish_demo();action(a)
		return
	if a=="watch":start_demo();return
	if busy and a in ["home","map","book","settings","back"]:return
	if a=="reset_prompt" and screen=="settings":modal="reset"
	elif a=="reset_cancel":modal=""
	elif a=="reset_confirm" and modal=="reset":
		if learner.reset_progress():
			generation+=1;audio.stop();demo=false;busy=false;modal="";screen="home";settings_return="home"
			index=0;chapter=1;selected=-1;review=false;free_play=false;lesson_step=0;introducing="";feedback="";anim_t=1
		else:modal="";feedback="저장 공간을 확인해 주세요. 초기화하지 못했어요."
	elif a=="home":screen="home";modal=""
	elif a=="continue":review=false;free_play=false;start_mission(int(learner.data.lastMission),true)
	elif a=="map":screen="map";modal="";map_page=0 if chapter<=4 else 1
	elif a=="mappage":map_page=1-map_page
	elif a=="book":screen="book";modal="";book_page=0
	elif a=="bookpage":book_page=(book_page+1)%int(ceil(learner.review_ids().size()/(6.0 if size_now().x<1050 else 9.0)))
	elif a=="settings":settings_return=screen;screen="settings"
	elif a=="back":screen=settings_return
	elif a.begins_with("mission:"):review=false;free_play=false;start_mission(int(a.split(":")[1]))
	elif a=="begin":
		modal=""
		if has_demo() and not missions[index].id in learner.data.completed and rules.history.is_empty():start_demo()
		else:speak_mission()
	elif a in ["listen","slow"]:say_id(missions[index].englishExpressionIds[0],a=="slow",true)
	elif a=="hint":
		hints=mini(3,hints+1);was_assisted=true;learner.chess(missions[index].id).hintCount+=1
		if missions[index].has("mateLimit"):
			var moves=puzzle_moves()
			if moves.size():
				feedback="추천하는 수: "+moves[0];selected=rules.square(moves[0].substr(0,2))
		elif missions[index].type=="GAME":feedback="추천하는 수: "+rules.choose_ai(true)
		elif hints>=2:
			var sol=Goals.solutions(rules,active_mission())
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
	var m=active_mission();var token=generation
	var before=rules.cells.duplicate();var old=rules.fen()
	var old_history=rules.history.duplicate();var old_positions=rules.positions.duplicate();var old_notation=rules.notation.duplicate()
	var c=learner.chess(m.id);c.attemptCount+=1
	var p=rules.cells[rules.square(move.substr(0,2))]
	if m.type=="CAPTURE" and before[rules.square(move.substr(2,2))]=="p":
		learner.selected(m.englishExpressionIds[0],was_assisted,korean_used);target_evidence=true
	if m.has("mateLimit") and not move in puzzle_moves():
		c.wrongCount+=1;mistakes+=1;hints=mini(3,hints+1);was_assisted=true
		feedback="합법적인 수지만 남은 "+str(puzzle_remaining())+"수 안의 메이트를 보장하지 못해요. 상대의 도망갈 길을 다시 살펴요."
		say_id("retry");persist();return
	if not rules.play(move):return
	c.legalMoveCount+=1;selected=-1;busy=true
	animate(move,p);last_move=move
	await get_tree().create_timer(.5).timeout
	if token!=generation:return
	if m.type=="GAME":
		persist()
		if finish_game():busy=false;return
		await ai_turn();return
	if Goals.success(rules,m,move,before):
		if m.has("sequence") and lesson_step+1<m.sequence.size():
			lesson_step+=1;rules.turn="w";feedback="첫 계획을 완성했어요. 다음 도착점까지 이어가요."
			busy=false;hints=0;persist();say_id(m.englishExpressionIds[0]);return
		win();busy=false;return
	c.wrongCount+=1;mistakes+=1
	var replies=rules.legal()
	if replies.size():
		var reply=replies.pick_random()
		var attacker=rules.square(move.substr(2,2))
		for candidate in replies:
			if rules.square(candidate.substr(2,2))==attacker:reply=candidate;break
		var enemy=rules.cells[rules.square(reply.substr(0,2))]
		rules.play(reply);animate(reply,enemy)
		feedback="상대의 가능한 응수를 살펴보세요. 아직 미션 목표를 이루지 못했어요."
	else:feedback="이 배치는 "+("체크메이트" if rules.check("b") else "더 움직일 수 없는 상태")+"예요. 이번 미션의 목표를 다시 살펴봐요."
	say_id("retry")
	await get_tree().create_timer(1.8).timeout
	if token!=generation:return
	rules.load_fen(old,rules.n);rules.history=old_history;rules.positions=old_positions;rules.notation=old_notation
	hints=mini(3,1+mistakes);was_assisted=true;busy=false;anim_t=1
	persist()
func ai_turn():
	busy=true
	var token=generation
	await get_tree().create_timer(.65).timeout
	if token!=generation:return
	var moves=puzzle_moves() if missions[index].has("mateLimit") else []
	var move=moves.pick_random() if moves.size() else rules.choose_ai(false)
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
	if not review:learner.data.current={}
	learner.save()
	modal="success";feedback="Great move!";say_id("praise")
