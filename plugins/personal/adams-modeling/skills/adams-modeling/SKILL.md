---
name: adams-modeling
description: MSC Adams 多体动力学建模、仿真与结果后处理技能，基于官方 Adamspy Python API 在 View 批处理模式下无界面运行。覆盖模型创建（部件/标记/几何/材料/力/约束/运动/设计变量/有限元）、模型验证与保存、动力学仿真、结果读取与测量，以及任意 Adams Command Language 命令逃生舱。用于机械系统多体动力学建模、机构运动学/动力学分析、仿真结果提取。
---

# Adams Modeling（Adamspy 多体动力学建模）

基于 MSC Adams 官方 Python 接口 **Adamspy** 的建模 + 仿真 + 后处理技能。Adamspy 是 Adams 的脚本化接口，必须在 Adams View 进程内运行（它通过 `__aview_main` 桥接层调用 View 内核）。

## 运行原理

Adamspy 不是独立的 Python 包：`import Adams` 依赖 View 进程注册的 `__aview_main` 原生桥接模块。因此**必须通过 View 启动 Python 脚本**，不能用普通 `python script.py`。

唯一可行的无界面运行方式是 **View 批处理模式**：

1. 写 Python 脚本（`import Adams` + 建模/仿真逻辑）
2. 写 View 命令文件 batch.cmd：`file python read file="<脚本绝对路径>"`
3. 运行：`mdi.bat aview ru-st b <batch.cmd>`

脚本的 `print` 输出会写到 `<ADAMS_HOME>/common/aview.log`（每次批处理运行前被覆盖）。

## 标准运行模板

在 Adams 安装目录（默认 `C:/Program Files/MSC.Software/Adams/<版本>`）下，wrapper.bat 内容：

```bat
@echo off
cd /d "C:\Program Files\MSC.Software\Adams\2020_711253\common"
call mdi.bat aview ru-st b "C:\path\to\batch.cmd"
```

batch.cmd 内容（注意：**不要加 exit**，View 用完命令文件会自动结束批运行；加 exit 会触发确认提示并报错）：

```
file python read file="C:\path\to\script.py"
```

调用：`cmd //c 'C:/path/to/wrapper.bat'`（Git Bash 下 wrapper 路径用正斜杠，脚本内反斜杠路径保持字面）。

## 核心工作流

1. **建模型**：`import Adams; m = Adams.Models.create(name=...)` → Parts/Markers/Geometries/Materials/Forces/Constraints
2. **验证**：`m.verify()`（输出 Gruebler 自由度、过约束检查）
3. **保存**：`Adams.write_binary_file(path)`（.bin）或 `Adams.write_command_file(path, m)`（.cmd）
4. **仿真**：`s = m.Simulations.create(name=..., end_time=..., number_of_steps=...)` → `s.simulate('analysis_name')`
5. **读结果**：`a = m.Analyses['analysis_name']` → `a.results[结果集][分量].values`
6. **后处理**：用 `Adams.execute_cmd(...)` 或 Measure API 提取/导出

## 最小可运行示例

```python
import Adams
m = Adams.Models.create(name='pendulum')
Adams.defaults.units.length = 'meter'
Adams.defaults.units.mass = 'kg'
Adams.defaults.units.time = 'second'

# 重力
grav = m.Forces.createGravity()
grav.xyz_component_gravity = [0, -9.81, 0]

# 摆杆（刚体）
p = m.Parts.createRigidBody(name='link', location=[0, 1.0, 0])
p.material_type = m.Materials.create(name='steel', youngs_modulus=2.07E11, poissons_ratio=0.29, density=7801.0)

# 地面铰点 + 杆端标记
ground = m.Parts['ground']
Adams.defaults.coordinate_system = ground
g_marker = ground.Markers.create(name='G_MAR', location=[0, 0, 0])

Adams.defaults.coordinate_system = p
p_marker = p.Markers.create(name='P_MAR', location=[0, 0, 0])

# 转动副（marker 用全路径 .模型.部件.MARKER）
m.Constraints.createRevolute(name='JOINT_1',
    i_marker_name='.pendulum.link.P_MAR',
    j_marker_name='.pendulum.ground.G_MAR')

# 验证 + 保存
m.verify()
Adams.write_binary_file(r'C:\temp\pendulum.bin')

# 仿真 2 秒 200 步
s = m.Simulations.create(name='sim1', end_time=2.0, number_of_steps=200)
s.simulate('sim1')

# 读结果：杆质心位移 X 随时间
a = m.Analyses['sim1']
t = a.results['TIME'].values                    # 时间数组
x = a.results['link_XFORM']['X'].values         # 位移 X 数组
print('SIM_OK', len(t), 'steps')
```

## API 速查

| 类别 | 方法 | 说明 |
|------|------|------|
| 模型 | `Adams.Models.create(name=)` | 创建模型 |
| 单位 | `Adams.defaults.units.{length,mass,time,angle,force}` | 设置单位制 |
| 部件 | `m.Parts.createRigidBody(name,location,orientation)` / `m.Parts.createFEPart(...)` / `m.Parts['ground']` | 刚体/FE 部件/地面 |
| 标记 | `part.Markers.create(name,location,orientation)` / `part.FloatingMarkers.create(name)` | 几何标记/浮动标记 |
| 几何 | `part.Geometries.createBlock/createCylinder/createEllipsoid/createFrustum/createEllipse/createArc/createLink/createOutline` | 基本几何体 |
| 材料 | `m.Materials.create(name,youngs_modulus,poissons_ratio,density)` | 材料定义 |
| 力 | `m.Forces.createGravity/createForceVector/createTorqueVector/createRotationalSpringDamper/createTranslationalSpringDamper/createBushing/createBeam/createField` | 各种力元 |
| 约束 | `m.Constraints.createRevolute/createTranslational/createCylindrical/createUniversal/createSpherical/createPlanar/createRackpin/createScrew/createConvel` | 运动副 |
| 驱动 | `m.Constraints.createJointMotion(name,joint_name,function=)` | 关节驱动（function 用 '...time' 表达式） |
| 设计变量 | `m.DesignVariables.createInteger/createReal/createString/createObject(name,value)` | 参数化 |
| 仿真 | `m.Simulations.create(name,end_time,number_of_steps,initial_static,script_type,script)` → `.simulate(analysis_name)` | 简单/脚本仿真 |
| 结果 | `m.Analyses[name].results[结果集][分量].values` | 结果数值数组 |
| 测量 | `m.Measures.createPoint/createPt2pt/createAngle/createComputed/createOrient/createRange/createFunction` | 后处理测量 |
| 保存 | `Adams.write_binary_file(path)` / `write_command_file(path, model)` / `m.exportAdmFile()` | 导出 .bin/.cmd/.adm |
| 读取 | `Adams.read_binary_file(path)` / `read_command_file(path)` | 读取模型 |
| 逃生舱 | `Adams.execute_cmd(cmd)` / `evaluate_exp(exp)` / `evaluate_real_exp(exp)` / `getCurrentModel()` | 任意 Adams cmd 命令 |

完整 API 签名见 `references/adamspy-api-reference.md`；运行细节与踩坑见 `references/batch-execution.md`。

## 结果数据结构

`a.results` 是嵌套字典，按结果集 → 分量组织：

- `a.results['TIME']` → `ResultComponent`，`.values` 是时间数组
- `a.results['<JOINT名>']` → OrderedDict，分量 `TIME/FX/FY/FZ/TX/TY/TZ`（关节反作用力/力矩）
- `a.results['<MOTION名>']` → OrderedDict，分量 `TIME/FX/FY/FZ/TX/TY/TZ/ANG`（运动副驱动载荷）
- `a.results['<部件名>_XFORM']` → OrderedDict，分量 `TIME/X/Y/Z/PSI/THETA/PHI/VX/VY/VZ/WX/WY/WZ/ACCX/ACCY/ACCZ/WDX/WDY/WDZ`（位移/欧拉角/速度/角速度/加速度/角加速度）

> **欧拉角语义（实测验证）**：Adams 用 Z-X-Z 欧拉角。XY 平面内转动的机构（最常见），绕 Z 的转角是 **PSI** 分量，THETA/PHI 恒 0（theta=0 表示未离开 XY 平面）。读摆角/转角用 `['PSI']`，不是 `['THETA']`。例如四杆机构摇杆摆角 = `a.results['rocker_XFORM']['PSI'].values`（实测 0°→66.66°）。

读取数值：`a.results['link_XFORM']['X'].values` 返回 float 列表。

## 常见任务配方

### 机构运动学分析（已知驱动，求位姿）
1. 建零件 + 约束 + 运动副 + `createJointMotion` 驱动
2. `m.verify()` 确认自由度
3. `Simulations.create(end_time, number_of_steps)` + `simulate()`
4. 读 `<部件>_XFORM` 的 `X/Y/Z`（位置）与 `PSI`（绕 Z 转角，XY 平面机构）分量

### 动力学分析（受力求运动）
1. 建零件 + 质量属性（material_type）+ 约束
2. 加力（gravity/force/spring_damper）
3. 仿真，读关节反力 `<JOINT名>` 的 `FX/FY/FZ`

### 参数扫描 / 优化
1. `m.DesignVariables.createReal(name, value)` 定义参数
2. 几何/力引用设计变量
3. 循环改 `dv.value` + `simulate()` + 读结果

### 有限元部件（柔性体简化）
1. `m.Parts.createFEPart(name, i_location, j_location, material_type)`
2. `m.Sections.createRectangular()` + `.rect_base/.rect_height`
3. `fep.setUniformSection(sec)` + `fep.addNode(x, section_label=sec)`

### 导出几何 / 与其他工具协同
- `Adams.write_geometry_file(type_of_geometry, file_name, **kwargs)` 导出几何
- `Adams.write_parasolid_file(file_name)` 导出 Parasolid
- `m.exportAdmFile()` 导出 ADAMS/Solver 输入文件

## 坑与注意

1. **必须在 View 进程内运行**：普通 `python script.py` 报 `ModuleNotFoundError: No module named '__aview_main'`。必须走 `mdi.bat aview ru-st b`。
2. **batch.cmd 不要加 exit**：`exit` 触发确认提示并报"无效的输入"。让 View 用完命令文件自动结束。
3. **marker 全路径格式**：`.模型名.部件名.MARKER名`，如 `.pendulum.link.P_MAR`。
4. **print 输出位置**：`<ADAMS_HOME>/common/aview.log`，每次运行被覆盖。
5. **Git Bash 反斜杠转义**：`cmd //c` 会吃掉 Windows 反斜杠，wrapper.bat 路径用正斜杠，脚本内路径保持反斜杠字面。
6. **simulate 后分析名**：不传 `analysis_name` 时分析用默认名（非仿真对象名），建议显式传 `s.simulate('自定义名')`。
7. **仿真需要 solver license**：仿真失败通常是无 solver 许可或模型过约束，先 `m.verify()` 排查。
8. **marker 定位约定**：`createRigidBody(location=...)` 的 location 是**质心全局坐标**，而 `part.Markers.create(location=...)` 的 location 是**相对质心的局部偏移**。关节的 i_marker 和 j_marker 必须全局重合（全局 = 质心 + 局部偏移），否则机构装配错误、运动学失真。
9. **移动副方向 = marker 的 Z 轴**：translational joint 沿 i/j marker 的 Z 轴滑动。要让活塞沿世界 X 轴滑动，两个 marker 的 orientation 都设 `[90, 90, 0]`（Z 轴转到 X 方向）。默认 `[0,0,0]` 的 Z 轴竖直，不能用于水平移动副。

## 参考

- `references/adamspy-api-reference.md` — 完整 API 签名（所有类与方法）
- `references/batch-execution.md` — 批处理运行、环境变量、调试技巧
- `examples/` — 三个已实测通过的完整示例（曲柄滑块 / 四杆机构 / 活塞曲柄）
