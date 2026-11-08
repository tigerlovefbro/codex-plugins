# 批处理运行详解

## 为什么必须用 View 批处理模式

Adamspy（`import Adams`）的导入链是：

```
Adams.pyc:  from Libraries import amdlib
            import aview_main
aview_main.pyc: import __aview_main
```

`__aview_main` 不是磁盘上的 .pyd 文件，而是由 `aview.dll`（View 内核）在**运行时注册**的桥接模块，提供 `execute_cmd(cmd)` / `evaluate_exp(exp)` 两个函数（执行 Adams Command Language）。

`Libraries.pyc` 通过 ctypes 加载 4 个 DLL：`amd.dll`、`AsolCombined.dll`、`aview.dll`、`plotting.dll`，并调用 `amdlib.ac_initialize('ADAMS_Windows')`。但 ctypes 只加载 DLL，**不初始化 View 内核**，所以 `__aview_main` 未注册。

结论：`import Adams` 必须在 View 进程内执行。直接 `python script.py` 会报 `ModuleNotFoundError: No module named '__aview_main'`；`mdi.bat python script.py` 同样失败（只是设 PYTHON_EXE 后直接跑，无特殊处理）。

## 正确的批处理运行方式

`mdi.bat aview ru-st b <batch.cmd>` 启动 View 批处理模式（无 GUI），`batch.cmd` 里用 `file python read file="..."` 执行 Python 脚本。

### 三个文件

**1. Python 脚本**（`script.py`）—— 你的建模/仿真逻辑：
```python
import Adams
m = Adams.Models.create(name='test')
print('OK', m.name)
```

**2. View 命令文件**（`batch.cmd`）—— **不要加 exit**：
```
file python read file="C:\full\path\to\script.py"
```

`exit` 会触发 "Enter confirmation (required)" 并报"无效的输入"错误。View 在命令文件用完后自动"完成批运行"退出，无需显式 exit。

**3. wrapper.bat**（从 Git Bash 调用）：
```bat
@echo off
cd /d "C:\Program Files\MSC.Software\Adams\2020_711253\common"
call mdi.bat aview ru-st b "C:\full\path\to\batch.cmd"
```

### 调用（Git Bash）

```bash
cmd //c 'C:/full/path/to/wrapper.bat'
```

关键：wrapper.bat 路径用**正斜杠**（`cmd //c` 会把反斜杠吃掉，`C:\Users` 变成 `C:Users` 报 "Cannot find command file"）；wrapper.bat 内部的 batch.cmd 路径保持**反斜杠字面**。

## 输出与日志

- Python 的 `print` 输出 → `<ADAMS_HOME>/common/aview.log`（每次批处理运行前被覆盖）
- 批处理命令回显也在 aview.log（`! >> ` 前缀）
- 每次运行 batch.cmd 会被复制到 `common/aview.cmd`

读取日志：
```bash
cat "C:/Program Files/MSC.Software/Adams/2020_711253/common/aview.log"
```

## 环境变量（mdi.bat 自动设置）

mdi.bat 主流程：`setTopdir` → `setupPython`（设 PYTHONHOME/PYTHONPATH/PYTHON_EXE）→ `setEnvironment` → `setLicense` → `setPath` → `runProducts`。

- PYTHONHOME/PYTHONPATH 指向捆绑 Python 3.6（`python/win64/`）
- PYTHONPATH 含 `site-packages\mdi`（adamspy 所在）、`site-packages\win64`、`site-packages\msc\ADAMS\Vibration`
- PATH 追加 `win64`、`gfx\win64\lib`、`ct\win64\lib` 等（aview.dll 的 Qt4/gfx 依赖）

## 启动入口

- `mdi.bat aview ru-st i` —— View GUI 交互模式
- `mdi.bat aview ru-st b <cmd>` —— View 批处理模式（本技能用）
- `mdi.bat acar/acsi/adrive ...` —— 其他产品（Car/Chassis/Driveline）

## 调试技巧

1. **最小验证**：先跑只含 `import Adams; print('OK')` 的脚本确认导入链通。
2. **逐段 print**：在建模/仿真/结果各段加 `print('STEP_X_OK')` 定位失败点。
3. **看 aview.log**：`m.verify()` 的输出（Gruebler 数、过约束）和仿真状态都在日志里。
4. **仿真失败**：先 `m.verify()` 查过约束/自由度，再查 solver license。

## 已实测通过的完整链路

在 Adams 2020（2020_711253）上验证：

```
建模（oscillating slider：ground + rod + slider + 2 joint + 2 motion）
→ m.verify()（0 自由度，模型验证正确）
→ Adams.write_binary_file()（.bin 9.9MB）
→ Adams.read_binary_file() + getCurrentModel()
→ Simulations.create(end_time=1.0, number_of_steps=100) + simulate('sim1')
→ "Simulation successful"
→ Analyses['sim1'].results 含 TIME / MOTION_8 / MOTION_7 / JOINT_2 / JOINT_1 / rod_XFORM / slider_XFORM
→ 各分量 .values 返回 float 数组
```

## 版本适配

- 本技能基于 Adams 2020（30.0.0）自带 adamspy 验证。
- 安装路径默认 `C:/Program Files/MSC.Software/Adams/<版本>/`，版本目录名如 `2020_711253`，用 `mdi.bat` 的实际位置为准。
- 不同 Adams 版本 adamspy API 可能略有差异（对象创建签名），以本机 `<ADAMS_HOME>/adamspy/examples/` 下官方示例为准。
