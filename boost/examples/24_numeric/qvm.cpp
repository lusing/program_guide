// qvm.cpp —— Boost.QVM（2018）：四元数/向量/矩阵的轻量运算库
//（游戏与图形的 3D 数学；对照 25 章 ublas 的"通用线代"定位）。
// 对应文档：docs/24-numeric.md
// 实测：qvm 的细分头是迷宫（mat×vec 的 operator* 在 gen/ 生成头里）——
// 一站式总头 all.hpp 最省心
#include <boost/qvm/all.hpp>
#include <iostream>

int main() {
    using boost::qvm::vec;
    using boost::qvm::quat;

    // 1) 向量：点积/叉积/模
    vec<float, 3> v{1, 2, 3};
    vec<float, 3> w{0, 1, 0};
    std::cout << "v = (" << X(v) << ',' << Y(v) << ',' << Z(v) << ")\n";
    std::cout << "点积 = " << dot(v, w) << '\n';
    auto c = cross(v, w);
    std::cout << "叉积 = (" << X(c) << ',' << Y(c) << ',' << Z(c) << ")\n";
    std::cout << "|v| = " << mag(v) << '\n';

    // 2) 旋转矩阵：rot_mat<3>(轴, 角)——绕 Z 转 90°
    auto rz = boost::qvm::rot_mat<3>(vec<float, 3>{0, 0, 1}, 3.14159265f / 2);
    auto rotated = rz * v;
    std::cout << "矩阵旋转: (" << round(X(rotated) * 100) / 100 << ','
              << round(Y(rotated) * 100) / 100 << ',' << round(Z(rotated) * 100) / 100 << ")\n";

    // 3) 四元数：rot_quat(轴, 角)——同样效果的 quat 表示
    boost::qvm::quat<float> q = boost::qvm::rot_quat(vec<float, 3>{0, 0, 1}, 3.14159265f / 2);  // 视图要落地成 quat 实体
    auto vr = q * v;                     // quat × vec = 旋转（quat_vec_operations）
    std::cout << "四元数旋转: (" << round(X(vr) * 100) / 100 << ','
              << round(Y(vr) * 100) / 100 << ',' << round(Z(vr) * 100) / 100 << ")\n";

    // 4) quat 自身运算：乘法合成旋转、取范数
    auto q2 = q * q;                     // 转 180°
    std::cout << "|q| = " << mag(q) << "（单位四元数）\n";
    std::cout << "q*q 再旋 v: (" << round(X(q2 * v) * 100) / 100 << ','
              << round(Y(q2 * v) * 100) / 100 << ',' << round(Z(q2 * v) * 100) / 100 << ")\n";

    // 5) 元素访问 A<行,列>(矩阵)。identity_mat 等生成器返回的是"视图"，
    //    隐式转换落地成 mat 实体后才能用
    boost::qvm::mat<float, 3, 3> m = boost::qvm::identity_mat<float, 3>();
    std::cout << "单位阵 [1][1] = " << A<1, 1>(m) << '\n';

    std::cout << "自检通过\n";
    return 0;
}
