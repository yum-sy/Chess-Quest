"""Generate the offline voice pack; the private key stays outside the project."""
import json, os, urllib.request, urllib.error, wave, io, time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
STAGE=Path.home()/'.cache/chess-quest/gpt-voice-v2'
MODEL='gpt-4o-mini-tts'
VOICE='coral'
INSTRUCTIONS=('Use a distinctly HIGH-PITCHED, bright, youthful ADULT FEMALE voice. '
 'You are a cheerful female primary-school English teacher speaking clearly to a child. '
 'Keep your speaking register high and light throughout each phrase, with a smiling upward lilt. '
 'Project your voice clearly at a confident, full conversational volume. '
 'Warm and friendly, never hushed, breathy, whispered, low-register, sleepy or intimate. '
 'Gentle means kind, NOT quiet or low-pitched. Crisp vowels and consonants, smooth natural delivery. '
 'Speak around 145 words per minute, without long pauses or drawn-out syllables. '
 'No baby talk, cartoon squeaks or shouting. Say only the supplied text.')
def main():
 key=os.environ.get('OPENAI_API_KEY','')
 if not key:
  for line in (Path.home()/'.config/chess-quest/openai.env').read_text().splitlines():
   if line.strip().startswith('OPENAI_API_KEY='):key=line.split('=',1)[1].strip().strip('\"\'')
 if not key or key=='PASTE_YOUR_KEY_HERE':raise SystemExit('API key has not been configured.')
 entries=json.loads((ROOT/'data/expressions.json').read_text())
 entries += [dict(audioId=k,wordOrSentence=v) for k,v in [('praise','Great move!'),('retry','Let’s try again!'),('check','Your king is in danger!')]]
 lines={x['audioId']:x['wordOrSentence'] for x in entries}
 STAGE.mkdir(parents=True,exist_ok=True)
 records=[]
 for ident,sentence in lines.items():
  dest=STAGE/(ident+'.wav')
  if not dest.exists():
   req=urllib.request.Request('https://api.openai.com/v1/audio/speech',data=json.dumps(dict(model=MODEL,voice=VOICE,input=sentence,instructions=INSTRUCTIONS,response_format='wav',speed=1.0)).encode(),headers={'Authorization':'Bearer '+key,'Content-Type':'application/json'})
   try:
    with urllib.request.urlopen(req,timeout=120) as response:data=response.read()
   except urllib.error.HTTPError as error:
    try:code=json.loads(error.read()).get('error',{}).get('code','unknown')
    except Exception:code='unknown'
    raise SystemExit('Speech API failed: HTTP '+str(error.code)+'; code='+str(code))
   with wave.open(io.BytesIO(data)) as wav:
    if wav.getnframes()<100:raise SystemExit('Invalid audio for '+ident)
   dest.write_bytes(data)
  # Streaming WAV headers can carry a sentinel length; normalize to actual PCM.
  with wave.open(str(dest)) as wav:
   channels,width,rate=wav.getnchannels(),wav.getsampwidth(),wav.getframerate()
   pcm=wav.readframes(wav.getnframes())
  with wave.open(str(dest),'wb') as wav:
   wav.setnchannels(channels);wav.setsampwidth(width);wav.setframerate(rate);wav.writeframes(pcm)
  duration=len(pcm)/(channels*width*rate)
  records.append(dict(id=ident,text=sentence,duration=round(duration,3)))
  print(ident,round(duration,2),'seconds',flush=True)
 for record in records:
  name=record['id']+'.wav';(ROOT/'assets/audio'/name).write_bytes((STAGE/name).read_bytes())
 (ROOT/'assets/audio/gpt-provenance.json').write_text(json.dumps(dict(provider='OpenAI',model=MODEL,voice=VOICE,instructions=INSTRUCTIONS,clips=records),ensure_ascii=False,indent=2))
 print('Installed',len(records),'GPT voice clips.')
if __name__=='__main__':main()
