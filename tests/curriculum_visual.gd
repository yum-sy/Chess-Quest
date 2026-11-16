extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.learner.path="user://curriculum-visual.json";g.learner.data.settings.sound=false
 for i in [0,3,50,52]:
  g.start_mission(i)
  await create_timer(.3).timeout
  if g.modal!="":root.get_texture().get_image().save_png("res://evidence/story-"+str(i)+".png")
  g.modal=""
  await create_timer(.3).timeout
  root.get_texture().get_image().save_png("res://evidence/lesson-"+str(i)+".png")
 root.size=Vector2i(720,1280);g.responsive();g.start_mission(52);g.modal=""
 await create_timer(.4).timeout
 root.get_texture().get_image().save_png("res://evidence/puzzle-portrait.png")
 await create_timer(2).timeout
 quit()
