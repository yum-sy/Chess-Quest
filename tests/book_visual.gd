extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.learner.path="user://book-visual.json";g.learner.data.settings.sound=false;g.learner.data.settings.motion=false
 for dimensions in [Vector2i(1280,800),Vector2i(720,1280)]:
  root.size=dimensions;g.responsive()
  for scene in ["home","ending"]:
   g.screen=scene
   await create_timer(.3).timeout
   root.get_texture().get_image().save_png("res://evidence/book-"+scene+"-"+str(dimensions.x)+".png")
 await create_timer(2).timeout
 quit()
