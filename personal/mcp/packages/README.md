# Personal MCP 安装包（完整服务器包）

这些是「小文老师」出品的工业自动化 MCP 服务器安装包（原始 zip 原样备份，便于换机分发与版本回溯）。
与上级 `personal/mcp/` 里的「配置片段」不同，这里是**完整可安装的服务器包**（自带运行环境）。

| 文件名 | 用途 | 版本 | 运行方式 | 安装路径 |
|---|---|---|---|---|
| 小文老师iFA-MCP-20261031-v1.3.1.zip | 操作 iFA Evolution（Inovance FA/HMI/PLC 编程软件，走官方 gRPC Open API） | v1.3.1 | 内置 Python 3.12 | 解压到 `C:\ifa-mcp` |
| 小文老师Inoproshop-20261031-v1.3.9.zip | 操作汇川 InoProShop V1.10.0.3（CODESYS 内核 + ScriptEngine 桥接） | v1.3.9 | 内置 Python 3.12 | 解压到 `C:\inoproshop-mcp` |
| 小文老师博途-20251101-v2.1.6.zip | 操作西门子博途 TIA Portal V21（Openness API） | v2.1.6 | Node.js + PowerShell | 解压后双击 `一键安装.bat` |

## 安装要点

- **iFA-MCP**：解压到 `C:\ifa-mcp`，双击 `一键注册.cmd`（自动注册到 DeepSeek Harness 的 `cordis.patch.yml` 与 Claude Desktop）。使用前对 AI 说「准备开始IFA」。
- **Inoproshop**：解压到 `C:\inoproshop-mcp`，双击 `安装向导.cmd` 选客户端。需已装 InoProShop V1.10.0.3。
- **博途**：解压后双击 `一键安装.bat`（需 Node.js），注销并重新登录一次。需已装博途 V21 并开启 Openness 访问。

## 备注

- 原始来源目录：`D:\小文老师MCP\`（子目录 ifamcp / INPMCP / 博图MCP）。
- 均为 zip 原样备份，未解压入库（内置 Python 运行库体积较大，且解压后中文文件名在个别系统代码页下可能乱码）。
- 各包自带 `README.md`，建议路径不含空格。
