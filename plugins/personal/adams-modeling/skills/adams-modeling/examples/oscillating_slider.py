"""曲柄滑块机构（Oscillating Slider）—— Adamspy 完整示例。

演示完整链路：建模 → 验证 → 保存 → 仿真 → 结果读取。
来源：MSC Adams 官方教程 Oscillating_slider_completed.py（已实测通过，Adams 2020）。

运行方式（View 批处理模式）：
  1. batch.cmd 内容: file python read file="<本脚本绝对路径>"
  2. wrapper.bat: cd /d <ADAMS_HOME>/common 然后 call mdi.bat aview ru-st b "<batch.cmd>"
  3. 结果看 <ADAMS_HOME>/common/aview.log
"""
import Adams

# ---------- 建模型 + 单位 ----------
m = Adams.Models.create(name='oscillator_py')
d = Adams.defaults
d.units.length = 'inch'
d.units.mass = 'pound_mass'
d.units.time = 'second'
d.units.angle = 'degrees'
d.units.force = 'pound_force'

# ---------- 重力 + 材料 ----------
grav = m.Forces.createGravity()
grav.xyz_component_gravity = [0, -386.0, 0]
mat = m.Materials.create(name='steel', adams_id=1,
                         youngs_modulus=3.002281171E+07,
                         poissons_ratio=0.29, density=0.2818290049)

# ---------- 地面 ----------
ground = m.Parts['ground']
d.coordinate_system = ground
mar1 = ground.Markers.create(name='MARKER_1', adams_id=1, location=[0, 0, 0], orientation=[180, 90, 180])

# ---------- 杆（rod）----------
p2 = m.Parts.createRigidBody(name='rod', adams_id=2, location=[0, 0, 0], orientation=[330, 0, 0])
p2.material_type = mat
d.coordinate_system = p2
mar21 = p2.Markers.create(name='MARKER_1', adams_id=2, location=[0, 0, 0], orientation=[180, 90, 180])
mar23 = p2.Markers.create(name='MARKER_3', adams_id=5, location=[0, 0, 0], orientation=[210, 90, 180])
mar22 = p2.Markers.create(name='MARKER_2', adams_id=6, location=[0, 0, 0], orientation=[180, 90, 180])
p2.center_marker = p2.Markers.create(name='cm', location=[0, 8, 0], orientation=[0, 90.0, 0])
g1 = p2.Geometries.createCylinder(name='CYLINDER_1', center_marker=mar21, adams_id=1)
g1.radius = 0.25
g1.angle_extent = 360
g1.length = 16
g1.side_count_for_body = 20
g1.segment_count_for_ends = 20

# ---------- 滑块（slider）----------
d.coordinate_system = ground
p3 = m.Parts.createRigidBody(name='slider', adams_id=3, location=[4, 6.9282032303, 0], orientation=[0, 0, 0])
p3.material_type = mat
d.coordinate_system = p3
mar31 = p3.Markers.create(name='MARKER_1', adams_id=7, location=[0, 0, 0], orientation=[0, 0, 0])
mar32 = p3.Markers.create(name='MARKER_2', adams_id=9, location=[0, 0, 0], orientation=[150, 90, 180])
g31 = p3.Geometries.createEllipsoid(name='SPHERE_1', center_marker=mar31)
g31.x_scale_factor = 2
g31.y_scale_factor = 2
g31.z_scale_factor = 2

# ---------- 约束 ----------
m.Constraints.createRevolute(name='JOINT_2',
    i_marker_name='.oscillator_py.rod.MARKER_3',
    j_marker_name='.oscillator_py.ground.MARKER_1', adams_id=4)
m.Constraints.createTranslational(name='JOINT_1',
    i_marker_name='.oscillator_py.slider.MARKER_2',
    j_marker_name='.oscillator_py.rod.MARKER_2', adams_id=5)

# ---------- 驱动 ----------
mo1 = m.Constraints.createJointMotion(name='MOTION_8', joint_name='.oscillator_py.JOINT_1', adams_id=8)
mo1.function = '8+2*sin(4*pi * time)'
mo2 = m.Constraints.createJointMotion(name='MOTION_7', joint_name='.oscillator_py.JOINT_2', adams_id=7)
mo2.function = '(120*2*pi/60) * time'

# ---------- 验证 + 保存 ----------
m.verify()
Adams.write_binary_file(r'C:\temp\oscillator_py.bin')

# ---------- 仿真 ----------
s = m.Simulations.create(name='sim1', end_time=1.0, number_of_steps=100)
s.simulate('sim1')

# ---------- 读结果 ----------
a = m.Analyses['sim1']
t = a.results['TIME'].values
rod_y = a.results['rod_XFORM']['Y'].values
print('SIM_OK steps=%d rod_Y[0]=%.4f rod_Y[-1]=%.4f' % (len(t), rod_y[0], rod_y[-1]))
