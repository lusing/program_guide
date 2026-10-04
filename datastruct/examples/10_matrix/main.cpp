#include <cassert>
#include <cstddef>
#include <print>
#include <vector>

#include "compressed_matrix.hpp"
#include "cross_list.hpp"
#include "general_list.hpp"
#include "sparse_matrix.hpp"

// 10 多维数组与稀疏矩阵：压缩存储、三元组、十字链表、广义表

int main() {
    // ═══ 对称矩阵：3×3 只需 6 个位置；at(r,c) 与 at(c,r) 同槽 ═══
    ds::SymmetricMatrix sm(3);
    assert(sm.stored() == 6);
    sm.at(0, 1) = 5.0;
    assert(sm.at(1, 0) == 5.0);
    sm.at(2, 0) = 7.0;
    assert(sm.at(0, 2) == 7.0);
    sm.at(2, 2) = 9.0;
    // 六个下三角槽彼此独立，总和 5+7+9（上三角写入只落在下三角槽里）
    double total = 0.0;
    for (int r = 0; r < 3; ++r) {
        for (int c = 0; c <= r; ++c) {
            total += sm.at(r, c);
        }
    }
    assert(total == 21.0);
    bool sm_threw = false;
    try {
        (void)sm.at(3, 0);
    } catch (const std::out_of_range&) {
        sm_threw = true;
    }
    assert(sm_threw);
    std::println("对称矩阵 3×3：压缩为 {} 个位置，at(0,1) 写入则 at(1,0) 读出（同槽）",
                 sm.stored());

    // ═══ 稀疏矩阵 COO：三元组恒按 (r,c) 升序 ═══
    const ds::SparseMatrix a(3, 3, {
        {0, 1, 2}, {1, 0, 3}, {2, 2, 4},
    });
    assert(a.triples().size() == 3);
    assert(a.triples()[0].r == 0 && a.triples()[0].c == 1);
    assert(a.triples()[1].r == 1 && a.triples()[1].c == 0);
    assert(a.triples()[2].r == 2 && a.triples()[2].c == 2);

    // ═══ 转置：行列互换、值随位置走，仍保持 (r,c) 有序 ═══
    const ds::SparseMatrix at = a.transpose();
    assert(at.rows() == 3 && at.cols() == 3);
    assert(at.triples()[0].r == 0 && at.triples()[0].c == 1
           && at.triples()[0].v == 3.0);
    assert(at.triples()[1].r == 1 && at.triples()[1].c == 0
           && at.triples()[1].v == 2.0);
    assert(at.triples()[2].r == 2 && at.triples()[2].c == 2
           && at.triples()[2].v == 4.0);
    std::println("稀疏矩阵转置：行列互换，三元组仍按 (行,列) 升序");

    // ═══ 相加：双路归并，同位置求和，抵消的零项消失 ═══
    const ds::SparseMatrix b(3, 3, {
        {0, 1, -2}, {1, 0, -3}, {2, 2, 5},
    });
    const ds::SparseMatrix c = a + b;
    assert(c.triples().size() == 1);
    assert(c.triples()[0].r == 2 && c.triples()[0].c == 2
           && c.triples()[0].v == 9.0);
    bool shape_threw = false;
    try {
        const ds::SparseMatrix d(2, 3, {});
        const ds::SparseMatrix e = a + d;
        (void)e;
    } catch (const std::invalid_argument&) {
        shape_threw = true;
    }
    assert(shape_threw);
    std::println("矩阵相加：抵消后仅余 {} 个非零项（值为 {}）",
                 c.triples().size(), c.triples()[0].v);

    // ═══ 十字链表：节点同时在行、列两条有序链上 ═══
    ds::CrossList cl(3, 3);
    cl.set(0, 1, 2);
    cl.set(1, 0, 3);
    cl.set(2, 2, 4);
    assert(cl.node_count() == 3);
    assert(cl.get(0, 1) == 2.0);
    assert(cl.get(1, 0) == 3.0);
    assert(cl.get(2, 2) == 4.0);
    assert(cl.get(0, 0) == 0.0);
    std::vector<ds::Triple> r0 = cl.row(0);
    assert(r0.size() == 1 && r0[0].c == 1 && r0[0].v == 2.0);
    // 更新已存在位置不增加节点
    cl.set(0, 1, 20);
    assert(cl.node_count() == 3);
    assert(cl.get(0, 1) == 20.0);
    // 同行再插首尾两格，行链须保持列序，列链也各就各位
    cl.set(0, 0, 11);
    cl.set(0, 2, 22);
    r0 = cl.row(0);
    assert(r0.size() == 3);
    assert(r0[0].c == 0 && r0[1].c == 1 && r0[2].c == 2);
    assert(cl.node_count() == 5);
    assert(cl.get(0, 0) == 11.0 && cl.get(0, 2) == 22.0);
    bool cl_threw = false;
    try {
        cl.set(3, 0, 1);
    } catch (const std::out_of_range&) {
        cl_threw = true;
    }
    assert(cl_threw);
    std::println("十字链表：{} 个非零节点，set/get 往返一致，行内按列有序",
                 cl.node_count());

    // ═══ 广义表：嵌套结构的长度、深度与展开 ═══
    const ds::GeneralList g = ds::GeneralList::parse("(a,(b,(c)),d)");
    assert(g.length() == 3);
    assert(g.depth() == 3);
    const std::vector<double> flat = g.flatten();
    const std::vector<double> expect{'a', 'b', 'c', 'd'};
    assert(flat == expect);
    const ds::GeneralList g0 = ds::GeneralList::parse("()");
    assert(g0.length() == 0);
    assert(g0.depth() == 1);
    std::println("广义表 (a,(b,(c)),d)：长度 {}、深度 {}，展开为 {} {} {} {}",
                 g.length(), g.depth(),
                 static_cast<char>(flat[0]), static_cast<char>(flat[1]),
                 static_cast<char>(flat[2]), static_cast<char>(flat[3]));

    std::println("自检通过");
}
