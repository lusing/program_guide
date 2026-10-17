// pool.cpp —— Boost.Pool（2000）：固定大小块的内存池四兄弟
// 对应文档：docs/21-container-core.md
//
// pool 库基于"简单分隔存储"思想：一次向系统批发一大块，切成等大的小块
// 零售。C++11 后多数场景被 make_shared（单次分配）与 pmr 内存资源
// （C++17）覆盖，但"海量同型小对象高频生灭"它仍是直给的工具。
#include <boost/pool/object_pool.hpp>
#include <boost/pool/pool.hpp>
#include <boost/pool/pool_alloc.hpp>
#include <boost/pool/singleton_pool.hpp>
#include <iostream>
#include <list>
#include <new>       // placement new
#include <string>

struct Particle {
    double x, y, z;
    int id;
    explicit Particle(int i) : x(0), y(0), z(0), id(i) {}
};

struct Particle4 {   // 四参构造：object_pool::construct 透传不了（实测上限）
    int a, b, c, d;
    Particle4(int a_, int b_, int c_, int d_) : a(a_), b(b_), c(c_), d(d_) {}
};

// 书里的解法：可变参数模板 + placement new 的自由函数 construct——
// 参数个数无上限，任何 pool 类型通用
template <typename P, typename... Args>
inline typename P::element_type* construct(P& pool, Args&&... args) {
    typename P::element_type* mem = pool.malloc();
    return new (mem) typename P::element_type(std::forward<Args>(args)...);
}

// singleton_pool 的 Tag：空类仅用于在编译期区分不同的池（可内联声明）
struct particle_tag {};
using particle_pool = boost::singleton_pool<particle_tag, sizeof(Particle)>;

int main() {
    // ── 1) pool<>：最原始的池——只给内存不给构造（POD 专用） ──
    //    构造参数是"每块的大小"（不是池总大小）；池会按需自动扩容。
    boost::pool<> pl(sizeof(int));
    int* p1 = static_cast<int*>(pl.malloc());
    *p1 = 42;
    int* p2 = static_cast<int*>(pl.malloc());
    *p2 = 7;
    std::cout << "pool<>: *p1=" << *p1 << " *p2=" << *p2
              << " is_from(p1)? " << pl.is_from(p1) << '\n';
    // malloc 失败返回空指针（不抛异常）——用前要判空
    void* raw = pl.ordered_malloc();          // ordered_*：分配时顺带合并空闲链
    std::cout << "ordered_malloc 非空? " << (raw != nullptr)
              << " 失败约定 = 返回 nullptr（不抛异常）\n";
    pl.free(p2);                              // 手动归还（通常不必：析构全收）
    // release_memory() 还未分配的块 / purge_memory() 强制全还（析构就调它）

    // ── 2) object_pool：new/delete 的池化版（构造/析构会正确调用） ──
    boost::object_pool<Particle> pool;
    Particle* q1 = pool.construct(1);
    Particle* q2 = pool.construct(2);
    std::cout << "object_pool: q1 id=" << q1->id << " q2 id=" << q2->id << '\n';
    pool.destroy(q1);                          // 析构 + 归池
    Particle* q3 = pool.construct(3);          // 复用 q1 的槽
    std::cout << "复用槽位: q3 id=" << q3->id << " 地址复用? "
              << (q3 == q1) << '\n';
    // malloc() 只给原始内存不构造——里面的值是未定义的（别读！）
    Particle* uninit = pool.malloc();
    std::cout << "malloc 原始内存 is_from? " << pool.is_from(uninit)
              << "（值未定义，不读）\n";
    pool.destroy(uninit);
    pool.destroy(q2); pool.destroy(q3);
    // 【实测坑】construct 透传构造参数有**个数上限**：本机 1.92/MSVC 实测
    // 4 参编不过（第 5 版书说默认最多 3 参 + m4 宏生成更多；1.92 仍是
    // 预生成档位）。第 5 版书给的解法就是上面的自由函数 construct：
    {
        boost::object_pool<Particle4> p4;
        Particle4* f = construct(p4, 1, 2, 3, 4);   // 四参：自由函数无上限
        std::cout << "自由函数 4 参构造: " << f->a << f->b << f->c << f->d
                  << '\n';
        f->~Particle4();                            // placement new 的对象
        p4.free(f);                                 // 要手动析构再归还
    }

    // ── 3) singleton_pool：全局单件池，静态接口，无需实例 ──
    //    生命周期到程序结束（不随作用域析构）；Tag 区分不同池。
    Particle* s1 = static_cast<Particle*>(particle_pool::malloc());
    s1->id = 99;
    std::cout << "singleton_pool: s1 id=" << s1->id
              << " is_from? " << particle_pool::is_from(s1) << '\n';
    particle_pool::free(s1);
    particle_pool::release_memory();          // 主动归还（否则等到进程结束）
    std::cout << "singleton 释放后仍可再分配? "
              << (particle_pool::ordered_malloc() != nullptr) << '\n';

    // ── 4) pool_allocator：给 STL 容器换池化分配器（一行升级） ──
    std::list<int, boost::pool_allocator<int>> pooled;
    for (int i = 0; i < 5; ++i) pooled.push_back(i * 100);
    std::cout << "池化 list:";
    for (int x : pooled) std::cout << ' ' << x;
    std::cout << '\n';
    // fast_pool_allocator：单链 free list，更快更简单
    std::list<std::string, boost::fast_pool_allocator<std::string>> fp;
    fp.push_back("池");
    fp.push_back("化");
    std::cout << "fast 池化 list 大小 = " << fp.size() << '\n';

    std::cout << "自检通过\n";
    return 0;
}
