extends SceneTree
func _initialize():call_deferred("run")
func snap(name):
 await create_timer(.3).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://evidence/pacing-"+name+".png")
func run():
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.learner.path="user://pacing-visual.json";g.learner.data.settings.sound=false;g.learner.data.completed=[]
 for viewport_size in [Vector2i(1280,800),Vector2i(720,1280)]:
  root.size=viewport_size;g.responsive()
  var suffix="wide" if viewport_size.x==1280 else "tall"
  for i in [0,16,53]:
   g.start_mission(i);g.modal="";await snap("board-"+str(i)+"-"+suffix)
  for kind in ["intro","success","retry","promotion","reset"]:
   g.start_mission(0);g.modal=kind
   g.promotion=["b7b8q","b7b8r","b7b8b","b7b8n"]
   await snap(kind+"-"+suffix)
 g.start_mission(12);g.modal=""
 await create_timer(3.2).timeout;g.action("demo_next")
 await create_timer(3.2).timeout;g.action("demo_next")
 await create_timer(4.5).timeout
 await snap("fork-waiting")
 g.finish_demo()
 await create_timer(2).timeout
 quit()
