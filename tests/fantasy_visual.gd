extends SceneTree
func _initialize():call_deferred("run")
func capture(name):
 await create_timer(.25).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://evidence/fantasy-"+name+".png")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.learner.path="user://fantasy-visual.json";g.learner.data=g.Learning.new().data;g.learner.data.settings.sound=false
 for i in [5,12,28,22]:
  g.start_mission(i);g.modal=""
  await create_timer(4 if i!=22 else 7.4).timeout
  await capture("demo-"+str(i))
  g.finish_demo()
 for viewport_size in [Vector2i(1280,800),Vector2i(720,1280)]:
  root.size=viewport_size;g.responsive()
  var suffix="wide" if viewport_size.x==1280 else "tall"
  for page in ["settings","map","book"]:
   g.screen=page;g.modal=""
   await capture(page+"-"+suffix)
  g.screen="settings";g.action("reset_prompt");await capture("reset-"+suffix);g.action("reset_cancel")
  g.start_mission(0);g.modal="";await capture("play-"+suffix)
  g.modal="success";await capture("success-"+suffix);g.modal=""
 await create_timer(2).timeout
 quit()
