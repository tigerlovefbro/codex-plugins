"""活塞曲柄机构（Piston-Crank）—— Adamspy 示例。

机构：ground(机架+导轨) + crank(曲柄0.2) + conrod(连杆0.5) + piston(沿 X 往复)
曲柄匀速转动，活塞沿 X 轴滑动（移动副 Z 轴沿世界 X，orientation=[90,90,0]）。

运行方式同 oscillating_slider.py（View 批处理模式）。
"""
import Adams

m = Adams.Models.create(name='piston_crank')
d = Adams.defaults
d.units.length = 'meter'
d.units.mass = 'kg'
d.units.time = 'second'
d.units.angle = 'degrees'

mat = m.Materials.create(name='steel', youngs_modulus=2.07E11, poissons_ratio=0.29, density=7801.0)

# ---------- 机架：G_CRANK(0,0) 铰点 + G_GUIDE(0.7,0) 导轨 ----------
ground = m.Parts['ground']
d.coordinate_system = ground
g_crank = ground.Markers.create(name='G_CRANK', location=[0, 0, 0], orientation=[0, 0, 0])
g_guide = ground.Markers.create(name='G_GUIDE', location=[0.7, 0, 0], orientation=[90, 90, 0])  # Z 轴沿 X

# ---------- 曲柄 crank（长0.2，O→B 水平，质心 0.1）----------
crank = m.Parts.createRigidBody(name='crank', location=[0.1, 0, 0])
crank.material_type = mat
d.coordinate_system = crank
c1 = crank.Markers.create(name='C1', location=[-0.1, 0, 0], orientation=[0, 0, 0])  # 连地面 O
c2 = crank.Markers.create(name='C2', location=[0.1, 0, 0], orientation=[0, 0, 0])   # 连连杆 B
crank.center_marker = crank.Markers.create(name='cm', location=[0, 0, 0])

# ---------- 连杆 conrod（长0.5，B(0.2,0)→C(0.7,0)，质心 0.45）----------
conrod = m.Parts.createRigidBody(name='conrod', location=[0.45, 0, 0])
conrod.material_type = mat
d.coordinate_system = conrod
n1 = conrod.Markers.create(name='N1', location=[-0.25, 0, 0], orientation=[0, 0, 0])  # 连曲柄 B
n2 = conrod.Markers.create(name='N2', location=[0.25, 0, 0], orientation=[0, 0, 0])   # 连活塞 C
conrod.center_marker = conrod.Markers.create(name='cm', location=[0, 0, 0])

# ---------- 活塞 piston（沿 X 滑动，质心 0.7）----------
piston = m.Parts.createRigidBody(name='piston', location=[0.7, 0, 0])
piston.material_type = mat
d.coordinate_system = piston
p1 = piston.Markers.create(name='P1', location=[0, 0, 0], orientation=[0, 0, 0])      # 连连杆 C
p2 = piston.Markers.create(name='P2', location=[0, 0, 0], orientation=[90, 90, 0])     # 连导轨（Z 沿 X）
piston.center_marker = piston.Markers.create(name='cm', location=[0, 0, 0])

# ---------- 约束：3 转动副 + 1 移动副 ----------
m.Constraints.createRevolute(name='J_CRANK_GROUND',
    i_marker_name='.piston_crank.crank.C1', j_marker_name='.piston_crank.ground.G_CRANK')
m.Constraints.createRevolute(name='J_CRANK_CONROD',
    i_marker_name='.piston_crank.crank.C2', j_marker_name='.piston_crank.conrod.N1')
m.Constraints.createRevolute(name='J_CONROD_PISTON',
    i_marker_name='.piston_crank.conrod.N2', j_marker_name='.piston_crank.piston.P1')
m.Constraints.createTranslational(name='J_PISTON_GROUND',
    i_marker_name='.piston_crank.piston.P2', j_marker_name='.piston_crank.ground.G_GUIDE')

# ---------- 曲柄匀速驱动（120 rpm = 720 deg/s）----------
mot = m.Constraints.createJointMotion(name='MOTION_CRANK', joint_name='.piston_crank.J_CRANK_GROUND')
mot.function = '(120*360/60) * time'

# ---------- 验证 + 保存 ----------
m.verify()
Adams.write_binary_file(r'C:\temp\piston_crank.bin')

# ---------- 仿真 1 秒 100 步 ----------
s = m.Simulations.create(name='sim1', end_time=1.0, number_of_steps=100)
s.simulate('sim1')

# ---------- 读结果：活塞位移 X ----------
a = m.Analyses['sim1']
t = a.results['TIME'].values
piston_x = a.results['piston_XFORM']['X'].values
print('PISTON_OK steps=%d piston_X[0]=%.4f piston_X[-1]=%.4f' % (len(t), piston_x[0], piston_x[-1]))
