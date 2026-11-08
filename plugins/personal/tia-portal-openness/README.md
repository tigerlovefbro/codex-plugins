# tia-portal-openness

Siemens TIA Portal V21 自动化技能。**首选方法是「小文老师博途 MCP」（node 版，30 工具），已实测在破解版 V21 上 connect/create/save 全通过**；裸 PowerShell Openness API 作为备选参考。

## 文件
- `skills/tia-portal-openness/SKILL.md`：核心技能（推荐 MCP 方法 + 裸 API + 全部实测坑）。
- `skills/tia-portal-openness/scripts/open_portal.ps1`：裸 API 可运行模板。
- `skills/tia-portal-openness/references/openness-api-reference.md`：API 细节。

## 前提
本机需安装 TIA Portal V21（`C:\Program Files\Siemens\Automation\Portal V21\`）。破解版可用（已验证）；首次连接需人工点「Openness 访问」授权窗口 + 确认 UAC，并把当前用户加入本地组 `Siemens TIA Openness`（本机已满足）。

## 关键
- MCP 包位置：`D:\云契·小白虎\v21 MCP\小文老师MCP\博图MCP\小文老师博途-20251101-v2.1.6\`
- 接入：stdio `node server.js`（零 npm/python 依赖）
- 能力边界：无法自动加 PLC（需人工加设备）、无编译接口（编译人工右键）。
