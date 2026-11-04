import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
p = ROOT / ".agents" / "plugins" / "marketplace.json"
m = json.loads(p.read_text(encoding="utf-8"))

plugins = [
    ("personal-toolkit", "./plugins/personal/personal-toolkit"),
    ("mcp-sync", "./plugins/personal/mcp-sync"),
    ("task-router", "./plugins/personal/task-router"),
]
changed = False
for name, path in plugins:
    if any(x.get("name") == name for x in m["plugins"]):
        continue
    m["plugins"].append({
        "name": name,
        "source": {"source": "local", "path": path},
        "policy": {"installation": "AVAILABLE", "authentication": "ON_INSTALL"},
        "category": "Personal",
    })
    changed = True
    print("added", name)

if changed:
    p.write_text(json.dumps(m, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("plugins", len(m["plugins"]))
