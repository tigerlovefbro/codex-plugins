# adams-modeling

MSC Adams 多体动力学建模、仿真与结果后处理技能（Skill），基于官方 Adamspy Python API，在 View 批处理模式下无界面运行。

## 能力

- **模型创建**：部件（刚体/FE）、标记、几何（长方体/圆柱/球/椭圆/圆台/连杆/样条轮廓）、材料、力（重力/矢量力/弹簧阻尼/衬套/梁/场力）、约束（转动/移动/圆柱/万向/球/平面/齿轮齿条/螺旋/等速）、运动副驱动、设计变量
- **模型验证与保存**：Gruebler 自由度校验、保存/读取 `.bin`、导出 `.cmd`/`.adm`/Parasolid
- **动力学仿真**：简单仿真与脚本仿真（end_time / number_of_steps / initial_static / ACF / 内联 cmd）
- **结果读取**：位移/速度/加速度/角速度/关节反力/运动副力/测量值，按结果集 + 分量提取数值数组
- **任意 Adams Command Language 命令逃生舱**（`Adams.execute_cmd`）

## 运行方式

通过 `mdi.bat aview ru-st b <batch.cmd>` 在批处理模式执行 Python 脚本，详见 SKILL.md。

## 目录结构

```
adams-modeling/
├── .codex-plugin/plugin.json   # 插件元数据
├── README.md
└── skills/adams-modeling/
    ├── SKILL.md                 # 主技能文档
    ├── references/
    │   ├── adamspy-api-reference.md  # 完整 API 参考
    │   └── batch-execution.md        # 批处理运行 + 环境 + 坑
    ├── examples/                # 可运行示例（已实测通过）
    │   ├── oscillating_slider.py
    │   ├── four_bar_linkage.py
    │   └── piston_crank.py
    └── scripts/
        └── run_adams.bat        # 批处理 wrapper 模板
```
