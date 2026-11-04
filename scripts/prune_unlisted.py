import json, shutil, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APPLY = '--apply' in sys.argv
m = json.loads((ROOT/'.agents/plugins/marketplace.json').read_text(encoding='utf-8'))
listed = []
for p in m['plugins']:
    rel = p['source']['path']
    rel = rel[2:] if rel.startswith('./') else rel
    listed.append(rel.replace('\\','/').lower())

def inside_listed(rel):
    return any(rel == l or rel.startswith(l + '/') for l in listed)

def ancestor_of_listed(rel):
    return any(l.startswith(rel + '/') for l in listed)

targets = []
for pj in ROOT.glob('plugins/**/.codex-plugin/plugin.json'):
    d = pj.parent.parent
    rel = d.relative_to(ROOT).as_posix()
    low = rel.lower()
    if low in listed or inside_listed(low) or ancestor_of_listed(low):
        continue
    targets.append((rel, d, sum(f.stat().st_size for f in d.rglob('*') if f.is_file())))

total = sum(t[2] for t in targets)
print(f"targets={len(targets)} size={total/1024/1024:.2f} MB")
for rel, d, size in sorted(targets, key=lambda x: -x[2]):
    print(f"  {size/1024/1024:6.2f} MB  {rel}")

if APPLY:
    for rel, d, size in targets:
        shutil.rmtree(d, ignore_errors=True)
        print("deleted", rel)
