"""Apply the approved 0.90x pace to the bright voice pack, without lowering pitch.
Usage: python retime_audio.py /path/to/ffmpeg
Re-running on the same voice pack is a no-op.
"""
import json,subprocess,sys,tempfile,wave
from pathlib import Path
root=Path(__file__).resolve().parents[1]
manifest_path=root/'assets/audio/gpt-provenance.json'
manifest=json.loads(manifest_path.read_text())
if manifest.get('playback_tempo')==.9:
 print('Voice pack already uses 0.90x pace.');sys.exit(0)
with tempfile.TemporaryDirectory(prefix='chess-quest-pace-') as tmp:
 for clip in manifest['clips']:
  name=clip['id']+'.wav';source=root/'assets/audio'/name;dest=Path(tmp)/name
  subprocess.run([sys.argv[1],'-v','error','-y','-i',str(source),'-af','atempo=0.90',str(dest)],check=True)
  with wave.open(str(dest)) as w:
   clip['duration_before_retime']=clip['duration']
   clip['duration']=round(w.getnframes()/w.getframerate(),3)
 for clip in manifest['clips']:
  name=clip['id']+'.wav';(root/'assets/audio'/name).write_bytes((Path(tmp)/name).read_bytes())
manifest['playback_tempo']=.9
manifest['processing']+=' Final pitch-preserving 0.90x tempo for child-friendly listening.'
manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
print('Retimed',len(manifest['clips']),'clips to 0.90x.')
