#pragma once
// 观察者：主题状态变化时自动通知所有订阅者——一对多依赖，单向（主题不认识具体观察者）。
#include <functional>
#include <vector>

namespace dp {

// Observer：抽象观察者——主题只认这个接口，具体显示板对主题不可见。
class Observer {
public:
    virtual ~Observer() = default;
    virtual void on_update(double t) = 0;
};

// Subject：主题——attach/detach/notify 三件套。
class Subject {
public:
    void attach(Observer* o) { obs_.push_back(o); }
    void detach(Observer* o) {
        for (auto it = obs_.begin(); it != obs_.end(); ++it)
            if (*it == o) { obs_.erase(it); return; }
    }
    void notify(double t) {
        for (auto* o : obs_) o->on_update(t);      // 顺序通知：观察者 O(n)
    }
    [[nodiscard]] size_t count() const { return obs_.size(); }

private:
    std::vector<Observer*> obs_;     // 裸指针：主题不拥有观察者（生命周期归客户）
};

// ConcreteObserver：两块显示板，各自记录最近一次收到的温度。
struct DisplayA final : Observer {
    double last = -999;
    void on_update(double t) override { last = t; }
};

struct DisplayB final : Observer {
    double last = -999;
    bool received = false;
    void on_update(double t) override { last = t; received = true; }
};

// ---- 现代线：function 主题——观察者退化为闭包 ----
// 订阅 = push 一个 std::function；通知 = 遍历调用。
// 坑：通知途中 unsubscribe 会令迭代器失效——移除必须在遍历之外（或先收集后删除）。
class FunctionHub {
public:
    void subscribe(std::function<void(double)> f) { subs_.push_back(std::move(f)); }
    void notify(double t) const {
        for (const auto& f : subs_) f(t);
    }
    [[nodiscard]] size_t count() const { return subs_.size(); }

private:
    std::vector<std::function<void(double)>> subs_;
};

}  // namespace dp
