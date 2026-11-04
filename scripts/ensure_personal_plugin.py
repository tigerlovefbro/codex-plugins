import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
p = ROOT / ".agents" / "plugins" / "marketplace.json"
m = json.loads(p.read_text(encoding="utf-8"))
name = "personal-toolkit"
if not any(x.get("name") == name for x in m["plugins"]):
    m["plugins"].append({
        "name": name,
        "source": {"source": "local", "path": "./plugins/personal/personal-toolkit"},
        "policy": {"installation": "AVAILABLE", "authentication": "ON_INSTALL"},
        "category": "Personal",
    })
    p.write_text(json.dumps(m, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("added personal-toolkit")
else:
    print("personal-toolkit already present")
