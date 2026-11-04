# Releases：大文件分发

GitHub 仓库不适合放 >100 MB 的二进制，安装包与 Chrome MCP 组件放在 **Releases**：

https://github.com/tigerlovefbro/codex-plugins/releases/tag/assets-20261104

## 已上传

| 资产 | 大小 | 说明 |
|---|---|---|
| chrome-mcp-lite.zip | 4.6 MB | Chrome 扩展 + chrome-plugin + 安装脚本（不含 274 MB node_repl） |
| OpenAI.Codex_26.707.9564.0_x64__2p2nqsd0c76g0.Msix | 728 MB | 当前锁定版安装包 |

## 未上传（按需）

- 其他三个历史 MSIX（671 MB / 912 MB / 930 MB）；
- Chrome 完整组件（286 MB，含 node_repl，版本锁定）。

## 下载

~~~powershell
.\setup\releases\download-assets.ps1 -Dest "D:\CodexAssets"
~~~

只下某一个：

~~~powershell
.\setup\releases\download-assets.ps1 -Name "OpenAI.Codex_26.707.9564.0_x64__2p2nqsd0c76g0.Msix"
~~~

## 为什么用 Releases

- 单文件上限 2 GB，足够放 728 MB 的 MSIX；
- 不占 Git 历史，不会让 clone 变慢；
- 公开仓库的 Release 资产可直接下载，无需登录。
