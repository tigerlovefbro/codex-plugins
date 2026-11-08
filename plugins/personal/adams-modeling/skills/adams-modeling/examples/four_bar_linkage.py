"""四杆机构（Four-Bar Linkage，曲柄摇杆）—— Adamspy 示例。

机构：ground(机架0.6) + crank(曲柄0.25) + coupler(连杆0.5315) + rocker(摇杆0.4)
Grashof 曲柄摇杆：最短杆(曲柄0.25)+最长杆(连杆0.5315)=0.7815 <= 0.6+0.4=1.0，曲柄可整转。
4 个转动副（旋转轴沿世界 Z，机构在 XY 平面运动）+ 曲柄匀速驱动。

运行方式同 oscillating_slider.py（View 批处理模式）。
"""
import Adams

m = Adams.Models.create(name='fourbar')
d = Adams.defaults
d.units.length = 'meter'
d.units.mass = 'kg'
d.units.time = 'second'
d.units.angle = 'degrees'

mat = m.Materials.create(name='steel', youngs_modulus=2.07E11, poissons_ratio=0.29, density=7801.0)

# ---------- 机架 ground：G1(0,0) G2(0.6,0) ----------
ground = m.Parts['ground']
d.coordinate_system = ground
g1 = ground.Markers.create(name='G1', location=[0, 0, 0], orientation=[0, 0, 0])
g2 = ground.Markers.create(name='G2', location=[0.6, 0, 0], orientation=[0, 0, 0])

# ---------- 曲柄 crank（长0.25，O→B 水平向右，质心在 0.125）----------
crank = m.Parts.createRigidBody(name='crank', location=[0.125, 0, 0])
crank.material_type = mat
d.coordinate_system = crank
c1 = crank.Markers.create(name='C1', location=[-0.125, 0, 0], orientation=[0, 0, 0])  # 连地面 O
c2 = crank.Markers.create(name='C2', location=[0.125, 0, 0], orientation=[0, 0, 0])   # 连连杆 B
crank.center_marker = crank.Markers.create(name='cm', location=[0, 0, 0])

# ---------- 连杆 coupler（B(0.25,0)→C(0.6,0.4)，质心 0.425,0.2）----------
coupler = m.Parts.createRigidBody(name='coupler', location=[0.425, 0.2, 0])
coupler.material_type = mat
d.coordinate_system = coupler
n1 = coupler.Markers.create(name='N1', location=[-0.175, -0.2, 0], orientation=[0, 0, 0])  # 连曲柄 B
n2 = coupler.Markers.create(name='N2', location=[0.175, 0.2, 0], orientation=[0, 0, 0])   # 连摇杆 C
coupler.center_marker = coupler.Markers.create(name='cm', location=[0, 0, 0])

# ---------- 摇杆 rocker（A(0.6,0)→C(0.6,0.4)，质心 0.6,0.2）----------
rocker = m.Parts.createRigidBody(name='rocker', location=[0.6, 0.2, 0])
rocker.material_type = mat
d.coordinate_system = rocker
r1 = rocker.Markers.create(name='R1', location=[0, -0.2, 0], orientation=[0, 0, 0])  # 连机架 G2
r2 = rocker.Markers.create(name='R2', location=[0, 0.2, 0], orientation=[0, 0, 0])   # 连连杆 C
rocker.center_marker = rocker.Markers.create(name='cm', location=[0, 0, 0])

# ---------- 四个转动副 ----------
m.Constraints.createRevolute(name='J_CRANK_GROUND',
    i_marker_name='.fourbar.crank.C1', j_marker_name='.fourbar.ground.G1')
m.Constraints.createRevolute(name='J_CRANK_COUPLER',
    i_marker_name='.fourbar.crank.C2', j_marker_name='.fourbar.coupler.N1')
m.Constraints.createRevolute(name='J_COUPLER_ROCKER',
    i_marker_name='.fourbar.coupler.N2', j_marker_name='.fourbar.rocker.R2')
m.Constraints.createRevolute(name='J_ROCKER_GROUND',
    i_marker_name='.fourbar.rocker.R1', j_marker_name='.fourbar.ground.G2')

# ---------- 曲柄匀速驱动（60 rpm = 360 deg/s）----------
mot = m.Constraints.createJointMotion(name='MOTION_CRANK', joint_name='.fourbar.J_CRANK_GROUND')
mot.function = '(60*360/60) * time'

# ---------- 验证 + 保存 ----------
m.verify()
Adams.write_binary_file(r'C:\temp\fourbar.bin')

# ---------- 仿真 2 秒 200 步 ----------
s = m.Simulations.create(name='sim1', end_time=2.0, number_of_steps=200)
s.simulate('sim1')

# ---------- 读结果：摇杆摆角（PSI，绕 Z 的欧拉角） ----------
a = m.Analyses['sim1']
t = a.results['TIME'].values
rocker_psi = a.results['rocker_XFORM']['PSI'].values
print('FOURBAR_OK steps=%d rocker_PSI[0]=%.4f rocker_PSI[-1]=%.4f' % (len(t), rocker_psi[0], rocker_psi[-1]))