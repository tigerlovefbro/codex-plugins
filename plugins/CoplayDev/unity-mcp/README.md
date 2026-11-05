# Unity MCP

Unity 编辑器 MCP 桥接 + 编排技能，收录自 [CoplayDev/unity-mcp](https://github.com/CoplayDev/unity-mcp)（MIT，15.7k+ stars）。

## 内容

- `skills/unity-mcp-orchestrator/` — 编排技能：通过 MCP 工具与资源驱动 Unity 编辑器（GameObject/脚本/场景/Prefab/材质/VFX/测试），含资源优先工作流、工具 schema、最佳实践（references/ 共 4 篇）。
- `.mcp.json` — MCP server 配置（stdio：`uvx --from mcpforunityserver mcp-for-unity`）。

## 接入

1. **Unity 端**：Package Manager → Add package from git URL：
   `https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity#main`
2. **MCP 端**：安装 `uv`，首次运行会自动拉取 `mcpforunityserver`。
3. 在 Unity 中通过 MCPForUnity 面板连接。

## 许可

MIT — 版权 © 2025 CoplayDev（见 LICENSE）。
