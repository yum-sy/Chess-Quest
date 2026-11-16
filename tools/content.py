import json
from pathlib import Path
R=Path(__file__).resolve().parents[1]
chapters=[('작은 병사의 출발','THE GARDEN','왕관의 빛이 사라졌어. 작은 병사와 첫걸음을 내딛자!','정원의 길이 열렸어! 다리 너머 기사를 찾아가자.'),('뛰어넘는 기사','THE BROKEN BRIDGE','다리가 무너졌어. 기사는 친구들을 뛰어넘을 수 있어!','멋진 점프야! 마법의 탑이 보인다.'),('마법의 탑','THE MAGIC TOWER','든든한 룩과 함께 성벽을 지키자.','성벽을 지켰어! 사원에 숨은 마법사를 만나자.'),('비밀의 사원','THE SECRET TEMPLE','비숍은 대각선을 따라 빛의 길을 찾아.','안전한 길을 찾았어! 여왕의 궁전으로 가자.'),('여왕의 귀환','THE QUEEN RETURNS','여왕과 힘을 합쳐 왕국의 친구들을 구하자.','여왕이 돌아왔어! 이제 위험에 빠진 왕을 지켜야 해.'),('위험에 빠진 왕','THE KING’S CASTLE','왕은 잡히지 않아. 체크를 막고 체크메이트를 만들어 보자.','왕을 구했어! 마지막 왕관의 전쟁이 기다려.'),('왕관의 전쟁','THE LOST CROWN','배운 모든 기물과 함께 모험을 완성하자. 천천히 두어도 괜찮아.','왕관을 되찾았어! 왕국에 빛과 웃음이 돌아왔어. 우리의 모험은 계속돼!')]
json.dump([dict(id=i+1,title=a,subtitle=b,intro=c,outro=d) for i,(a,b,c,d) in enumerate(chapters)],open(R/'data/chapters.json','w'),ensure_ascii=False,indent=2)
missions=[]; expressions={}
def fen(n,p):
 rows=[]
 for y in range(n,0,-1):
  s='';empty=0
  for x in range(n):
   v=p.get(chr(97+x)+str(y),'')
   if not v: empty+=1
   else:
    if empty:s+=str(empty)
    empty=0;s+=v
  if empty:s+=str(empty)
  rows.append(s)
 return '/'.join(rows)+' w - - 0 1'
def add(ch,kind,p,phrase,meaning,target='',piece='',dest='',position=None):
 n=4 if ch<3 else 6 if ch<6 else 8
 idx=sum(m['chapter']==ch for m in missions)+1
 eid=phrase.lower().replace('!','').replace('.','').replace(' ','_')
 expressions[eid]=dict(expressionId=eid,wordOrSentence=phrase,meaning=meaning,learningLevel=min(ch,4),relatedActions=[kind],relatedPieces=[piece],audioId=eid,animationId=kind,reviewRules={'intervalDays':[1,3,7,14]})
 missions.append(dict(id=f'{ch}-{idx}',chapter=ch,type=kind,difficulty='EASY' if idx<3 else 'NORMAL' if idx<6 else 'HARD',boardSize=n,initialPosition=position or fen(n,p),objective=dict(target=target,piece=piece,destination=dest),acceptedSolutions=[],opponentResponsePolicy='legal_capture_then_random',hints=[meaning,'초록 점은 이동할 수 있는 칸이에요.','빛나는 경로를 따라 움직여 보세요.'],englishExpressionIds=[eid],rewardId=f'reward-{ch}-{idx}',boss=idx>5))
add(1,'MOVE',{'b2':'P'},'Move forward!','폰을 앞으로 움직여요.',piece='p',dest='b3')
add(1,'MOVE',{'a2':'P'},'Move two!','처음 자리에서는 두 칸도 갈 수 있어요.',piece='p',dest='a4')
add(1,'CAPTURE',{'b2':'P','c3':'p'},'Capture the pawn!','대각선의 상대 폰을 잡아요.',target='c3',piece='p')
add(1,'MOVE',{'c2':'P','a2':'P'},'Move forward!','폰을 앞으로 움직여요.',piece='p',dest='c3')
add(1,'SAFE_MOVE',{'b2':'P','d4':'p'},'Find a safe move!','상대 폰이 공격하지 않는 칸을 찾아요.',piece='p')
add(1,'CAPTURE',{'c2':'P','b3':'p','d3':'p'},'Capture the pawn!','상대 폰 하나를 잡아요.',piece='p')
add(1,'SAFE_MOVE',{'a2':'P','c4':'p'},'Find a safe move!','안전한 칸으로 움직여요.',piece='p')
add(1,'CAPTURE',{'a2':'P','b3':'p','d4':'p'},'Capture the pawn!','마지막 문지기 폰을 잡아요.',target='b3',piece='p')
for i in range(8):
 if i in [0,1,3,5]:
  p={'b1':'N','b2':'P','c1':'P'} if i%2==0 else {'c1':'N','c2':'P','b1':'P'}
  add(2,'MOVE',p,'Jump over the pawn!','나이트는 친구를 뛰어넘어요.',piece='n',dest=('c3' if i%2==0 else 'b3'))
 elif i in [2,7]:add(2,'CAPTURE',{'b1':'N','c3':'p','b2':'P'},'Capture the pawn!','나이트로 상대 폰을 잡아요.',target='c3',piece='n')
 else:add(2,'SAFE_MOVE',{'c1':'N','c4':'p'},'Jump to safety!','나이트가 안전하게 착지할 곳을 찾아요.',piece='n')
for ch,piece,name in [(3,'R','rook'),(4,'B','bishop'),(5,'Q','queen')]:
 start='b2'; attack='e5' if ch==4 else 'e4'
 add(ch,'MOVE',{start:piece},f'Move the {name}!','룩은 직선, 비숍은 대각선, 퀸은 두 방향 모두 움직여요.',piece=piece.lower(),dest='d4' if ch==4 else 'b4')
 add(ch,'CAPTURE',{'b2':piece,'d4' if ch==4 else 'b5':'p'},'Capture the pawn!','새 친구와 상대 폰을 잡아요.',piece=piece.lower())
 if ch==4:
  scenarios=[
   ('CAPTURE',{'c1':'B','f1':'P','f4':'r','a5':'p'},'Capture the rook!','룩이 우리 폰을 노리고 있어요. 비숍으로 룩을 잡아 폰을 구해요.','f4',['f4','f1'],'룩을 잡았어요! 이제 우리 폰은 그 룩에게 잡히지 않아요.'),
   ('PROTECT',{'b1':'B','c4':'P','c6':'r'},'Protect the pawn!','폰이 룩의 공격을 받고 있어요. 폰이 잡히면 비숍으로 되잡을 수 있게 지켜요.','c4',['c6','c4'],'이제 룩이 폰을 잡으면 비숍이 룩을 되잡을 수 있어요. 보호는 상대의 포획 자체를 금지하지는 않아요.'),
   ('SAFE_MOVE',{'e3':'B','e6':'r','c5':'p'},'Save the bishop!','비숍이 룩에게 잡힐 위험이에요! 룩과 폰 모두 공격하지 않는 칸으로 피하세요.','',['e6','e3'],'비숍이 공격받는 줄에서 벗어났어요. 도착한 칸도 상대의 공격 밖이에요.'),
   ('CAPTURE',{'b2':'B','e5':'r','e1':'R','a5':'p'},'Capture the rook!','상대 룩이 우리 룩을 노려요. 비숍으로 상대 룩을 먼저 잡아 친구를 구하세요.','e5',['e5','e1'],'상대 룩을 먼저 잡았어요! 우리 룩은 그 공격에서 벗어났어요.'),
   ('PROTECT',{'f1':'B','c2':'R','c6':'r'},'Protect the rook!','상대 룩이 우리 룩을 노려요. 우리 룩이 잡히면 비숍으로 되잡을 수 있게 지켜요.','c2',['c6','c2'],'룩에 수비수가 생겼어요. 상대 룩이 우리 룩을 잡아도 비숍으로 되잡아 손해를 막을 수 있어요.'),
   ('SAFE_MOVE',{'c3':'B','f3':'r','d5':'p'},'Save the bishop!','룩이 비숍을 노리고 있어요. 도망갈 때 상대 폰의 대각선 공격도 피하세요.','',['f3','c3'],'룩의 공격을 피하고 폰의 함정에도 빠지지 않았어요!')
  ]
  for kind,position,phrase,brief,target,threat,result in scenarios:
   add(4,kind,position,phrase,brief,target=target,piece='b')
   m=missions[-1];m.update(briefing=brief,threat=threat,explanation=result,revision=2)
   m['objective']['requireThreatened']=kind=='SAFE_MOVE'
   m['objective']['requireNewDefense']=kind=='PROTECT'
   m['hints']=[brief,'주황색 공격선을 살펴보세요. 선택한 비숍의 초록 칸을 비교해요.','금색 경로가 목표를 해결하는 이동이에요.']
  continue
 add(ch,'ATTACK',{'b2':piece,attack:'r'},'Attack the rook!','움직인 뒤 상대 룩을 공격해요. 지금 잡는 것이 아니에요.',target=attack,piece=piece.lower())
 add(ch,'PROTECT',{'b2':piece,'d4':'P','d6':'r'},'Protect the pawn!','상대 룩이 폰을 잡으면 되잡을 수 있게 지켜요.',target='d4',piece=piece.lower())
 add(ch,'SAFE_MOVE',{'b2':piece,'f5':'r'},'Find a safe move!','상대의 공격을 받지 않는 칸으로 움직여요.',piece=piece.lower())
 add(ch,'ATTACK',{'a1':piece,'e5' if ch==4 else 'f5':'q'},'Attack the queen!','움직인 뒤 상대 퀸을 공격해요.',target='e5' if ch==4 else 'f5',piece=piece.lower())
 if ch==5:add(ch,'FORK',{'b2':'Q','a5':'r','e5':'r'},'Attack together!','퀸 하나로 상대 룩 둘을 동시에 공격해요.',piece='q')
 else:add(ch,'PROTECT',{'a1':piece,'c3':'P','c6':'r'},'Protect the pawn!','상대가 폰을 잡으면 되잡을 수 있게 지켜요.',target='c3',piece=piece.lower())
 add(ch,'SAFE_MOVE',{'c3':piece,'f6':'r','a5':'p'},'Find a safe move!','안전한 이동으로 다음 길을 열어요.',piece=piece.lower())
add(6,'CHECK',{},'Check the king!','상대 왕을 공격하되 우리 왕을 안전하게 지켜요.',piece='r',position='4k3/8/8/8/8/8/R7/4K3 w - - 0 1')
add(6,'ESCAPE_CHECK',{},'Protect the king!','왕이 체크를 받았어요. 체크에서 벗어나요.',piece='k',position='4r1k1/8/8/8/8/8/8/4K3 w - - 0 1')
add(6,'CHECKMATE',{},'Checkmate in one!','상대 왕이 빠져나올 수 없는 체크를 만들어요.',position='7k/5Q2/6K1/8/8/8/8/8 w - - 0 1')
add(6,'CHECKMATE',{},'Checkmate in one!','다른 배치에서도 체크메이트를 찾아요.',position='k7/2Q5/1K6/8/8/8/8/8 w - - 0 1')
add(6,'SAFE_MOVE',{},'Save your rook!','공격받는 룩을 안전한 칸으로 움직여요.',piece='r',position='6k1/8/8/4b3/8/2R5/8/6K1 w - - 0 1')
for pos in ['7k/8/5K2/3Q4/8/8/8/8 w - - 0 1','k7/8/2K5/4Q3/8/8/8/8 w - - 0 1','7k/8/8/4K3/8/1Q6/8/8 w - - 0 1']:
 add(6,'GAME',{},'Checkmate! You win!','AI와 번갈아 두어 체크메이트를 완성해요.',position=pos)
# Five short endgame lessons, then three complete games.
finals=[
 ('6k1/5ppp/8/8/8/8/5PPP/4R1K1 w - - 0 18',1,'닫힌 뒷줄을 찾아 룩으로 한 수 안에 체크메이트해요.'),
 ('7k/5Q2/6K1/8/8/8/8/8 w - - 0 27',1,'왕의 도움을 받는 퀸으로 한 수 안에 체크메이트해요. 스테일메이트에 주의해요.'),
 ('7k/8/8/8/8/8/1R6/R5K1 w - - 0 28',2,'두 룩이 번갈아 길을 막아요. 내 두 수 안에 체크메이트해요.'),
 ('7k/8/5K2/3Q4/8/8/8/8 w - - 0 32',2,'먼저 왕의 도망갈 길을 좁히고, 내 두 수 안에 체크메이트해요.'),
 ('7k/8/8/5K2/8/1Q6/8/8 w - - 0 36',3,'퀸으로 가두고 우리 왕을 가까이 데려와요. 내 세 수 안에 체크메이트해요.')]
for pos,limit,brief in finals:
 add(7,'GAME',{},'Checkmate in one!' if limit==1 else 'Checkmate! You win!',brief,position=pos)
 missions[-1].update(mateLimit=limit,briefing=brief,revision=2,opponentResponsePolicy='verified_defense')
for brief in ['첫 정식 대국이에요. 중앙으로 나아가고 왕을 안전하게 지켜요.','두 번째 정식 대국이에요. 공격 전에 내 기물이 안전한지 살펴봐요.','왕관을 되찾는 마지막 대국이에요. 배운 계획을 연결해 체크메이트를 완성해요.']:
 add(7,'GAME',{},'Protect your king!','정식 대국이에요. 힌트와 무르기를 마음껏 사용하세요.',position='rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')
 missions[-1].update(briefing=brief,revision=2)
# Retain explicit destinations. Moving somewhere unrelated is no longer a solution.
by_id={m['id']:m for m in missions}
def revise(id,p,**objective):
 m=by_id[id];m['initialPosition']=fen(m['boardSize'],p);m['objective'].update(objective);m['revision']=2
revise('1-5',{'b2':'P','c3':'p','a4':'p'},requireThreatened=True)
revise('1-6',{'c2':'P','b3':'p','d3':'p','a4':'p'},safeCapture=True)
revise('1-7',{'c2':'P','b3':'p','d4':'p'},requireThreatened=True)
revise('2-4',{'c1':'N','c2':'P','b1':'P'},destination='b3')
revise('2-5',{'c1':'N','b2':'p','c4':'p'},requireThreatened=True)
revise('2-7',{'b1':'N','c2':'p','b4':'p'},requireThreatened=True)
revise('2-8',{'b1':'N','c3':'p','a4':'p','b2':'P'},target='c3')
revise('3-5',{'b2':'R','f2':'r','c5':'p'},requireThreatened=True)
revise('3-8',{'c3':'R','f3':'r','a5':'p'},requireThreatened=True)
revise('5-4',{'b1':'Q','d4':'P','d6':'r'},requireNewDefense=True)
revise('5-5',{'b2':'Q','f2':'r','c4':'p'},requireThreatened=True)
revise('5-8',{'c3':'Q','f3':'r','a5':'p'},requireThreatened=True)
for id in ['3-4','3-7']:
 by_id[id]['objective']['requireNewDefense']=True
# Continuous path practice: the opponent stands still; finish both steps to earn the reward.
for id,goals,texts in [
 ('1-4',[{'destination':'c3'},{'destination':'c4'}],['하늘길로 갈 편지를 옮겨요. 먼저 c3으로 한 칸 전진해요.','편지를 문까지 배달해요. 이제 c4로 한 칸 더 전진해요.']),
 ('2-4',[{'destination':'b3'},{'destination':'d4'}],['끊어진 다리의 첫 발판 b3으로 뛰어요. 상대는 움직이지 않는 경로 연습이에요.','다음 발판 d4까지 한 번 더 뛰어 다리를 건너요.']),
 ('2-8',[{'target':'c3'},{'target':'a4'}],['다리의 두 문지기를 차례로 잡아요. 먼저 c3의 폰을 잡아요.','다리 끝 a4의 문지기까지 잡으면 친구들이 건널 수 있어요.'])]:
 m=by_id[id];m['sequence']=[dict(objective=g,briefing=t) for g,t in zip(goals,texts)];m['revision']=2
# Story beats frame a real purpose for each lesson, with longer scenes only at milestones.
stories=[
 ['왕관의 빛이 사라지자 정원의 문이 닫혔어요. 작은 폰이 첫 편지를 들고 길을 나섭니다.', '첫 걸음은 두 칸도 갈 수 있어요. 멀리 가기 전에 길이 비었는지 확인해요.', '문지기는 앞길이 아닌 대각선에 있어요. 폰의 이동과 잡는 방향을 구별해요.', '편지를 다리 입구까지 배달해야 해요. 폰은 돌아갈 수 없으니 두 걸음을 차례로 계획해요.', '숨어 있던 상대 폰이 다가왔어요. 지금 자리와 도착할 자리의 위험을 모두 살펴요.', '두 문지기 중 하나는 친구의 보호를 받고 있어요. 잡은 뒤에도 안전한 쪽을 골라요.', '정원 끝에는 대각선 함정이 있어요. 첫 두 칸 전진을 기억하며 안전한 길을 찾아요.', '마지막 문지기를 지나면 다리의 기사에게 편지를 전할 수 있어요.'],
 ['편지는 도착했지만 다리가 끊어졌어요. 나이트는 친구를 뛰어넘어 발판에 착지할 수 있어요.', '반대편 발판에서도 같은 모양으로 뛸 수 있을까요? 도착할 칸을 먼저 찾아요.', '다리 위 문지기를 잡아야 친구들이 따라올 수 있어요.', '두 발판을 이어 건너야 해요. 첫 점프만 성공해도 끝나는 것은 아니에요.', '발판 위 나이트가 공격받아요. 뛰어넘는 동안은 안전해도 착지하는 칸은 살펴야 해요.', '다리의 좁은 길은 친구가 막고 있어요. 나이트의 특별한 점프를 다시 사용해요.', '반대쪽에도 함정이 있어요. 상대 폰이 실제로 공격하는 대각선을 찾아요.', '두 문지기를 차례로 지나 마지막 밧줄을 풀어요. 나이트가 길을 열면 탑의 친구가 기다려요.'],
 ['탑의 불이 꺼졌어요. 룩이 곧은 복도를 따라 등불을 찾아 나섭니다.', '복도를 막은 문지기를 잡고 등불을 되찾아요.', '상대 룩을 겨냥하면 다음 길을 열 수 있어요. 잡기와 공격 준비는 달라요.', '등불을 든 폰이 공격받아요. 친구가 잡히면 되잡을 수 있게 지켜요.', '등불을 떨어뜨리지 않도록 상대의 공격 밖으로 옮겨요.', '탑 꼭대기에서 상대 퀸이 길을 막아요. 룩의 긴 직선으로 겨냥해요.', '마지막 등불을 운반하는 폰 곁에 수비수를 보내요.', '탑의 불을 밝혔어요. 안전한 길을 골라 사원으로 향할 준비를 해요.'],
 ['탑에서 비춘 빛이 사원의 대각선 길을 드러냈어요. 비숍과 함께 잃어버린 문양을 찾아요.', '같은 색의 길 위에 문지기가 있어요. 비숍으로 대각선을 따라가요.', '상대 룩이 문양을 든 폰을 노려요. 공격자를 먼저 막아야 해요.', '이번에는 폰을 직접 구할 수 없어요. 잡히더라도 되잡을 수 있게 준비해요.', '문양을 찾던 비숍이 공격받아요. 도망갈 곳에도 함정이 없는지 살펴요.', '친구 룩이 출구를 지키고 있어요. 비숍으로 친구를 위협하는 룩을 잡아요.', '출구 앞의 룩을 혼자 두지 마세요. 서로 지키는 자리를 찾아요.', '마지막 함정을 피하면 사원의 문양이 완성돼요. 문양은 여왕의 궁전을 가리킵니다.'],
 ['사원의 문양이 궁전 문을 열었어요. 여왕은 직선과 대각선의 힘을 함께 사용해요.', '궁전 계단의 문지기를 잡아 여왕의 길을 열어요.', '궁전의 긴 길을 이용해 상대 룩을 겨냥해요.', '왕에게 소식을 전할 폰을 지켜야 해요.', '여왕도 공격받을 수 있어요. 강한 기물일수록 도착할 칸을 살펴요.', '상대 퀸을 겨냥해 친구들이 지나갈 틈을 만들어요.', '두 곳을 함께 공격하면 상대는 모두 지키기 어려워져요.', '여왕과 함께 안전한 길을 찾았어요. 이제 왕의 성에서 들리는 도움 요청을 따라가요.'],
 ['왕의 성에 도착했어요. 왕은 잡는 기물이 아니라 공격받으면 반드시 피해야 하는 기물이에요.', '우리 왕에게 체크가 걸렸어요. 먼저 위험을 없애야 다른 계획을 세울 수 있어요.', '왕을 공격하는 것만으로는 끝나지 않아요. 빠져나갈 길이 하나도 없는 체크를 찾아요.', '반대편 모서리에서도 왕과 퀸의 협력을 확인해요.', '왕을 돕는 룩이 위험해요. 안전하게 구해야 마지막 계획을 이어갈 수 있어요.', '이제 상대가 실제로 응수해요. 왕과 퀸을 함께 움직여 도망갈 공간을 좁혀요.', '성의 다른 문에서도 같은 원리를 연습해요. 급히 체크하기보다 길을 막는 수를 찾아요.', '왕의 성을 지켜냈어요. 마지막 왕관을 찾기 전에 끝내는 기술을 정리해요.'],
 ['왕관의 성으로 가는 길에서 이미 진행된 대국을 만났어요. 먼저 닫힌 뒷줄을 이용해 한 수로 끝내요.', '두 번째 문은 왕과 퀸이 함께 열어요. 체크가 없는 막힘은 승리가 아니라 무승부예요.', '세 번째 문에는 두 룩이 필요해요. 하나가 길을 막으면 다른 하나가 마무리해요.', '바로 체크할 필요는 없어요. 상대의 다음 수까지 생각해 도망갈 길을 먼저 좁혀요.', '마지막 연습은 세 수 계획이에요. 퀸으로 가두고 왕을 도우러 보내 마무리해요.', '이제 처음 배치부터 정식 대국을 시작해요. 폰과 나이트로 길을 열고 왕을 지키세요.', '다음 대국에서는 서로 지키는 기물을 만들어 보세요. 한 수마다 상대의 위협도 확인해요.', '왕관을 되찾을 마지막 대국이에요. 정원에서 배운 첫 걸음부터 함께 만든 모든 계획을 연결해요.']]
for m in missions:
 idx=int(m['id'].split('-')[1])-1
 m['story']=stories[m['chapter']-1][idx];m['storyBeat']=idx in [0,3,7] or (m['chapter']==7 and idx==5)
 m.setdefault('briefing',m['hints'][0])
 if m['chapter']<=2:m['briefing']=m['story']
 if m['type']=='MOVE':m['briefing']+=' 도착점: '+m['objective']['destination']+'.'
 if m['chapter']<=3:m['revision']=max(2,m.get('revision',1))
 if m['id']=='1-6':m['objective']['safeCapture']=True
json.dump(missions,open(R/'data/missions.json','w'),ensure_ascii=False,indent=2)
vocab=[['pawn','move','forward','one','two','capture'],['knight','jump','over','left','right'],['rook','straight','attack','protect'],['bishop','diagonal','find','safe'],['queen','powerful','together','save'],['king','danger','check','checkmate'],['win','defend','great move']]
meanings=['폰,움직여요,앞으로,하나,둘,잡아요','나이트,뛰어요,넘어서,왼쪽,오른쪽','룩,직선으로,공격해요,지켜요','비숍,대각선으로,찾아요,안전해요','퀸,강해요,함께,구해요','킹,위험해요,체크,체크메이트','이겨요,방어해요,멋진 수예요']
for ch,words in enumerate(vocab,1):
 for word,meaning in zip(words,meanings[ch-1].split(',')):
  eid='word_'+word.replace(' ','_')
  expressions[eid]=dict(expressionId=eid,wordOrSentence=word.capitalize()+'!',meaning=meaning,learningLevel=1,relatedActions=['MOVE'],relatedPieces=[],audioId=eid,animationId='MOVE',reviewRules={'intervalDays':[1,3,7,14]},chapter=ch,practiceMission=(ch-1)*8 if ch<7 else 40)
json.dump(list(expressions.values()),open(R/'data/expressions.json','w'),ensure_ascii=False,indent=2)

# Keep bounded-mate proofs synchronized whenever content is regenerated.
import subprocess
subprocess.run(["node",str(R/"tools/puzzle_book.mjs")],check=True)
