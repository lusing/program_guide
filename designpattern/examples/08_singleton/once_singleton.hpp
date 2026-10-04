#pragma once
// call_once 单例：需要带参数构造时用它——magic static 不收参。
#include <mutex>
#include <string>

namespace dp {

class NamedPool {
public:
    // 首调者给名字，之后所有人共享同一实例——构造参数只生效一次。
    static NamedPool& instance(std::string name) {
        static NamedPool* inst = nullptr;
        static std::once_flag flag;
        std::call_once(flag, [&] { inst = new NamedPool(std::move(name)); });
        return *inst;
    }

    [[nodiscard]] const std::string& name() const { return name_; }

private:
    explicit NamedPool(std::string name) : name_(std::move(name)) {}
    std::string name_;
};

// 对比写法：C++11 后其实可以给局部 static 传参——参数取"第一次调用者"：
//   static NamedPool inst(std::move(name));
// 首调用者的参数生效、后续调用者的参数被丢弃。call_once 版的意义在于
// 显式控制"谁提供参数"并配合自定义删除器（此处教学演示，第 8 章正文展开）。

}  // namespace dp
