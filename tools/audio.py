import json,subprocess
from pathlib import Path
r=Path(__file__).resolve().parents[1]; (r/'assets/audio').mkdir(exist_ok=True)
e=json.loads((r/'data/expressions.json').read_text())
for x in e+[dict(audioId='praise',wordOrSentence='Great move!'),dict(audioId='retry',wordOrSentence='Let’s try again!'),dict(audioId='check',wordOrSentence='Your king is in danger!')]:
 dest=r/'assets/audio'/f"{x['audioId']}.wav"
 if dest.exists():continue
 subprocess.run(['say','-v','Samantha','-r','145','-o','/tmp/chess-quest-voice.aiff',x['wordOrSentence']],check=True)
 subprocess.run(['afconvert','-f','WAVE','-d','LEI16@22050','/tmp/chess-quest-voice.aiff',str(dest)],check=True)
print('Audio files:',len(list((r/'assets/audio').glob('*.wav'))))
