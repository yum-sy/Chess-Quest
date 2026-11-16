extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g)
	await process_frame;g.learner.path="user://visual-test.json";g.learner.data.settings.sound=false
	g.start_mission(27);g.modal="";g.selected=g.rules.square("b1")
	await create_timer(.6).timeout
	root.get_texture().get_image().save_png("res://evidence/temple-defense.png")
	g.player_move("b1d3")
	await create_timer(.65).timeout
	root.get_texture().get_image().save_png("res://evidence/temple-explanation.png")
	root.size=Vector2i(720,1280);g.responsive();g.start_mission(48);g.modal=""
	await create_timer(.6).timeout
	root.get_texture().get_image().save_png("res://evidence/dense-portrait.png")
	await create_timer(2).timeout
	quit()
