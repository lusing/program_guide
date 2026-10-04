#pragma once
// 35 自注册插件框架：插件在 main 之前把自己塞进注册表，main 只认名字不认类型。
// 核心：Meyers 单例注册表（躲静态初始化顺序事故）+ RegisterOne 哨兵（构造即注册）。
#include <memory>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace dp {

// 插件合同：报名字 + 干活。
struct Codec {
    virtual ~Codec() = default;
    virtual std::string name() const = 0;
    virtual std::string encode(std::string_view data) const = 0;
};

// 注册表：Meyers 单例——各编译单元的静态注册量构造时才首次调用 instance()，
// 首个调用者触发构造，"谁先谁后"的跨编译单元顺序问题被函数内静态化解。
class Registry {
public:
    static Registry& instance() { static Registry r; return r; }

    bool add(std::unique_ptr<Codec> c) {
        if (c == nullptr || find(c->name()) != nullptr) return false;   // 重名拒绝
        plugins_.push_back(std::move(c));
        return true;
    }

    const Codec* find(std::string_view name) const {
        for (const auto& p : plugins_)
            if (p->name() == name) return p.get();
        return nullptr;
    }

    std::size_t size() const { return plugins_.size(); }

private:
    Registry() = default;
    std::vector<std::unique_ptr<Codec>> plugins_;
};

// 注册哨兵：模板类——构造时把 C 实例化并注册。每个"插件"翻译单元里放一个
// 静态实例，动态初始化在 main 之前完成。模板类而非模板构造函数：
// 静态对象 `RegisterOne reg_hex;` 必须能默认构造，构造函数模板做不到。
template <class C>
struct RegisterOne {
    RegisterOne() { Registry::instance().add(std::make_unique<C>()); }
};

// 面向名字的门面：客户不接触 Codec 指针。
inline std::string encode_with(std::string_view kind, std::string_view data) {
    const Codec* c = Registry::instance().find(kind);
    if (c == nullptr) return "err";
    return c->encode(data);
}

}  // namespace dp
