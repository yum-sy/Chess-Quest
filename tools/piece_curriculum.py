"""Hand-authored piece-specific curriculum. Special rules always use a legal 8x8 board.
Rules reference: https://handbook.fide.com/chapter/E012023 articles 3.7 and 3.8.
Voice files are reused unchanged; topic labels add the specific lesson vocabulary.
"""
def apply(missions,fen):
 by={m['id']:m for m in missions}
 def put(id,kind,topic,p,brief,audio,*,n=None,position=None,story=None,result=None,**goal):
  m=by[id];size=n or m['boardSize']
  for key in ['sequence','threat','mateLimit','puzzleBook','previousMove','previousPosition']:m.pop(key,None)
  m.update(type=kind,topic=topic,boardSize=size,initialPosition=position or fen(size,p),objective=dict(target='',piece='',destination=''),acceptedSolutions=[],revision=4,briefing=brief,hints=[brief,'목표 기물을 누르고, 도착한 뒤의 공격과 방어를 비교해요.','금색 경로가 이 상황의 해결 방법이에요.'],englishExpressionIds=[audio],opponentResponsePolicy='legal_capture_then_random')
  m['objective'].update(goal)
  m['story']=story or brief
  m['explanation']=result or brief
  return m
 def route(m,steps):
  m['sequence']=[dict(objective=goal,briefing=text,type=kind) for kind,goal,text in steps]
 # PAWN: one-way movement, first double step, capture, blocked file, promotion, immediate/expired en passant.
 put('1-1','MOVE','FORWARD',{'b2':'P'},'폰은 앞으로만 가요. 편지를 들고 b3으로 한 칸 전진해요.','move_forward',piece='p',destination='b3',story='정원 문이 닫혔어요. 작은 폰이 편지를 들고 길을 나섭니다. 뒤로 갈 수 없으니 첫 걸음을 신중하게 골라요.')
 put('1-2','MOVE','FIRST DOUBLE STEP',{'a2':'P'},'처음 자리에서는 앞의 두 칸이 모두 비었을 때 두 칸도 갈 수 있어요. a4까지 가요.','move_two',piece='p',destination='a4')
 put('1-3','CAPTURE','DIAGONAL CAPTURE',{'b2':'P','c3':'p'},'앞으로 이동하지만 잡을 때는 대각선이에요. c3의 문지기를 잡아요.','capture_the_pawn',piece='p',target='c3')
 m=put('1-4','MOVE','NO SECOND DOUBLE',{'c2':'P','a2':'P'},'편지를 c4까지 두 걸음으로 배달해요. 움직인 폰은 다시 두 칸 전진할 수 없어요.','move_forward',piece='p',destination='c3')
 route(m,[('MOVE',{'destination':'c3'},'먼저 c3으로 한 칸 전진해요.'),('MOVE',{'destination':'c4'},'한 번 움직였으니 이제 c4까지 한 칸만 갈 수 있어요.')])
 put('1-5','CAPTURE','BLOCKED PAWN',{'b2':'P','b3':'p','c3':'p'},'정면의 폰은 뛰어넘거나 앞으로 잡을 수 없어요. 대각선 문지기를 잡고 길을 열어요.','capture_the_pawn',piece='p',target='c3')
 put('1-6','PROMOTION','PROMOTION',{},'폰을 b8 끝줄까지 보내세요. 퀸·룩·비숍·나이트 중 하나로 승격할 수 있어요.','move_forward',n=8,position='7k/1P6/8/8/8/8/8/7K w - - 0 1',piece='p',destination='b8',result='폰은 끝줄에 도착하는 즉시 새 기물이 돼요. 잡혔던 기물만 고를 필요도 없어요.')
 m=put('1-7','EN_PASSANT','EN PASSANT',{},'방금 상대가 d7→d5로 두 칸 전진했어요. 바로 이번 수에만 e5의 폰이 d6으로 가며 그 폰을 잡을 수 있어요.','capture_the_pawn',n=8,position='6k1/8/8/3pP3/8/8/8/6K1 w - d6 0 2',piece='p',target='d5',destination='d6',result='빈 d6으로 대각 이동했지만 d5의 폰이 사라졌어요. 옆으로 두 칸 전진해 온 폰을 즉시 잡는 앙파상이에요.')
 m['previousPosition']='6k1/3p4/8/4P3/8/8/8/6K1 b - - 0 1';m['previousMove']='d7d5'
 put('1-8','CAPTURE','EN PASSANT EXPIRED',{},'이번에는 다른 수를 둬서 앙파상 기회가 지났어요. d6은 안 돼요. f6의 폰을 보통의 대각 포획으로 잡아요.','capture_the_pawn',n=8,position='6k1/8/5p2/3pP3/8/8/8/6K1 w - - 2 3',piece='p',target='f6',result='폰이 나란히 있어도 항상 앙파상은 아니에요. 직전 수의 두 칸 전진이어야 하고 바로 다음 수에만 가능해요.')
 # KNIGHT: jump over either side, route, safe fork, asymmetric queen attack, edge trap, underpromotion.
 put('2-1','MOVE','JUMP OVER FRIENDS',{'b1':'N','b2':'P','c1':'P'},'친구들이 길을 막아도 나이트는 뛰어넘어요. L자 모양으로 c3에 착지해요.','jump_over_the_pawn',piece='n',destination='c3')
 put('2-2','MOVE','JUMP OVER ENEMIES',{'b1':'N','b2':'p','c1':'p'},'상대 폰도 뛰어넘을 수 있어요. c3으로 뛰면 중간의 폰은 잡히지 않아요.','jump_over_the_pawn',piece='n',destination='c3')
 put('2-3','CAPTURE','CAPTURE ON LANDING',{'b1':'N','b2':'P','c3':'p'},'점프 중간이 아니라 착지한 칸의 상대만 잡아요. c3의 폰을 잡아요.','capture_the_pawn',piece='n',target='c3')
 m=put('2-4','MOVE','TWO-JUMP ROUTE',{'c1':'N','c2':'P','b1':'P'},'두 발판을 이어서 건너요. 상대가 움직이지 않는 경로 연습이에요.','jump_over_the_pawn',piece='n',destination='b3')
 route(m,[('MOVE',{'destination':'b3'},'첫 발판 b3으로 뛰어요.'),('MOVE',{'destination':'d4'},'L자 방향을 바꿔 두 번째 발판 d4로 뛰어요.')])
 put('2-5','FORK','KNIGHT FORK',{'b1':'N','b2':'P','a4':'p','e4':'p'},'한 번 뛰어서 상대 폰 둘을 동시에 공격해요. 착지한 나이트도 안전해야 해요.','attack_together',n=6,piece='n',targets=['a4','e4'])
 put('2-6','ATTACK','ATTACK THE QUEEN',{'b1':'N','b2':'P','e4':'q'},'나이트의 L자 공격은 퀸의 직선·대각선과 달라요. 다음 수에 잡히지 않게 퀸을 공격해요.','attack_the_queen',n=6,piece='n',target='e4')
 put('2-7','SAFE_MOVE','EDGE TRAP',{'b1':'N','c2':'p','b4':'p'},'가장자리 나이트가 폰에게 공격받아요. 상대 폰의 대각선을 피해 안전한 착지점을 찾아요.','jump_to_safety',piece='n',requireThreatened=True)
 put('2-8','PROMOTION','KNIGHT PROMOTION',{},'c8에 승격할 때 나이트를 골라 보세요. L자 공격으로 왕과 룩을 동시에 겨냥할 수 있어요.','attack_together',n=8,position='8/r1P1k3/8/8/8/8/8/6K1 w - - 0 1',piece='p',destination='c8',promotion='n',forkTargets=['a7','e7'],result='항상 퀸 승격이 최선은 아니에요. c8의 나이트는 왕과 룩을 동시에 공격하지만 퀸은 같은 공격을 만들지 못해요.')
 # ROOK: blocking, detour, one-way attack, recapture defense, battery, seventh rank, skewer, fork.
 put('3-1','MOVE','STRAIGHT LINES',{'b2':'R'},'룩은 가로와 세로로 멀리 가요. 대각선으로는 갈 수 없어요. b4로 이동해요.','move_the_rook',piece='r',destination='b4')
 m=put('3-2','MOVE','AROUND THE WALL',{'b2':'R','b3':'P','b5':'p'},'룩은 친구를 뛰어넘지 못해요. 세 번 꺾어 문지기에게 가는 경로 연습이에요.','move_the_rook',piece='r',destination='e2')
 route(m,[('MOVE',{'destination':'e2'},'막힌 b파일을 피해 e2로 옆걸음해요.'),('MOVE',{'destination':'e5'},'열린 e파일을 따라 e5까지 올라가요.'),('MOVE',{'destination':'b5'},'이제 b5로 꺾어 문지기를 잡아요.')])
 put('3-3','ATTACK','ROOK VS KNIGHT',{'b2':'R','e4':'n'},'룩의 직선과 나이트의 L자는 달라요. 나이트가 다음 수에 잡을 수 없는 자리에서 공격해요.','move_the_rook',piece='r',target='e4')
 put('3-4','PROTECT','READY TO RECAPTURE',{'b2':'R','d4':'P','d6':'r'},'등불을 든 폰이 공격받아요. 폰을 잡으면 우리 룩이 되잡을 수 있게 지켜요.','protect_the_pawn',piece='r',target='d4',requireNewDefense=True)
 put('3-5','BATTERY','DOUBLED ROOKS',{'a1':'R','c2':'R','c5':'p'},'뒤의 룩을 c2 룩과 같은 파일에 연결해요. 앞의 룩이 전진해도 뒤의 룩이 받쳐 줄 수 있어요.','move_the_rook',piece='r',ally='c2',target='c5')
 put('3-6','MOVE','SEVENTH RANK',{},'열린 a파일로 a7까지 침투해요. 룩은 7번째 줄에서 상대 폰들을 옆으로 공격할 수 있어요.','move_the_rook',n=8,position='6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1',piece='r',destination='a7',safeMove=True)
 put('3-7','SKEWER','ROOK SKEWER',{},'한 직선에 왕과 퀸이 있어요. 왕에게 체크를 걸어 비키게 하면 뒤의 퀸이 드러나요.','check_the_king',n=8,position='3q4/8/3k4/8/8/8/8/R5K1 w - - 0 1',piece='r',target='d6',rear='d8')
 put('3-8','FORK','TWO-SIDED ATTACK',{'b2':'R','a5':'p','f5':'p'},'한 줄의 양쪽 문지기를 동시에 겨냥해요. 룩은 같은 직선의 양방향을 공격할 수 있어요.','attack_together',piece='r',targets=['a5','f5'])
 # BISHOP: same color, blockers, discovered line, absolute pin, diagonals at range.
 put('4-1','MOVE','DIAGONAL PATH',{'b2':'B'},'비숍은 대각선으로만 움직여요. b2에서 d4까지 같은 색의 칸을 따라가요.','move_the_bishop',piece='b',destination='d4')
 put('4-2','CAPTURE','TWO SQUARE COLORS',{'b1':'B','c1':'B','c2':'P','f4':'p'},'두 비숍은 서로 다른 색의 길을 맡아요. f4와 같은 색에서 출발한 비숍으로 문지기를 잡아요.','capture_the_pawn',piece='b',target='f4')
 m=put('4-3','CAPTURE','LONG DIAGONAL RESCUE',{'c1':'B','f1':'P','f4':'r','a5':'p'},'먼 곳의 룩이 우리 폰을 노려요. 긴 대각선을 따라 f4의 공격자를 먼저 잡아요.','capture_the_rook',piece='b',target='f4');m['threat']=['f4','f1']
 put('4-4','DISCOVERED_ATTACK','OPEN THE DIAGONAL',{'b1':'B','c2':'P','e4':'r'},'비숍 앞을 친구 폰이 막고 있어요. 폰을 안전하게 옮겨 비숍의 대각선 공격을 열어요.','move_forward',piece='p',ally='b1',target='e4')
 put('4-5','PIN','BISHOP PIN',{},'나이트 뒤에 왕이 있어요. 비숍으로 둘을 대각선에 묶으면 나이트는 왕을 노출하며 움직일 수 없어요.','move_the_bishop',n=8,position='8/4k3/5n2/8/8/8/8/2B3K1 w - - 0 1',piece='b',target='f6',rear='e7')
 put('4-6','PROTECT','DIAGONAL DEFENDER',{'f1':'B','c2':'R','c6':'r'},'룩의 직선과 비숍의 대각선이 만나게 해요. 친구 룩이 잡히면 비숍이 되잡을 수 있게 지켜요.','protect_the_rook',piece='b',target='c2',requireNewDefense=True)
 put('4-7','CHECK','DIAGONAL CHECK',{},'긴 대각선 끝의 왕을 겨냥해요. 비숍은 멀리서도 왕에게 체크를 걸 수 있어요.','check_the_king',n=8,position='7k/8/8/8/8/8/8/2B3K1 w - - 0 1',piece='b',safeMove=True)
 put('4-8','ATTACK','BISHOP VS ROOK',{'b1':'B','e6':'r'},'대각선으로 룩을 공격해요. 룩은 대각선으로 되잡을 수 없지만 다른 공격도 살펴야 해요.','attack_the_rook',piece='b',target='e6')
 # QUEEN: combined directions, safe long-range attack, fork, defense, skewer, mate vs stalemate, retreat/counterattack.
 m=put('5-1','MOVE','TWO KINDS OF PATH',{'b2':'Q'},'퀸은 룩과 비숍의 길을 모두 써요. 직선과 대각선을 차례로 사용해요.','move_the_queen',piece='q',destination='b4')
 route(m,[('MOVE',{'destination':'b4'},'먼저 직선으로 b4에 가요.'),('MOVE',{'destination':'e1'},'이번에는 대각선으로 e1에 가요.')])
 put('5-2','CAPTURE','CHOOSE THE DIAGONAL',{'b2':'Q','b5':'p','e5':'p'},'직선과 대각선 양쪽에 문지기가 있어요. 이번 목표인 e5의 폰을 대각선으로 잡아요.','capture_the_pawn',piece='q',target='e5')
 put('5-3','ATTACK','SAFE QUEEN ATTACK',{'b2':'Q','e4':'r'},'강한 퀸도 공짜로 내주면 안 돼요. 상대 룩이 다음 수에 잡을 수 없는 방향에서 공격해요.','attack_the_rook',piece='q',target='e4')
 put('5-4','FORK','QUEEN FORK',{'b2':'Q','a5':'r','e5':'r'},'퀸의 두 대각선으로 상대 룩 둘을 동시에 겨냥해요. 퀸 자체도 안전해야 해요.','attack_together',piece='q',targets=['a5','e5'])
 put('5-5','PROTECT','FLEXIBLE DEFENSE',{'b1':'Q','c4':'P','c6':'r'},'여왕은 멀리 있는 친구도 지켜요. 폰을 잡으면 퀸으로 되잡을 수 있게 수비를 만들어요.','protect_the_pawn',piece='q',target='c4',requireNewDefense=True)
 put('5-6','SKEWER','DIAGONAL SKEWER',{},'퀸은 직선뿐 아니라 대각선에서도 꼬치를 만들어요. 왕에게 체크하며 뒤의 룩을 드러내세요.','check_the_king',n=8,position='4r3/8/2k5/8/8/8/8/3Q2K1 w - - 0 1',piece='q',target='c6',rear='e8')
 put('5-7','CHECKMATE','MATE NOT STALEMATE',{},'도망갈 칸만 없애면 스테일메이트일 수 있어요. 체크까지 걸어 한 수에 승리해요.','checkmate_in_one',n=8,position='7k/8/5KQ1/8/8/8/8/8 w - - 0 1',piece='q',result='스테일메이트는 체크 없이 합법적인 수가 없는 무승부예요. 체크메이트는 체크를 피할 수 없는 상태예요.')
 m=put('5-8','SAFE_MOVE','RETREAT AND ATTACK',{'d4':'Q','f5':'n','a6':'r'},'나이트가 퀸을 노려요. 안전하게 물러난 뒤 퀸의 긴 공격으로 반격해요.','save_your_rook',piece='q',destination='c3',requireThreatened=True)
 m['englishExpressionIds']=['find_a_safe_move']
 route(m,[('SAFE_MOVE',{'destination':'c3'},'먼저 c3으로 물러나 나이트의 공격을 피해요.'),('ATTACK',{'destination':'','target':'f5'},'이제 퀸을 잡히지 않는 칸으로 옮겨 f5의 나이트를 공격해요. 상대가 멈춘 계획 연습이에요.')])
 # KING: separation, three responses to check, both castles and forbidden castling, mate.
 put('6-1','MOVE','KINGS KEEP DISTANCE',{},'왕끼리는 서로 붙을 수 없어요. 상대 왕의 공격 밖인 d1으로 이동해요.','protect_the_king',n=8,position='8/8/8/8/8/4k3/8/4K3 w - - 0 1',piece='k',destination='d1')
 put('6-2','ESCAPE_CHECK','ESCAPE CHECK',{},'체크를 받았어요. 왕을 공격받지 않는 칸으로 피하세요.','protect_the_king',n=8,position='4r1k1/8/8/8/8/8/8/4K3 w - - 0 1',piece='k')
 put('6-3','ESCAPE_CHECK','CAPTURE THE CHECKER',{},'왕도 상대 기물을 잡을 수 있어요. 다른 기물이 지키지 않는 e2의 룩을 잡아 체크를 없애요.','protect_the_king',n=8,position='6k1/8/8/8/8/8/4r3/4K3 w - - 0 1',piece='k',target='e2',captureChecker=True)
 put('6-4','BLOCK_CHECK','BLOCK THE CHECK',{},'직선 체크는 사이를 막을 수도 있어요. 비숍을 왕과 상대 룩 사이에 놓아 보세요.','protect_the_king',n=8,position='4r1k1/8/8/8/8/8/8/4KB2 w - - 0 1',piece='b')
 put('6-5','CASTLE','KINGSIDE CASTLING',{},'왕을 e1→g1로 움직이면 h1 룩도 f1로 와요. 둘 다 움직인 적 없고 길과 왕이 지나는 칸이 안전해야 해요.','protect_the_king',n=8,position='r5k1/5ppp/8/8/8/8/5PPP/4K2R w K - 0 1',piece='k',destination='g1',result='왕과 룩이 한 수에 함께 움직였어요. 왕이나 사용할 룩이 움직였다 돌아왔더라도 캐슬링 권리는 되살아나지 않아요.')
 put('6-6','CASTLE','QUEENSIDE CASTLING',{},'f1은 상대 룩의 공격을 받아요. 그쪽으로 캐슬링할 수 없어요. 안전한 c1 쪽으로 왕을 옮겨 보세요.','protect_the_king',n=8,position='5rk1/6pp/8/8/8/8/PPP3PP/R3K2R w KQ - 0 1',piece='k',destination='c1',result='퀸 쪽 캐슬링은 왕이 c1, 룩이 d1로 가요. 왕은 출발·통과·도착 칸 모두 공격받지 않아야 해요.')
 put('6-7','ESCAPE_CHECK','NO CASTLING IN CHECK',{},'길이 비어도 지금은 체크 중이라 캐슬링할 수 없어요. 먼저 왕을 안전한 칸으로 피하세요.','protect_the_king',n=8,position='4r1k1/8/8/8/8/8/8/4K2R w K - 0 1',piece='k',result='체크에서 캐슬링으로 도망칠 수는 없어요. 왕을 움직였으므로 이후 원래 자리로 돌아와도 캐슬링 권리는 없어요.')
 put('6-8','CHECKMATE','KING AND QUEEN TEAM',{},'왕은 퀸을 가까이서 지켜요. 둘의 힘을 합쳐 체크메이트로 성을 구하세요.','checkmate_in_one',n=8,position='7k/5Q2/6K1/8/8/8/8/8 w - - 0 1',piece='q')
