extends SceneTree
func _initialize():call_deferred("run")
func run():
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://evidence/home.png")
	game.start_mission(34);game.modal=""
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://evidence/play.png")
	quit()
