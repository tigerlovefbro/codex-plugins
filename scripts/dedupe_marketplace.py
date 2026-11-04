import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
p = ROOT / ".agents" / "plugins" / "marketplace.json"
m = json.loads(p.read_text(encoding="utf-8"))
seen = set()
out = []
for item in m.get("plugins", []):
    name = item.get("name")
    if name in seen:
        print("drop duplicate:", name)
        continue
    seen.add(name)
    out.append(item)
if len(out) != len(m.get("plugins", [])):
    m["plugins"] = out
    p.write_text(json.dumps(m, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("plugins now", len(out))
else:
    print("no duplicates")
