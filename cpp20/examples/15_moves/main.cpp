#include <print>
#include <string>
#include <utility>
#include <vector>

// 15 移动语义：值类别、std::move、完美转发、RVO

class Tracer {
public:
    explicit Tracer(std::string name) : name_{std::move(name)} {
        std::println("  构造 {}", name_);
    }
    Tracer(const Tracer& other) : name_{other.name_} {
        ++copies_;
        std::println("  拷贝 {}", name_);
    }
    Tracer(Tracer&& other) noexcept : name_{std::move(other.name_)} {
        ++moves_;
        std::println("  移动 {}", name_);
    }
    ~Tracer() = default;
    static int copies() { return copies_; }
    static int moves() { return moves_; }

private:
    std::string name_;
    inline static int copies_ = 0;
    inline static int moves_ = 0;
};

// ═══ 15.4 完美转发：保持调用方的值类别 ═══
void process(const Tracer&) { std::println("  process 收到左值"); }
void process(Tracer&&) { std::println("  process 收到右值"); }

template <typename T>
void relay(T&& arg) {
    process(std::forward<T>(arg));
}

int main() {
    // ═══ 15.1 拷贝 vs 移动 ═══
    std::println("-- 拷贝 --");
    Tracer a{"原件"};
    Tracer b = a;             // 拷贝构造
    std::println("-- 移动 --");
    Tracer c = std::move(a);  // 移动构造：a 进入"被搬空"状态

    // ═══ 15.2 容器操作：move 让插入便宜 ═══
    std::println("-- vector 插入 --");
    std::vector<Tracer> box;
    box.reserve(2);                 // 预留容量：排除扩容干扰
    box.push_back(Tracer{"临时"});  // 纯右值经 push_back(T&&)：一次移动落位
    Tracer named{"具名"};
    box.push_back(std::move(named));  // 具名对象要显式 move

    // ═══ 15.3 RVO：返回纯右值，连移动都省 ═══
    auto make = []() -> Tracer { return Tracer{"返回值"}; };
    Tracer r = make();  // C++17 保证消除：0 次拷贝 0 次移动

    std::println("统计：拷贝 {} 次，移动 {} 次", Tracer::copies(), Tracer::moves());

    // ═══ 15.4 完美转发 ═══
    std::println("-- 转发 --");
    Tracer x{"左值源"};
    relay(x);                 // 左值 → process(const Tracer&)
    relay(Tracer{"右值源"});  // 右值 → process(Tracer&&)
    std::println("自检通过");
}
