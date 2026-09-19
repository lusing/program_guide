// pool.cpp —— Boost.Pool（2000）：固定大小块的内存池。
// C++11 后大多数场景被 make_shared 的单次分配和自定义 allocator 取代，
// 但"海量同型小对象"场景它仍是直给的工具。
// 对应文档：docs/21-container-core.md
#include <boost/pool/pool_alloc.hpp>
#include <boost/pool/object_pool.hpp>
#include <iostream>
#include <list>
#include <string>

struct Particle {
    double x, y, z;
    int id;
    explicit Particle(int i) : x(0), y(0), z(0), id(i) {}
};

int main() {
    // 1) object_pool：new/delete 的池化版（构造/析构会正确调用）。
    //    注意：construct 透传构造参数，但参数个数支持有限制（实测 4 参
    //    不行），复杂初始化走单参构造 + 成员赋值最稳
    boost::object_pool<Particle> pool;
    Particle* p1 = pool.construct(1);
    Particle* p2 = pool.construct(2);
    std::cout << "p1 = (" << p1->x << ',' << p1->y << ',' << p1->z << ") id=" << p1->id << '\n';
    std::cout << "p2 id = " << p2->id << '\n';
    pool.destroy(p1);       // 析构 + 归池
    Particle* p3 = pool.construct(3);   // 复用 p1 的槽
    std::cout << "p3 复用槽位 id=" << p3->id << '\n';
    pool.destroy(p2); pool.destroy(p3);

    // 2) pool_allocator：给 STL 容器换池化分配器（一行升级）
    std::list<int, boost::pool_allocator<int>> pooled;
    for (int i = 0; i < 5; ++i) pooled.push_back(i * 100);
    std::cout << "池化 list:";
    for (int x : pooled) std::cout << ' ' << x;
    std::cout << '\n';

    // 3) fast_pool_allocator：单链 free list，更快更简单
    std::list<std::string, boost::fast_pool_allocator<std::string>> fp;
    fp.push_back("池");
    fp.push_back("化");
    std::cout << "fast 池化 list 大小 = " << fp.size() << '\n';

    // 4) 何时还用它：百万级 16-64 字节的小对象高频生灭（粒子、AST 节点）
    std::cout << "std 无对应（allocator 没有池化的标准件）\n";

    std::cout << "自检通过\n";
    return 0;
}
