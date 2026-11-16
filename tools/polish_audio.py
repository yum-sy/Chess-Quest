"""Trim GPT clip padding and match the previous pack's pace without shifting pitch.
Usage: python polish_audio.py /path/to/ffmpeg /path/to/previous/assets/audio
"""
import array,json,subprocess,sys,tempfile,wave
from pathlib import Path
root=Path(__file__).resolve().parents[1]
ffmpeg,reference=sys.argv[1],Path(sys.argv[2])
manifest=json.loads((root/'assets/audio/gpt-provenance.json').read_text())
for clip in manifest['clips']:
 name=clip['id']+'.wav';raw=Path.home()/'.cache/chess-quest/gpt-voice-v1'/name
 with wave.open(str(raw)) as wav:
  rate=wav.getframerate();channels=wav.getnchannels();pcm=wav.readframes(wav.getnframes())
  assert channels==1 and wav.getsampwidth()==2
 samples=array.array('h',pcm)
 active=[i for i,value in enumerate(samples) if abs(value)>180]
 assert active
 start=max(0,active[0]-int(rate*.045));end=min(len(samples),active[-1]+int(rate*.10))
 duration=(end-start)/rate
 with wave.open(str(reference/name)) as old:target=old.getnframes()/old.getframerate()
 tempo=min(1.45,max(1.0,duration/target))
 with tempfile.TemporaryDirectory() as tmp:
  source=Path(tmp)/name
  with wave.open(str(source),'wb') as wav:
   wav.setnchannels(1);wav.setsampwidth(2);wav.setframerate(rate);wav.writeframes(samples[start:end].tobytes())
  dest=root/'assets/audio'/name
  subprocess.run([ffmpeg,'-v','error','-y','-i',str(source),'-af',f'atempo={tempo:.5f}',str(dest)],check=True)
 with wave.open(str(dest)) as wav:clip['duration']=round(wav.getnframes()/wav.getframerate(),3)
 clip['tempo']=round(tempo,5);clip['previous_duration']=round(target,3)
manifest['processing']='Trim outer silence with 45ms/100ms padding; pitch-preserving tempo matching, maximum 1.45x.'
(root/'assets/audio/gpt-provenance.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
print('Polished',len(manifest['clips']),'clips')
