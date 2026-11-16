extends SceneTree
const R=preload("res://scripts/rules.gd")
var fails=0
func check(ok:bool,label:String):
 if not ok:fails+=1;printerr(label)
func _initialize():call_deferred("run")
func run():
 var ms=JSON.parse_string(FileAccess.get_file_as_string("res://data/missions.json"));var nodes=0
 for m in ms:
  if not m.has("mateLimit"):continue
  var setup=R.new();setup.load_fen(m.initialPosition,8)
  var white_count=0;var black_count=0
  for piece in setup.cells:
   if setup.color(piece)=="w":white_count+=1
   if setup.color(piece)=="b":black_count+=1
  check(white_count>=10 and black_count>=10,m.id+" developed middlegame armies")
  check(not setup.check("w") and not setup.check("b"),m.id+" legal non-check start")
  check(int(m.revision)>=3,m.id+" invalidates old sparse puzzle save")
  for key in m.puzzleBook:
   nodes+=1
   var parts=key.split("|");var left=int(parts[1]);var r=R.new();r.load_fen(parts[0]+" 0 1",8)
   var original=r.fen();var moves=m.puzzleBook[key];var legal=r.legal();var white=r.turn=="w"
   check(moves.size()>0,m.id+" nonempty proof")
   if not white:check(moves.size()==legal.size(),m.id+" covers every defense")
   for move in moves:
    check(move in legal,m.id+" legal proof edge "+move)
    r.apply_raw(move)
    var next_left=left-(1 if white else 0)
    if r.status()=="checkmate":check(r.turn=="b",m.id+" white wins")
    else:
     check(next_left>0,m.id+" bounded mate")
     var next=" ".join(r.fen().split(" ").slice(0,4))+"|"+str(next_left)
     check(m.puzzleBook.has(next),m.id+" closed proof tree")
    r.load_fen(original,8)
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
 g.learner.path="user://puzzle-ui-test.json";g.learner.data.settings.sound=false
 g.learner.data.completed=[]
 g.start_mission(3);g.modal="";g.player_move("c2c3");await create_timer(.65).timeout
 check(g.lesson_step==1 and g.modal=="" and not g.learner.data.completed.has("1-4"),"two steps, no premature reward")
 var saved=g.learner.data.current.duplicate(true);g.start_mission(3,true)
 check(g.lesson_step==1 and g.rules.fen()==saved.fen,"step progress resumes")
 g.player_move("c3c4");await create_timer(.65).timeout
 check(g.modal=="success" and g.learner.data.completed.has("1-4"),"both steps complete")
 g.learner.data.current={"id":"7-3","revision":2,"fen":"7k/8/8/8/8/8/1R6/R5K1 w - - 0 28"}
 g.start_mission(50,true);g.modal=""
 check(g.rules.fen()==g.missions[50].initialPosition,"old sparse puzzle save resets to middlegame")
 var initial=g.rules.fen();var solutions=g.puzzle_moves()
 for move in g.rules.legal():
  if not move in solutions:
   g.player_move(move);check(g.rules.fen()==initial and g.mistakes==1,"wrong plan rejected without corrupting board");break
 g.action("hint");check(g.feedback.contains(g.puzzle_moves()[0]),"hint follows mate proof")
 g.player_move(g.puzzle_moves()[0]);await create_timer(1.5).timeout
 check(g.rules.turn=="w" and g.rules.history.size()==2 and g.puzzle_remaining()==1,"opponent responds and move budget decreases")
 var position=g.rules.fen();g.start_mission(50,true)
 check(g.rules.fen()==position and g.puzzle_remaining()==1,"puzzle resumes at same budget")
 g.action("undo");check(g.rules.fen()==initial and g.puzzle_remaining()==2,"undo restores puzzle budget")
 print("PUZZLES ",nodes," proof nodes; sequence, hints, retry, resume, undo; failures ",fails)
 await create_timer(2).timeout
 quit(1 if fails else 0)
