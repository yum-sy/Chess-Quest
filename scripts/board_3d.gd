extends SubViewport
# 3D board with approved AI-rendered, alpha-tested 2.5D character sprites.
const ATLAS=preload("res://assets/characters/approved-atlas-v1.png")
const COLUMN={"p":0,"n":1,"b":2,"r":3,"q":4,"k":5}
const BASE_X=[137,132,128,121,116,121]
const PIXEL_SIZE=.0038
var atlas_image:Image
var stage=Node3D.new()
var camera=Camera3D.new()
var ground=Node3D.new()
var actors=Node3D.new()
var markers=Node3D.new()
var n=0
var signature=""
var pieces={}
var mats={}
var phase=0.0
var motion=true
var chosen=-1
var checked=[]
var happy=false
var theme=0
var gold_skin=false
var view_rect=Rect2()
var marker_key=""
var moving_from=-1
var moving_to=-1
var moving_progress=1.0
var moving_letter=""
func _init():
	atlas_image=ATLAS.get_image()
	transparent_bg=true
	own_world_3d=true
	msaa_3d=Viewport.MSAA_4X
	render_target_update_mode=SubViewport.UPDATE_ALWAYS
	size=Vector2i(900,650)
	add_child(stage);stage.add_child(ground);stage.add_child(actors);stage.add_child(markers)
	stage.add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.position=Vector3(3.4,14.8,11.0)
	camera.rotation=Vector3(-atan(14.8/Vector2(3.4,11.0).length()),atan(3.4/11.0),0)
	camera.near=.1;camera.far=80
	var env=WorldEnvironment.new();env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("e8efdc")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("fff0d9")
	env.environment.ambient_light_energy=.38
	env.environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	stage.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-30,0)
	sun.light_color=Color("fff3da");sun.light_energy=.85;sun.shadow_enabled=true
	sun.directional_shadow_max_distance=32;sun.shadow_bias=.04;sun.light_angular_distance=4
	stage.add_child(sun)
	var fill=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-25,145,0)
	fill.light_color=Color("c9e8ff");fill.light_energy=.26
	stage.add_child(fill)
func material(hex:String,metal=0.0)->StandardMaterial3D:
	var key=hex+str(metal)
	if mats.has(key):return mats[key]
	var m=StandardMaterial3D.new();m.albedo_color=Color(hex);m.roughness=.38;m.metallic=metal
	mats[key]=m;return m
func mesh_node(parent:Node3D,mesh:Mesh,pos:Vector3,mat:Material)->MeshInstance3D:
	var node=MeshInstance3D.new();node.mesh=mesh;node.position=pos;node.material_override=mat;parent.add_child(node);return node
func sphere(parent:Node3D,pos:Vector3,scale_v:Vector3,mat:Material)->MeshInstance3D:
	var mesh=SphereMesh.new();mesh.radius=.5;mesh.height=1.0;mesh.radial_segments=20;mesh.rings=12
	var node=mesh_node(parent,mesh,pos,mat);node.scale=scale_v;return node
func cylinder(parent:Node3D,pos:Vector3,radius:float,height:float,mat:Material,top=-1.0)->MeshInstance3D:
	var mesh=CylinderMesh.new();mesh.bottom_radius=radius;mesh.top_radius=radius if top<0 else top;mesh.height=height;mesh.radial_segments=32
	return mesh_node(parent,mesh,pos,mat)
func cube(parent:Node3D,pos:Vector3,extent:Vector3,mat:Material)->MeshInstance3D:
	var mesh=BoxMesh.new();mesh.size=extent;return mesh_node(parent,mesh,pos,mat)
func clear(parent:Node3D):
	for node in parent.get_children():parent.remove_child(node);node.queue_free()
func world(file:float,rank:float)->Vector3:return Vector3(file-(n-1)*.5,.015,(n-1)*.5-rank)
func projected(file:float,rank:float)->Vector2:return view_rect.position+camera.unproject_position(world(file,rank))
func polygon(i:int)->PackedVector2Array:
	var x=float(i%n);var y=float(i/n)
	return PackedVector2Array([projected(x-.5,y+.5),projected(x+.5,y+.5),projected(x+.5,y-.5),projected(x-.5,y-.5)])
func configure(count:int,rect:Rect2,theme_idx:int):
	view_rect=rect
	var next_size=Vector2i(rect.size)
	if size!=next_size:size=next_size
	if n!=count or theme!=theme_idx:
		n=count;theme=theme_idx;signature="";build_board()
	camera.size=n*1.65
	camera.force_update_transform()
	# Fit projected board including the thick rim and tall back-rank characters.
	var bounds=Rect2(camera.unproject_position(world(-.8,-.8)),Vector2.ZERO)
	for x in [-.8,n-.2]:
		for y in [-.8,n-.2]:
			bounds=bounds.expand(camera.unproject_position(world(x,y)))
			bounds=bounds.expand(camera.unproject_position(world(x,y)+Vector3(0,.9,0)))
	var factor=maxf(bounds.size.x/(size.x-38.0),bounds.size.y/(size.y-36.0))
	camera.size*=factor
	camera.force_update_transform()
func build_board():
	clear(ground)
	var ivory=material("f7e6c8");var brown=material("b98259")
	if theme>0:brown=material(["b87b50","6a9c85","7996b8","a286b8","c98e99","8299b6","7f729e","bd964c"][theme])
	ivory.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	brown.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	# A substantial toy-like plinth, stepped golden bevels, and distinct team rails.
	cube(ground,Vector3(0,-.31,0),Vector3(n+.48,.42,n+.48),material("754a39"))
	cube(ground,Vector3(0,-.115,0),Vector3(n+.54,.13,n+.54),material("daa657",.35))
	cube(ground,Vector3(0,-.085,0),Vector3(n+.2,.10,n+.2),material("ffe4a3",.2))
	for rank in range(n):
		for file in range(n):cube(ground,world(file,rank)+Vector3(0,-.055,0),Vector3(.992,.09,.992),ivory if (file+rank)%2 else brown)
	cube(ground,Vector3(0,-.035,n*.5+.14),Vector3(n+.2,.14,.16),material("479ed0",.25))
	cube(ground,Vector3(0,-.035,-n*.5-.14),Vector3(n+.2,.14,.16),material("9c6cb0",.25))
	# Blue shield badge physically attached to the player's front edge.
	sphere(ground,Vector3(0,-.27,n*.5+.255),Vector3(.56,.39,.08),material("317caf"))
	sphere(ground,Vector3(0,-.25,n*.5+.30),Vector3(.16,.18,.04),material("ffe3a0",.3))
func update_position(cells:Array,selected:int,check_squares:Array,celebrate:bool,enabled:bool):
	chosen=selected;checked=check_squares;happy=celebrate;motion=enabled
	var key="|".join(cells)+str(gold_skin)
	if key==signature:return
	signature=key;clear(actors);pieces.clear()
	for i in range(cells.size()):
		if cells[i]=="":continue
		var actor=character(cells[i]);actors.add_child(actor);actor.position=world(i%n,i/n)
		pieces[i]=actor
func character(letter:String)->Node3D:
	var node=Node3D.new();node.set_meta("letter",letter)
	var sprite=Sprite3D.new();sprite.name="Portrait"
	sprite.texture=ATLAS;sprite.hframes=6;sprite.vframes=4
	sprite.frame=COLUMN[letter.to_lower()]+(0 if letter==letter.to_upper() else 12)
	sprite.pixel_size=PIXEL_SIZE
	sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded=false;sprite.double_sided=true
	sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD;sprite.alpha_scissor_threshold=.55
	sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.position.y=.012
	sprite.offset.y=229-128
	sprite.offset.x=128-BASE_X[COLUMN[letter.to_lower()]]
	node.add_child(sprite)
	if gold_skin and letter==letter.to_upper():
		var ring=TorusMesh.new();ring.inner_radius=.28;ring.outer_radius=.32;ring.rings=32;ring.ring_segments=8
		var ornament=mesh_node(node,ring,Vector3(0,.025,0),material("ffd274",.25));ornament.name="RewardRing"
	# A contact shadow keeps the cutout anchored to its actual square.
	var shadow=CylinderMesh.new();shadow.top_radius=.19;shadow.bottom_radius=.19;shadow.height=.008;shadow.radial_segments=32
	var mat=StandardMaterial3D.new();mat.albedo_color=Color(0.20,.13,.10,.12)
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_node(node,shadow,Vector3(0,.006,-.10),mat)
	return node
func portrait_rect(i:int)->Rect2:
	var node=pieces[i];var sprite=node.get_node("Portrait")
	var center=view_rect.position+camera.unproject_position(sprite.global_position)
	var pixels_per_unit=(camera.unproject_position(camera.global_transform.basis.x)-camera.unproject_position(Vector3.ZERO)).length()
	var extent=256*PIXEL_SIZE*pixels_per_unit*node.scale.x
	center+=Vector2(sprite.offset.x,-sprite.offset.y)*PIXEL_SIZE*pixels_per_unit*node.scale.x
	return Rect2(center-Vector2.ONE*extent*.5,Vector2.ONE*extent)
func pick_actor(screen_pos:Vector2)->int:
	# Alpha-aware picking follows visible artwork, not a rectangular hitbox.
	var order=pieces.keys()
	order.sort_custom(func(a,b):return camera.global_position.distance_squared_to(pieces[a].position)<camera.global_position.distance_squared_to(pieces[b].position))
	for i in order:
		var rect=portrait_rect(i)
		if not rect.has_point(screen_pos):continue
		var uv=(screen_pos-rect.position)/rect.size
		var sprite=pieces[i].get_node("Portrait")
		var x=int(sprite.frame)%6*256+clampi(int(uv.x*256),0,255)
		var y=int(sprite.frame)/6*256+clampi(int(uv.y*256),0,255)
		if atlas_image.get_pixel(x,y).a>.55:return i
	return -1
func update_markers(destinations:Array,selected:int,target:int):
	var key=str(n)+str(destinations)+str(selected)+str(target)+str(checked)
	if key==marker_key:return
	marker_key=key
	clear(markers)
	for i in destinations:
		var pos=world(i%n,i/n)+Vector3(0,.045,0)
		cylinder(markers,pos,.12,.015,material("df6562" if pieces.has(i) else "4fbd8e"))
	var rings=[[selected,"4fbeef"],[target,"ffd06d"]]
	for i in checked:rings.append([i,"ee515a"])
	for pair in rings:
		if pair[0]<0:continue
		var i=int(pair[0]);var ring=TorusMesh.new();ring.inner_radius=.37;ring.outer_radius=.405;ring.rings=32;ring.ring_segments=8
		mesh_node(markers,ring,world(i%n,i/n)+Vector3(0,.045,0),material(pair[1]))
func animate(delta:float):
	phase+=delta
	for i in pieces:
		var node=pieces[i];var p=world(i%n,i/n);var active=i==chosen
		var local_phase=phase*2.1+i*.73
		var bounce=(sin(local_phase)*.014 if motion else 0.0)
		if happy and motion:bounce=abs(sin(phase*5+i))*.13
		node.position=p+Vector3(0,bounce,0)
		node.rotation=Vector3(0,sin(local_phase*.6)*.045 if motion else 0.0,sin(local_phase)*.025 if motion else 0.0)
		if i==moving_to and moving_progress<1:
			var t=moving_progress;var from=world(moving_from%n,moving_from/n)
			node.position=from.lerp(p,t)
			if moving_letter.to_lower()=="n":
				var corner=Vector3(p.x,from.y,from.z) if absf(p.x-from.x)>absf(p.z-from.z) else Vector3(from.x,from.y,p.z)
				node.position=from.lerp(corner,t*1.5) if t<2.0/3.0 else corner.lerp(p,(t-2.0/3.0)*3)
				node.position.y+=sin(t*PI)*.65
			elif moving_letter.to_lower()=="p":node.position.y+=sin(t*PI)*.23
			else:node.position.y+=sin(t*PI)*.06
			node.rotation.z=-sin(t*PI)*.12
		var sprite=node.get_node("Portrait")
		var letter=node.get_meta("letter")
		var surprised=i in checked or (i==moving_to and moving_progress<.7)
		sprite.frame=COLUMN[letter.to_lower()]+(0 if letter==letter.to_upper() else 12)+(6 if surprised else 0)
		# A small celebratory nod/selection bounce, with no arms or hands.
		node.scale=Vector3.ONE*(1.035 if active else 1.0)
		if active and motion:node.position.y+=.025+sin(phase*4)*.015
