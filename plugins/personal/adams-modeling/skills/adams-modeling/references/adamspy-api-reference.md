# Adamspy API 完整参考

基于 MSC Adams 2020 自带 `adamspy` 包（`<ADAMS_HOME>/python/win64/Lib/site-packages/mdi/adamspy/`）。所有对象通过 `import Adams` 使用。

## 顶层（Adams 模块）

| 函数 | 签名 | 说明 |
|------|------|------|
| `Models.create` | `Adams.Models.create(name=...)` | 创建并激活模型，返回 Model 对象 |
| `defaults` | `Adams.defaults` | 全局默认值对象 |
| `getCurrentModel` | `Adams.getCurrentModel()` | 返回当前模型 Model 对象 |
| `execute_cmd` | `Adams.execute_cmd(cmd)` | 执行任意 Adams Command Language 命令（万能逃生舱） |
| `evaluate_exp` | `Adams.evaluate_exp(exp)` | 求值表达式，返回结果 |
| `evaluate_real_exp` | `Adams.evaluate_real_exp(exp)` | 求值实数表达式 |
| `write_binary_file` | `Adams.write_binary_file(file_name)` | 保存模型为 .bin（内部执行 file binary write + model display） |
| `read_binary_file` | `Adams.read_binary_file(file_name)` | 读取 .bin 模型 |
| `write_command_file` | `Adams.write_command_file(file_name, model)` | 导出 .cmd 命令文件 |
| `read_command_file` | `Adams.read_command_file(file_name)` | 读取 .cmd 文件 |
| `write_geometry_file` | `Adams.write_geometry_file(type_of_geometry, file_name, **kwargs)` | 导出几何（kwargs: model_name/part_name/analysis_name+frame_number） |
| `read_geometry_file` | `Adams.read_geometry_file(type_of_geometry, file_name, **kwargs)` | 导入几何（kwargs: location/orientation/model_name/part_name） |
| `write_parasolid_file` | `Adams.write_parasolid_file(file_name)` | 导出 Parasolid 几何 |
| `read_parasolid_file` | `Adams.read_parasolid_file(file_name)` | 读取 Parasolid 几何 |
| `undo` / `redo` | `Adams.undo()` / `Adams.redo()` | 撤销/重做 |

`defaults` 对象属性：
- `d.units.length` / `d.units.mass` / `d.units.time` / `d.units.angle` / `d.units.force`（字符串，如 'inch'/'meter'/'pound_mass'/'kg'/'second'/'degrees'/'pound_force'）
- `d.coordinate_system`（当前坐标系，设为 ground 或 part）
- `d.model`（当前模型）

## Model 对象

`m = Adams.Models.create(name=...)` 返回的 Model：

| 成员 | 说明 |
|------|------|
| `m.name` | 模型名 |
| `m.Parts` | 部件管理器 |
| `m.Materials` | 材料管理器 |
| `m.Forces` | 力管理器 |
| `m.Constraints` | 约束管理器 |
| `m.DesignVariables` | 设计变量管理器 |
| `m.Simulations` | 仿真管理器 |
| `m.Analyses` | 分析管理器 |
| `m.Measures` | 测量管理器 |
| `m.Sections` | 截面管理器（FE） |
| `m.Geometries` | 模型级几何（弹簧阻尼） |
| `m.verify()` | 验证模型（输出 Gruebler 自由度 + 过约束检查） |
| `m.exportAdmFile()` | 导出 .adm 求解器输入文件 |
| `m.mergeInto()` | 合并模型 |

## Parts（部件）

| 方法 | 签名 | 说明 |
|------|------|------|
| `createRigidBody` | `m.Parts.createRigidBody(name, adams_id=None, location=None, orientation=None)` | 创建刚体 |
| `createFEPart` | `m.Parts.createFEPart(name, i_location, j_location, material_type)` | 创建有限元部件 |
| `m.Parts['ground']` | 索引 | 地面部件（固定） |

部件属性：
- `part.material_type = mat`（指定材料）
- `part.center_marker = marker`（质心标记）
- `part.Markers` / `part.FloatingMarkers` / `part.Geometries`

## Markers（标记）

| 方法 | 签名 |
|------|------|
| `part.Markers.create` | `create(name, adams_id=None, location=[x,y,z], orientation=[a,b,c])` |
| `part.FloatingMarkers.create` | `create(name)`（浮动标记，用于力元） |

orientation 为 3 元素欧拉角列表（Z-X-Z 约定，如 [180,90,180]）。关键：**移动副（translational）的滑动方向 = marker 的 Z 轴**；要让 Z 轴沿世界 X，用 `[90,90,0]`；默认 `[0,0,0]` 的 Z 轴竖直。marker 的 location 是相对零件质心的局部偏移（全局 = 质心 location + 局部偏移）。

## Geometries（几何）

| 方法 | 关键参数 | 说明 |
|------|----------|------|
| `createBlock` | `corner_marker=, x=, y=, z=` | 长方体 |
| `createCylinder` | `center_marker=, radius=, angle_extent=, length=, side_count_for_body=, segment_count_for_ends=` | 圆柱 |
| `createEllipsoid` | `center_marker=, x_scale_factor=, y_scale_factor=, z_scale_factor=` | 椭球 |
| `createEllipse` | `center_marker=, start_angle=, end_angle=, major_radius=, minor_radius=` | 椭圆 |
| `createArc` | `center_marker=, radius=, angle_extent=, segment_count=` | 圆弧 |
| `createFrustum` | `center_marker=, top_radius=, bottom_radius=, angle_extent=, length=, side_count_for_body=, segment_count_for_ends=` | 圆台 |
| `createLink` | `i_marker=, j_marker=, depth=, width=` | 连杆（两标记连线） |
| `createOutline` | `marker=[m1,m2,...]` | 样条轮廓（多点） |
| `m.Geometries.createSpringDamper` | `name=, i_marker_name=, j_marker_name=` | 弹簧阻尼可视化 |

几何属性示例：`g.radius = 0.25`、`g.length = 16`、`g.side_count_for_body = 20`（创建后可设属性）。

## Materials（材料）

`m.Materials.create(name, adams_id=None, youngs_modulus=, poissons_ratio=, density=)` 返回材料对象，用 `part.material_type = mat` 指定。

## Forces（力）

| 方法 | 签名 |
|------|------|
| `createGravity` | `createGravity(name=None, xyz_component_gravity=[x,y,z])` |
| `createForceVector` | `createForceVector(name, i_marker_name, j_floating_marker_name, ref_marker_name)` |
| `createTorqueVector` | `createTorqueVector(name, i_marker_name, j_floating_marker_name, ref_marker_name)` |
| `createRotationalSpringDamper` | `createRotationalSpringDamper(name, i_marker_name, j_marker_name)` |
| `createTranslationalSpringDamper` | `createTranslationalSpringDamper(name, i_marker_name, j_marker_name)` |
| `createBushing` | `createBushing(name, i_marker_name, j_marker_name)` |
| `createSingleComponentForce` | `createSingleComponentForce(name, i_marker_name, j_marker_name)` |
| `createBeam` | `createBeam(name, i_marker_name, j_marker_name)` |
| `createField` | `createField(name, i_marker_name, j_marker_name)` |

重力属性：`grav.xyz_component_gravity = [0, -9.81, 0]`。

## Constraints（约束）

| 方法 | 签名 | 说明 |
|------|------|------|
| `createRevolute` | `(name, i_marker_name, j_marker_name)` | 转动副 |
| `createTranslational` | `(name, i_marker_name, j_marker_name)` | 移动副 |
| `createCylindrical` | `(name, i_marker_name, j_marker_name)` | 圆柱副 |
| `createUniversal` | `(name, i_marker_name, j_marker_name)` | 万向节 |
| `createSpherical` | `(name, i_marker_name, j_marker_name)` | 球副 |
| `createPlanar` | `(name, i_marker_name, j_marker_name)` | 平面副 |
| `createRackpin` | `(name, i_marker_name, j_marker_name, diameter_of_pitch=)` | 齿轮齿条 |
| `createScrew` | `(name, i_marker_name, j_marker_name, pitch=)` | 螺旋副 |
| `createConvel` | `(name, i_marker_name, j_marker_name)` | 等速副 |
| `createJointMotion` | `(name, joint_name, function=)` | 关节驱动 |

marker 全路径格式：`.模型名.部件名.MARKER名`（如 `.osc.rod.MARKER_3`）。

`createJointMotion` 的 function 示例：
- `'8+2*sin(4*pi * time)'`（正弦位移驱动）
- `'(120*2*pi/60) * time'`（匀速转动驱动，120 rpm）

## DesignVariables（设计变量）

| 方法 | 签名 |
|------|------|
| `createInteger` | `(name, value)` |
| `createReal` | `(name, value)` |
| `createString` | `(name, value)` |
| `createObject` | `(name, value)` |

## Simulations（仿真）

创建：`m.Simulations.create(name=, end_time=, initial_static=, number_of_steps=, script_type=, script=)`

| 参数 | 说明 |
|------|------|
| `end_time` | 仿真时长（duration） |
| `initial_static` | 是否先做静平衡（默认 False） |
| `number_of_steps` | 步数 |
| `analysis_type` | 简单仿真类型（默认 auto_select） |
| `script_type` | 脚本类型：simple（默认）/ solver_commands / commands |
| `script` | 脚本内容（script_type=solver_commands 时为 ACF 命令列表；commands 时为内联 cmd） |

运行：`s.simulate(analysis_name=None)`，成功打印 "Simulation successful"，失败打印 "Simulation failed"。

脚本仿真示例：
```python
# ACF 脚本
s = m.Simulations.create(name='sim4', script_type='solver_commands',
    script=["simulate/transient,duration=10, dtout=0.01", "linear/statemat,file=model.mat"])
s.simulate()
# 内联 cmd
s5 = m.Simulations.create(name='sim5', script_type='commands',
    script="simulation single_run transient type=auto_select initial_static=no end_time=5.0 number_of_steps=50")
s5.simulate()
```

## Analyses（分析结果）

`a = m.Analyses[name]` 或 `a = m.Analyses.createFromFile(file_name=...)`

`a.results` 嵌套字典结构：
- `a.results['TIME']` → ResultComponent，`.values` 时间数组
- `a.results['<JOINT名>']` → OrderedDict：`TIME/FX/FY/FZ/TX/TY/TZ`（关节反力）
- `a.results['<MOTION名>']` → OrderedDict：`TIME/FX/FY/FZ/TX/TY/TZ/ANG`（驱动载荷）
- `a.results['<部件名>_XFORM']` → OrderedDict：`TIME/X/Y/Z/PSI/THETA/PHI/VX/VY/VZ/WX/WY/WZ/ACCX/ACCY/ACCZ/WDX/WDY/WDZ`（位姿/速度/加速度）。欧拉角 Z-X-Z 约定：XY 平面机构绕 Z 转角读 **PSI**（THETA/PHI 恒 0）。

每个分量是 ResultComponent，`.values` 属性返回 float 列表：
```python
t = a.results['TIME'].values
fx = a.results['JOINT_1']['FX'].values
y = a.results['link_XFORM']['Y'].values
```

分析时间属性：`a._Analysis__start_time()` / `a._Analysis__end_time()`（name-mangled 私有方法）。

## Measures（测量）

| 方法 | 说明 |
|------|------|
| `m.Measures.createPoint` | 点测量 |
| `m.Measures.createPt2pt` | 点对点距离测量 |
| `m.Measures.createAngle` | 角度测量 |
| `m.Measures.createComputed` | 计算表达式测量 |
| `m.Measures.createOrient` | 方向测量 |
| `m.Measures.createRange` | 范围测量 |
| `m.Measures.createFunction` | 函数测量 |

## Sections（FE 截面）

| 方法 | 说明 |
|------|------|
| `m.Sections.createRectangular()` | 矩形截面（`.rect_base` / `.rect_height` 属性） |
| `fep.setUniformSection(sec)` | 给 FE 部件设均匀截面 |
| `fep.addNode(x, section_label=sec)` | FE 部件加节点（x 为 0-1 归一化位置） |

## Solver（求解器，底层）

`Solver.create(Name, Parent)` 创建；`solver.evaluateExpression(text)` / `solver.simIC(ic)` / `solver.setRoutine(rout)` 等。一般通过 `m.Simulations` 高层 API 使用，不直接操作 Solver。

## execute_cmd 万能逃生舱

所有 Adamspy 未封装的 Adams 功能都可通过 `Adams.execute_cmd(cmd)` 执行。常用命令：

```python
Adams.execute_cmd('simulation single_run transient end_time=5.0 number_of_steps=50')  # 直接仿真
Adams.execute_cmd('numeric_results write file_name="results.txt"')  # 导出数值结果
Adams.execute_cmd('file model write file_name="model.cmd"')  # 导出模型
Adams.execute_cmd('list_info part part_name=.model.part')  # 列出部件信息
```

表达式求值：`Adams.evaluate_exp('DX(.model.part.MARKER)') ` / `Adams.evaluate_real_exp('DX(...)')`。
