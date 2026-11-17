import os,subprocess
from pathlib import Path
r=Path(__file__).resolve().parents[1]
g=os.environ.get('GODOT_BIN',str(r.parent/'.tools/Godot.app/Contents/MacOS/Godot'))
for name in ['headless','oracle','learning','campaign','ui','ending','temple','selection','revision','puzzles','piece_curriculum','special_demo']:
 p=subprocess.run([g,'--headless','--path',str(r),'--script',f'tests/{name}.gd'],capture_output=True,text=True)
 (r/'evidence'/f'{name}.txt').write_text(p.stdout+p.stderr)
 print(name,p.returncode,(p.stdout+p.stderr).strip().splitlines()[-1])
 if p.returncode:raise SystemExit(p.returncode)
