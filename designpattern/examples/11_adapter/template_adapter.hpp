#pragma once
// 类适配器：用（私有）继承同时继承 Target 与 Adaptee——C++ 特有的形态。
#include "object_adapter.hpp"

namespace dp {

// 继承 Target 获得"是一个栈"的接口身份；私有继承 Adaptee 获得它的实现，
// 但阻断"Adapter 不是一个 LegacyStack"的误用——私有继承表达"按实现继承"。
class StackClassAdapter final : public StackLike, private LegacyStack {
public:
    void push(int v) override { LegacyStack::push(v); }   // 显式指名，防自递归
    int pop() override { return LegacyStack::pop(); }
    [[nodiscard]] bool empty() const override { return size() == 0; }

private:
    using LegacyStack::top;   // 旧接口不外泄：把 top 留成私有
    using LegacyStack::size;
};

}  // namespace dp
