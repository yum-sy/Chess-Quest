"""Build self-contained Godot + chess.js + offline PWA."""
import hashlib,json,subprocess,zipfile,os
from pathlib import Path
r=Path(__file__).resolve().parents[1];d=r/'dist';d.mkdir(exist_ok=True)
(d/'.gdignore').touch()
godot=os.environ.get('GODOT_BIN',str(r.parent/'.tools/Godot.app/Contents/MacOS/Godot'))
subprocess.run([str(godot),'--headless','--path',str(r),'--editor','--import','--quit'],check=True)
subprocess.run([str(godot),'--headless','--path',str(r),'--export-release','Web'],check=True)
engine=(r/'node_modules/chess.js/dist/esm/chess.js').read_text()
engine=engine[:engine.rfind('export {')]
(d/'chess.js').write_text(engine+'\n'+(r/'web/bridge.js').read_text())
html=(d/'index.html').read_text().replace('"serviceWorker":"index.service.worker.js"','"serviceWorker":""')
html=html.replace('<head>','<head>\n<script src="chess.js"></script>\n<link rel="apple-touch-icon" href="icon-192.png"><meta name="apple-mobile-web-app-capable" content="yes"><meta name="theme-color" content="#367f7b">')
html=html.replace('</body>','''<script>if('serviceWorker' in navigator)navigator.serviceWorker.register('./sw.js',{updateViaCache:'none'}).then(r=>r.update());</script>
<a href="guide.html" style="position:fixed;bottom:5px;right:10px;color:#367f7b;font:12px sans-serif">Board lettering · v11.17.11 · Help</a></body>''')
(d/'index.html').write_text(html)
manifest={'name':'Chess Quest: The Lost Crown','short_name':'Chess Quest','start_url':'./index.html','scope':'./','id':'./','display':'standalone','orientation':'any','background_color':'#e8efdc','theme_color':'#367f7b','icons':[{'src':f'icon-{s}.png','sizes':f'{s}x{s}','type':'image/png','purpose':'any maskable'} for s in [192,512]]}
(d/'index.manifest.json').write_text(json.dumps(manifest))
# Original app icon, generated as SVG and rendered by macOS sips from a PNG generator.
import struct,zlib
for size in [192,512]:
 rows=[]
 for y in range(size):
  row=bytearray()
  for x in range(size):
   u=x/size;v=y/size
   crown=(.24<u<.76 and .42<v<.68) or (.24<u<.35 and .28<v<.46) or (.45<u<.55 and .22<v<.46) or (.65<u<.76 and .28<v<.46)
   row.extend((232,179,93,255) if crown else (54,127,123,255))
  rows.append(b'\0'+row)
 def chunk(t,b):return struct.pack('!I',len(b))+t+b+struct.pack('!I',zlib.crc32(t+b)&0xffffffff)
 (d/f'icon-{size}.png').write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('!2I5B',size,size,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(b''.join(rows)))+chunk(b'IEND',b''))
(d/'guide.html').write_text('''<!doctype html><html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Chess Quest 도움말</title><style>body{font:18px/1.8 system-ui;max-width:760px;margin:40px auto;padding:24px;background:#fff6df;color:#263e45}a{color:#367f7b}</style><h1>Chess Quest</h1><p>기물을 누르고 초록 점이 있는 목적지를 누르세요. 영어를 다시 듣거나 힌트를 자유롭게 사용할 수 있어요. 폰이 끝에 도착하면 새 기물을 고릅니다.</p><h2>설치와 오프라인</h2><p>인터넷에 연결된 상태로 처음 실행하고 다운로드를 기다리세요. iPad에서는 Safari의 공유 → 홈 화면에 추가를 사용하세요. Galaxy Chrome에서는 메뉴 → 앱 설치 / 홈 화면에 추가를 선택하세요. 오프라인 실행에는 최초 캐시 완료가 필요합니다.</p><h2>음성</h2><p>영어 안내는 OpenAI로 생성한 AI 음성입니다.</p><h2>저장</h2><p>진행과 현재 대국은 기기에 자동 저장됩니다. 브라우저 데이터 삭제 시 사라질 수 있습니다. 브라우저와 설치 앱 간 자동 동기화는 제공하지 않습니다.</p><p><a href="./">게임 시작</a> · <a href="source.zip">전체 소스 코드</a> · <a href="CREDITS.txt">라이선스와 크레딧</a></p></html>''')
(d/'CREDITS.txt').write_text((r/'CREDITS.txt').read_text())
with zipfile.ZipFile(d/'source.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in r.rglob('*'):
  if p.is_file() and p.name!='SPEC-v3.md' and not any(a in p.relative_to(r).parts for a in ['.git','.godot','node_modules','dist','evidence']):z.write(p,p.relative_to(r))
assets=sorted(p.name for p in d.iterdir() if p.is_file() and p.suffix not in ['.zip'] and not p.name.startswith('.') and p.name not in ['sw.js','index.service.worker.js'])
version=hashlib.sha256(b'cache-refresh-v2'+b''.join((d/n).read_bytes() for n in assets)).hexdigest()[:16]
(d/'sw.js').write_text('const CACHE="chess-quest-'+version+'";const FILES='+json.dumps(assets)+''';
self.addEventListener('install',e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(FILES.map(url=>new Request(url,{cache:'reload'})))).then(()=>self.skipWaiting())));
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k.startsWith('chess-quest-')&&k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',e=>{if(e.request.method!=='GET'||new URL(e.request.url).origin!==location.origin)return;e.respondWith(caches.match(e.request,{ignoreSearch:true}).then(async r=>r||(e.request.mode==='navigate' ? (await caches.match('index.html'))||fetch(e.request) : fetch(e.request))));});''')
(d/'.nojekyll').touch()
print('BUILD',version,'FILES',len(assets),'BYTES',sum((d/n).stat().st_size for n in assets))
