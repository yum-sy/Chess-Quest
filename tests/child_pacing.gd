extends SceneTree
var failures=0
func check(ok,label):
 if not ok:failures+=1;printerr("FAIL ",label)
func english_only(value:String)->bool:
 for i in range(value.length()):
  var c=value.unicode_at(i)
  if c>=0xAC00 and c<=0xD7AF:return false
 return true
func _initialize():call_deferred("run")
func run():
 Engine.time_scale=8
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.learner.path="user://child-pacing-test.json";g.learner.data.completed=[];g.learner.data.settings.sound=false
 for i in range(g.missions.size()):
  g.index=i
  check(english_only(g.popup_message(false)),"English intro "+str(i))
  check(english_only(g.popup_message(true)),"English result "+str(i))
 var source=FileAccess.get_file_as_string("res://scripts/game.gd")
 var modal=source.split("func draw_modal(")[1].split("func expression(")[0]
 check(english_only(modal),"all modal text English including reset and retry")
 g.start_mission(6)
 var initial=g.rules.fen();g.action("demo_next")
 check(g.rules.fen()==initial and not g.demo_waiting,"cannot skip viewing time")
 await create_timer(3.3).timeout
 check(g.demo_waiting,"Next unlocked after hold")
 g.action("demo_next");await process_frame
 await create_timer(.9).timeout
 check(g.anim_t>0 and g.anim_t<.8,"piece moves slowly enough to watch")
 await create_timer(4).timeout
 var held=g.rules.fen();await create_timer(8).timeout
 check(g.demo_waiting and g.rules.fen()==held,"motion result stays until Next")
 g.action("watch");await create_timer(3.2).timeout;g.action("home")
 await create_timer(4).timeout
 check(g.screen=="home" and not g.demo,"paused preview cancels safely")
 for size in [Vector2i(1280,800),Vector2i(720,1280)]:
  root.size=size;g.responsive()
  for index in [0,16,53]:
   g.start_mission(index);g.modal="";g.layout_board(g.size_now())
   var front=g.board_view.ground.get_node("WhiteRailText")
   check(front.text=="WHITE" and not g.board_view.ground.has_node("BlackRailText"),"only player side has lettering")
   check(is_equal_approx(front.position.z,g.rules.n*.5+.272) and front.rotation_degrees.y==0 and front.position.y<0,"text sits on continuous wooden side")
   var white=g.board_view.ground.get_node("WhiteTeamRail").material_override.albedo_color
   var black=g.board_view.ground.get_node("BlackTeamRail").material_override.albedo_color
   check(white.r>.9 and white.g>.9 and white.b>.9 and black.r<.15 and black.g<.15 and black.b<.15,"white and black team rails")
 print("CHILD PACING manual steps, slower movement, English popups, symmetric board plaques; failures ",failures)
 quit(1 if failures else 0)
