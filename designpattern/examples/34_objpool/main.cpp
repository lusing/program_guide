// 34 对象池实战：复用不虚增 created、上限拒绝、RAII 异常路径归还。
#include <cassert>
#include <print>
#include <stdexcept>

#include "pool.hpp"

int main() {
    using namespace dp;

    Pool& pool = Pool::instance();

    // 两次 acquire：不同 id（比较不相等，不打印值），created 只在新建时涨
    Conn& a = pool.acquire();
    Conn& b = pool.acquire();
    assert(a.id() != b.id());
    assert(pool.created() == 2);
    assert(pool.in_use_count() == 2);
    std::println("借出线: 两次 acquire 得两个不同 id，created=2");

    // 归还后再借：复用同一对象，created 不变
    pool.release(a);
    assert(!a.in_use());
    Conn& c = pool.acquire();
    assert(c.id() == a.id());
    assert(pool.created() == 2);          // 复用不虚增
    std::println("复用线: 归还后 acquire 拿回同一 id，created 仍为 2");

    // 补满到 4 个：第 5 个 acquire 抛异常
    Conn& d = pool.acquire();             // 新建 id2
    Conn& e = pool.acquire();             // 新建 id3
    assert(pool.created() == 4);
    int caught = 0;
    try {
        pool.acquire();                   // 已满 4：应抛
    } catch (const std::runtime_error&) {
        ++caught;
    }
    assert(caught == 1);
    assert(pool.in_use_count() == 4);
    std::println("上限线: 第 5 个 acquire 抛 runtime_error，caught=1");

    // 清场：全部归还
    pool.release(b);
    pool.release(c);
    pool.release(d);
    pool.release(e);
    assert(pool.in_use_count() == 0);

    // RAII 守卫：正常路径自动归还
    {
        Connection g(pool);
        assert(pool.in_use_count() == 1);
        assert(g.get().id() >= 0);
    }
    assert(pool.in_use_count() == 0);

    // RAII 守卫：异常路径也归还（守卫析构在栈展开时执行）
    int caught2 = 0;
    try {
        Connection g(pool);
        assert(pool.in_use_count() == 1);
        throw std::runtime_error("boom");
    } catch (const std::runtime_error&) {
        ++caught2;
    }
    assert(pool.in_use_count() == 0);     // 异常路径守卫已归还
    assert(caught2 == 1);
    std::println("RAII 线: 正常与异常两条路径 in_use 都归零");

    std::println("自检通过");
}
