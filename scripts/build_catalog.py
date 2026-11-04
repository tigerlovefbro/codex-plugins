import json, os
from pathlib import Path
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / ".agents" / "plugins" / "marketplace.json"

def read_json(p):
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return {}

manifest = read_json(MANIFEST)
plugins_out = []
skills_index = []
mcp_index = []
counts = {"plugins": 0, "with_skills": 0, "with_mcp": 0, "codex_only": 0}

for item in manifest.get("plugins", []):
    rel = (item.get("source") or {}).get("path", "")
    if rel.startswith("./"):
        rel = rel[2:]
    pdir = ROOT / rel
    if not pdir.exists():
        continue
    meta = read_json(pdir / ".codex-plugin" / "plugin.json")
    iface = meta.get("interface") or {}
    name = item.get("name") or meta.get("name") or pdir.name
    skills = []
    seen = set()
    for sm in pdir.rglob("SKILL.md"):
        skill_dir = sm.parent
        key = str(sm.relative_to(ROOT)).lower()
        if key in seen:
            continue
        seen.add(key)
        entry = {
            "name": skill_dir.name,
            "path": sm.relative_to(ROOT).as_posix(),
        }
        skills.append(entry)
        skills_index.append({"plugin": name, "skill": skill_dir.name, "path": entry["path"]})
    servers = []
    mcp_files = []
    m = read_json(pdir / ".mcp.json")
    if isinstance(m.get("mcpServers"), dict) and m["mcpServers"]:
        servers.extend(m["mcpServers"].keys())
        mcp_files.append((pdir / ".mcp.json").relative_to(ROOT).as_posix())
    pm = meta.get("mcpServers")
    if isinstance(pm, dict):
        for k in pm.keys():
            if k not in servers:
                servers.append(k)
    if servers:
        mcp_index.append({"plugin": name, "servers": servers, "path": mcp_files[0] if mcp_files else None})
    author = meta.get("author")
    if isinstance(author, dict):
        author = author.get("name") or author.get("url")
    tools = {
        "codex": True,
        "claude": bool(skills),
        "dsh": bool(skills),
        "mcp": bool(servers),
    }
    plugins_out.append({
        "id": name,
        "name": name,
        "displayName": iface.get("displayName") or name,
        "description": meta.get("description") or iface.get("shortDescription") or "",
        "version": meta.get("version") or item.get("version") or "",
        "category": item.get("category") or iface.get("category") or "",
        "author": author or "",
        "repository": meta.get("repository") or meta.get("homepage") or "",
        "license": meta.get("license") or "",
        "codexPath": pdir.relative_to(ROOT).as_posix(),
        "skills": skills,
        "mcpServers": servers,
        "tools": tools,
    })
    counts["plugins"] += 1
    if skills:
        counts["with_skills"] += 1
    if servers:
        counts["with_mcp"] += 1
    if not skills and not servers:
        counts["codex_only"] += 1

out_dir = ROOT / "catalog"
out_dir.mkdir(exist_ok=True)
summary = {
    "schema": 1,
    "generatedAt": datetime.now(timezone.utc).isoformat(),
    "marketplace": manifest.get("name"),
    "displayName": (manifest.get("interface") or {}).get("displayName"),
    "totals": counts,
    "skillCount": len(skills_index),
}
(out_dir / "plugins.json").write_text(json.dumps({"summary": summary, "plugins": plugins_out}, ensure_ascii=False, indent=2), encoding="utf-8")
(out_dir / "skills.json").write_text(json.dumps(skills_index, ensure_ascii=False, indent=2), encoding="utf-8")
(out_dir / "mcp.json").write_text(json.dumps(mcp_index, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(summary, ensure_ascii=False, indent=2))
print("files:", os.path.getsize(out_dir/"plugins.json"), os.path.getsize(out_dir/"skills.json"), os.path.getsize(out_dir/"mcp.json"))
