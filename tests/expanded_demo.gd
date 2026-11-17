extends SceneTree
const R=preload("res://scripts/rules.gd")
var fails=0
func expect(ok,label):
 if not ok:fails+=1;printerr("FAIL ",label)
func _initialize():call_deferred("run")
func run():
 Engine.time_scale=8
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.learner.path="user://expanded-demo-test.json";g.learner.data.completed=[];g.learner.data.settings.sound=false
 for i in [5,12,15,22,23,28,35,37]:
  g.start_mission(i)
  if g.modal=="intro":g.action("begin")
  var original=g.missions[i].initialPosition;var saved=g.learner.data.current.duplicate(true)
  expect(g.demo,"auto demo "+str(i))
  await create_timer(9).timeout
  expect(g.demo_heading=="YOUR TURN","demo finished "+str(i))
  g.persist();expect(g.learner.data.current==saved,"demo never saves "+str(i))
  var m=g.missions[i]
  if m.type=="PROMOTION":expect(g.rules.cells[g.rules.square(m.objective.destination)]==("N" if i==15 else "Q"),"promotion transformation")
  elif m.type=="FORK":expect(g.demo_links.size()==2,"two fork arrows")
  elif m.type=="PIN":expect(g.demo_links.size()==2 and g.rules.legal().all(func(move):return not move.begins_with("f6")),"pinned knight cannot move")
  elif m.type=="SKEWER":expect(g.rules.color(g.rules.cells[g.rules.square(m.objective.rear)])=="w","skewer captures rear piece")
  expect(not m.id in g.learner.data.completed,"watch earns no completion")
  g.action("practice");expect(not g.demo and not g.busy and g.rules.fen()==original,"exact exercise restoration")
  var solution=g.Goals.solutions(g.rules,g.active_mission())[0]
  g.player_move(solution);g.action("watch");expect(not g.demo,"watch blocked during move")
  await create_timer(.8).timeout
  expect(g.modal=="success","solve after preview "+str(i))
 # Reset requires confirmation, preserves preferences, clears rewards and both save copies.
 g.modal="";g.screen="play";g.action("settings")
 var previous=g.learner.data.duplicate(true)
 g.action("reset_confirm");expect(g.learner.data==previous,"no reset without confirmation dialog")
 g.action("reset_prompt");expect(g.modal=="reset","reset confirmation opens")
 g.action("reset_cancel");expect(g.learner.data==previous and g.screen=="settings","cancel keeps all progress")
 g.learner.data.settings.sound=false;g.learner.data.settings.korean=false;g.learner.data.settings.motion=false;g.learner.data.settings.theme=3;g.learner.data.settings.gold_skin=true
 g.action("reset_prompt");g.action("reset_confirm")
 expect(g.screen=="home" and g.modal=="" and g.index==0,"reset returns to first adventure")
 var fresh=g.Learning.new();fresh.path=g.learner.path;fresh.load_save()
 for key in ["completed","english","chess","rewards","current"]:expect(fresh.data[key].is_empty(),"reset clears "+key)
 expect(fresh.data.lastMission==0 and fresh.data.settings.theme==0 and not fresh.data.settings.get("gold_skin",false),"reset clears unlock cosmetics")
 expect(not fresh.data.settings.sound and not fresh.data.settings.korean and not fresh.data.settings.motion,"preferences preserved")
 var broken=FileAccess.open(fresh.path,FileAccess.WRITE);broken.store_string("broken");broken.close()
 fresh.load_save();expect(fresh.data.completed.is_empty() and fresh.data.english.is_empty(),"backup cannot resurrect erased progress")
 # All visible controls stay on screen in both layouts.
 for viewport_size in [Vector2i(1280,800),Vector2i(720,1280)]:
  root.size=viewport_size;g.responsive()
  for page in ["settings","map","book"]:
   g.screen=page;g.queue_redraw();await process_frame;await process_frame
   for button in g.buttons:expect(Rect2(Vector2.ZERO,g.size_now()).encloses(button.r),page+" button in viewport")
 print("EXPANDED DEMO 8 lessons, interactive solutions, reset confirmation/recovery, responsive subpages; failures ",fails)
 quit(1 if fails else 0)
