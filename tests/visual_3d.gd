extends SceneTree
func _initialize():call_deferred("run")
func run():
	var game=load("res://main.tscn").instantiate();root.add_child(game)
	game.learner.path="user://visual-render-test.json"
	await create_timer(.5).timeout
	root.get_texture().get_image().save_png("res://evidence/3d-home.png")
	for idx in [0,34,48]:
		game.start_mission(idx);game.modal="";game.audio.stop()
		await create_timer(.5).timeout
		root.get_texture().get_image().save_png("res://evidence/3d-board-"+str(game.rules.n)+".png")
	await create_timer(3).timeout
	quit()
