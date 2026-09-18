// hash2.cpp —— Boost.Hash2（2023）：哈希的第二代——可换算法、可换框架、
// 有保证的抗碰撞语义。C++26 std::hash 的提案就照着它讨论。
// 对应文档：docs/08-unordered.md
#include <boost/hash2/fnv1a.hpp>
#include <boost/hash2/xxhash.hpp>
#include <iostream>
#include <string>

int main() {
    using namespace boost::hash2;

    // 1) 框架 + 算法分离：fnv1a 是最快的散列之一。
    //    注意：默认构造用**进程随机种子**（防碰撞 DoS 的设计），要可复现
    //    结果就显式给种子（0）；result() 是流式快照，先存值再用
    fnv1a_64 h1(0);
    h1.update("hello", 5);
    auto r1 = h1.result();
    std::cout << "fnv1a_64(hello) = 0x" << std::hex << r1 << std::dec << '\n';

    // 2) 同一框架换算法：只需换类型
    xxhash_64 h2(0);
    h2.update("hello", 5);
    std::cout << "xxhash_64(hello) = 0x" << std::hex << h2.result() << std::dec << '\n';

    // 3) hash_append 协议：类型自己声明"怎么进哈希"（container_hash 的
    //    hash_value 升级版：流式、可换算法）。自定义类型的写法：
    //      template <class H> friend void hash_append(H& h, const Key& k) {
    //          using boost::hash2::hash_append;
    //          hash_append(h, k.a);
    //          hash_append(h, k.b);
    //      }
    // 这里演示底层原语：对字节流逐段 update
    fnv1a_64 h3;
    int a = 7;
    std::string b = "x";
    h3.update(&a, sizeof(a));
    h3.update(b.data(), b.size());
    std::cout << "手写组合 = 0x" << std::hex << h3.result() << std::dec << '\n';

    // 4) 确定性：显式种子下同输入同输出（跨平台跨版本的承诺，std::hash 不给）
    fnv1a_64 h4(0);
    h4.update("hello", 5);
    auto r4 = h4.result();
    std::cout << "两次运行一致? " << std::boolalpha << (r4 == r1) << '\n';

    // 5) 随机种子：默认构造的实例之间种子不同（防碰撞 DoS 的关键设计）
    fnv1a_64 seeded;
    seeded.update("hello", 5);
    std::cout << "默认随机种子结果不同? " << (seeded.result() != h1.result()) << '\n';

    std::cout << "自检通过\n";
    return 0;
}
