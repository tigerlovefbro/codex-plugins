# Setup：安装包与版本锁定

## 本地合并目录

D:\云契·小白虎\codex\安装包+锁定版本\

- 安装包\  -> 指向 ..\安装包（4 个 MSIX，共约 3.1 GB）
- 锁定版本\ -> lock/restore 脚本与 bat
- 本目录的脚本也会同步到仓库 setup/lock-version

## 为什么不把 MSIX 放进 Git

- 单文件 671–975 MB，超过 GitHub 100 MB 文件限制；
- 4 个版本共 3.1 GB，会把仓库撑爆。

仓库只保留 setup/installers/README.md 与 SHA256SUMS.txt；安装包请留在本地，或用 GitHub Releases 附件分发。

## 当前机器快照（2026-11-05）

`setup/snapshot/` 固化了本机正在用的 Codex 桌面端：版本指纹、config.toml（中转地址为占位符）、AGENTS、启动器、APPLY/CHECK 脚本。系统提示词与中转地址真值在私有仓库 [codex-private](https://github.com/tigerlovefbro/codex-private)，用该仓库的 `APPLY-PRIVATE.ps1` 写回。
完整还原步骤见 [`NEW-MACHINE.md`](./NEW-MACHINE.md)，快照说明见 [`snapshot/README.md`](./snapshot/README.md)。

## 锁定版本

双击 锁定版本\锁定更新-双击运行.bat（需要管理员），会向 hosts 写入 3 个更新域名的屏蔽。
恢复：双击 恢复更新-双击运行.bat。

锁定基于 hosts，和安装包版本无关；换电脑时先装对应 MSIX，再运行锁定脚本。
