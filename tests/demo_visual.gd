extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.learner.path="user://demo-visual.json";g.learner.data.completed=[];g.learner.data.settings.sound=false
 g.start_mission(6)
 await create_timer(3.5).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://evidence/demo-ep.png")
 await create_timer(4).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://evidence/demo-ready.png")
 g.start_mission(44)
 await create_timer(3.4).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://evidence/demo-castle.png")
 g.finish_demo();root.size=Vector2i(720,1280);g.responsive();g.start_mission(45)
 await create_timer(3.4).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://evidence/demo-portrait.png")
 quit()
