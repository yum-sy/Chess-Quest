extends RefCounted
static func finish(tree:SceneTree,g)->bool:
 for tick in range(600):
  if not g.demo:return false
  if g.demo_heading=="YOUR TURN":return true
  if g.demo_waiting:g.action("demo_next")
  await tree.create_timer(.1).timeout
 return false
