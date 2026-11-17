extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.learner.path="user://piece-visual.json";g.learner.data.settings.sound=false
 for i in [6,15,28,34,45]:
  g.start_mission(i);g.modal=""
  await create_timer(.4).timeout
  root.get_texture().get_image().save_png("res://evidence/piece-lesson-"+str(i)+".png")
 root.size=Vector2i(720,1280);g.responsive();g.start_mission(6);g.modal=""
 await create_timer(.4).timeout
 root.get_texture().get_image().save_png("res://evidence/piece-portrait.png")
 await create_timer(2).timeout
 quit()
