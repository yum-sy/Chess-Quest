extends SceneTree
var fails=0
func expect(ok,label):
 if not ok:fails+=1;printerr("FAIL ",label)
func _initialize():call_deferred("run")
func run():
 Engine.time_scale=8
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.learner.path="user://special-demo-test.json";g.learner.data.completed=[];g.learner.data.settings.sound=false
 for i in [6,44,45]:
  g.start_mission(i)
  var original=g.missions[i].initialPosition;var saved=g.learner.data.current.duplicate(true)
  expect(g.demo and g.busy,"automatic demonstration")
  var before=g.rules.fen();g.player_move("e1g1");expect(g.rules.fen()==before,"input locked")
  await create_timer(3.2).timeout
  g.persist();expect(g.learner.data.current==saved,"preview cannot enter save")
  await create_timer(4.2).timeout
  expect(g.demo_heading=="WATCH 1 / 3" and g.demo_waiting and g.rules.fen()==before,"waits for child with no automatic advance")
  await preload("res://tests/demo_driver.gd").finish(self,g)
  expect(g.demo_heading=="YOUR TURN","demo reaches replay/practice choice")
  if i==6:expect(g.rules.cells[g.rules.square("d6")]=="P" and g.rules.cells[g.rules.square("d5")]=="","EP animation result")
  else:expect(g.rules.cells[g.rules.square("g1" if i==44 else "c1")]=="K" and g.rules.cells[g.rules.square("f1" if i==44 else "d1")]=="R","castle animation result")
  expect(not g.missions[i].id in g.learner.data.completed,"watch does not earn reward")
  g.action("watch");expect(g.demo_heading=="WATCH 1 / 3","replay resets")
  g.action("practice");expect(not g.demo and not g.busy and g.rules.fen()==original and g.rules.history.is_empty(),"practice restores exact position")
  await create_timer(1.7).timeout
  expect(g.rules.fen()==original,"cancelled replay cannot mutate practice")
  g.player_move("e5d6" if i==6 else "e1g1" if i==44 else "e1c1")
  await create_timer(.7).timeout
  expect(g.modal=="success","player solves after demonstration")
 g.start_mission(6);expect(not g.demo,"completed lesson does not force demo")
 g.action("watch");g.action("home");await create_timer(2).timeout
 expect(not g.demo and g.screen=="home","leave demo safely")
 g.learner.data.completed=[];g.learner.data.settings.motion=false;g.start_mission(44)
 await create_timer(3.2).timeout
 expect(g.anim_t==1,"reduced motion uses timed steps")
 g.start_mission(0);await create_timer(3).timeout
 expect(not g.demo and g.index==0 and g.rules.fen()==g.missions[0].initialPosition,"mission change cancels preview")
 print("SPECIAL DEMO automatic, replay, practice, saves, cancellation, reduced motion; failures ",fails)
 quit(1 if fails else 0)
