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
for i in range(8):add(7,'GAME',{},'Protect your king!' if i%2 else 'Great move!','정식 대국이에요. 힌트와 무르기를 마음껏 사용하세요.',position='rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')
for m in missions:
 if m['type']=='MOVE' and m['englishExpressionIds'][0]!='move_two':m['objective']['destination']=''
json.dump(missions,open(R/'data/missions.json','w'),ensure_ascii=False,indent=2)
vocab=[['pawn','move','forward','one','two','capture'],['knight','jump','over','left','right'],['rook','straight','attack','protect'],['bishop','diagonal','find','safe'],['queen','powerful','together','save'],['king','danger','check','checkmate'],['win','defend','great move']]
meanings=['폰,움직여요,앞으로,하나,둘,잡아요','나이트,뛰어요,넘어서,왼쪽,오른쪽','룩,직선으로,공격해요,지켜요','비숍,대각선으로,찾아요,안전해요','퀸,강해요,함께,구해요','킹,위험해요,체크,체크메이트','이겨요,방어해요,멋진 수예요']
for ch,words in enumerate(vocab,1):
 for word,meaning in zip(words,meanings[ch-1].split(',')):
  eid='word_'+word.replace(' ','_')
  expressions[eid]=dict(expressionId=eid,wordOrSentence=word.capitalize()+'!',meaning=meaning,learningLevel=1,relatedActions=['MOVE'],relatedPieces=[],audioId=eid,animationId='MOVE',reviewRules={'intervalDays':[1,3,7,14]},chapter=ch,practiceMission=(ch-1)*8 if ch<7 else 40)
json.dump(list(expressions.values()),open(R/'data/expressions.json','w'),ensure_ascii=False,indent=2)
