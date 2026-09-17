#include <memory>
#include <print>
#include <string>
#include <vector>

// 09 动态内存与智能指针：所有权说话

struct Task {
    explicit Task(std::string n) : name{std::move(n)} {
        std::println("  + 构造 {}", name);
    }
    ~Task() { std::println("  - 析构 {}", name); }
    std::string name;
};

// unique_ptr 按值返回 = 转移所有权（工厂惯用法）
std::unique_ptr<Task> make_task(std::string name) {
    return std::make_unique<Task>(std::move(name));
}

int main() {
    // ═══ 9.1 unique_ptr：独占所有权 ═══
    auto t1 = make_task("调研");
    // auto t2 = t1;         // 编译错误：unique_ptr 不可拷贝
    auto t2 = std::move(t1);  // 只能转移；t1 变空
    std::println("t1 空了吗？{}", t1 == nullptr);
    std::println("t2 持有 {}", t2->name);

    // ═══ 9.2 作用域即生命周期 ═══
    {
        auto t3 = make_task("原型");
    }  // t3 在此自动析构——RAII 管理堆内存

    // ═══ 9.3 shared_ptr：共享所有权与引用计数 ═══
    auto shared1 = std::make_shared<Task>("发布");
    {
        auto shared2 = shared1;  // 拷贝：计数 +1
        std::println("引用计数 = {}", shared1.use_count());  // 2
    }  // shared2 析构：计数 -1
    std::println("引用计数 = {}", shared1.use_count());  // 1

    // ═══ 9.4 weak_ptr：观察但不拥有 ═══
    std::weak_ptr<Task> observer = shared1;
    if (auto locked = observer.lock()) {  // 尝试升级成 shared_ptr
        std::println("观察到 {}", locked->name);
    }
    shared1.reset();  // 释放最后一个强引用 → Task 立即析构
    std::println("对象还活着吗？{}", !observer.expired());  // false

    // ═══ 9.5 vector<unique_ptr>：多态持有的标配（见第 16 章）═══
    std::vector<std::unique_ptr<Task>> backlog;
    backlog.push_back(make_task("收尾"));
    backlog.push_back(make_task("复盘"));
    std::println("待办 {} 项", backlog.size());
    // 注意：容器析构时**元素按什么顺序销毁，标准没有规定** ——
    // libc++ 逆序、libstdc++ 正序、MSVC 又是一种，等着作用域结束就会看到三种输出。
    // 要让顺序确定，就自己按后进先出弹空它：
    while (!backlog.empty()) {
        backlog.pop_back();  // pop_back 销毁的"最后一个元素"是确定的
    }
    std::println("自检通过");
}  // t2（调研）在此析构 —— 它比前面几个都晚，因为活到了 main 结束
