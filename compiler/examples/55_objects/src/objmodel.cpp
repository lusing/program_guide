// file: src/objmodel.cpp
// 第 55 章配套：迷你对象模型——布局、vtable、单继承前缀法、
// 多继承的类成员测试、静态/虚派发轨迹（虎书 §14）。
#include "objmodel.hpp"

#include <algorithm>
#include <sstream>

namespace tip {

ClassDecl &World::declare(const std::string &name, const std::string &parent,
                          const std::vector<std::string> &fields,
                          const std::vector<Method> &methods) {
    ClassDecl c;
    c.name = name;
    c.parent = parent;
    c.fields = fields;
    c.methods = methods;
    classes_[name] = c;
    return classes_[name];
}

void World::finalize() {
    // 布局：单继承前缀法——父类字段原序在前，子类字段接后；
    // 每个类记 (基址偏移, 字段表)。多继承的教学子集：
    // D 同时继承 B1、B2 ⇒ D 的布局 = B1 前缀 + B2 副本(偏移 b1Size) + 自有，
    // 访问 B2 的字段要走“D 内的 B2 子对象偏移”。
    for (auto &kv : classes_) {
        ClassDecl &c = kv.second;
        if (c.parent.empty()) {
            c.baseOffset = 0;
            c.layout = c.fields;
        } else if (c.parent.find(',') == std::string::npos) {
            // 单继承：前缀
            ClassDecl &p = classes_.at(c.parent);
            c.baseOffset = 0;
            c.layout = p.layout;
            c.layout.insert(c.layout.end(), c.fields.begin(), c.fields.end());
        } else {
            // 多继承：parent 形如 "B1,B2"（教学口径只支持两个）
            std::string p1 = c.parent.substr(0, c.parent.find(','));
            std::string p2 = c.parent.substr(c.parent.find(',') + 1);
            ClassDecl &b1 = classes_.at(p1);
            ClassDecl &b2 = classes_.at(p2);
            c.secondaryOffset = static_cast<int>(b1.layout.size());
            c.layout = b1.layout;
            c.layout.insert(c.layout.end(), b2.layout.begin(), b2.layout.end());
            c.layout.insert(c.layout.end(), c.fields.begin(), c.fields.end());
            c.secondaryParent = p2;
        }
    }
    // vtable：虚方法的槽表。单继承下子类 vtable = 父类副本 + 覆写槽替换 +
    // 新方法追加（前缀法的调用方兼容）。多继承教学子集只编主父的表。
    for (auto &kv : classes_) {
        ClassDecl &c = kv.second;
        VTable vt;
        if (!c.parent.empty() && c.parent.find(',') == std::string::npos) {
            vt = classes_.at(c.parent).vtable;   // 继承槽序
        }
        for (const auto &m : c.methods) {
            if (!m.isVirtual) continue;
            // 覆写或追加：按名字找槽
            int slot = -1;
            for (size_t k = 0; k < vt.slots.size(); ++k)
                if (vt.slotNames[k] == m.name) slot = static_cast<int>(k);
            if (slot < 0) {
                vt.slotNames.push_back(m.name);
                vt.slots.push_back(c.name + "::" + m.name);
            } else {
                vt.slots[slot] = c.name + "::" + m.name;
            }
        }
        c.vtable = vt;
    }
}

int World::fieldOffset(const std::string &cls, const std::string &field) const {
    const ClassDecl &c = classes_.at(cls);
    for (size_t k = 0; k < c.layout.size(); ++k)
        if (c.layout[k] == field) return static_cast<int>(k);
    return -1;
}

// 类成员测试（虎书 14.4 的 display 方案，教学两级）：
//   一级缓存：类自身；miss 时沿父链上行（单继承直走、多继承两路都查）。
int World::subclassTest(const std::string &cls, const std::string &ancestor,
                        std::vector<std::string> &path) const {
    if (cls == ancestor) return 0;
    path.push_back(cls);
    const ClassDecl &c = classes_.at(cls);
    if (c.parent.empty()) return -1;
    if (c.parent.find(',') == std::string::npos) {
        int d = subclassTest(c.parent, ancestor, path);
        return d < 0 ? -1 : d + 1;
    }
    std::string p1 = c.parent.substr(0, c.parent.find(','));
    std::string p2 = c.parent.substr(c.parent.find(',') + 1);
    int d1 = subclassTest(p1, ancestor, path);
    if (d1 >= 0) return d1 + 1;
    return subclassTest(p2, ancestor, path) < 0 ? -1
           : subclassTest(p2, ancestor, path) + 1;
}

std::string World::dispatchVirtual(const std::string &cls,
                                   const std::string &method) const {
    const ClassDecl *c = &classes_.at(cls);
    while (c) {
        for (size_t k = 0; k < c->vtable.slotNames.size(); ++k)
            if (c->vtable.slotNames[k] == method)
                return c->vtable.slots[k];
        c = c->parent.empty() || c->parent.find(',') != std::string::npos
                ? nullptr : &classes_.at(c->parent);
    }
    return "<无此虚方法>";
}

std::string World::dispatchStatic(const std::string &cls,
                                  const std::string &method) const {
    const ClassDecl *c = &classes_.at(cls);
    while (c) {
        for (const auto &m : c->methods)
            if (m.name == method && !m.isVirtual)
                return c->name + "::" + m.name;
        c = c->parent.empty() || c->parent.find(',') != std::string::npos
                ? nullptr : &classes_.at(c->parent);
    }
    return "<无此方法>";
}

// 虚调用的“可能目标集合”：0-CFA 口径——不做类型收敛时，
// 静态类型 T 的引用可能指向 T 或任何子类 ⇒ 目标 = 槽位上各子类的实现。
std::vector<std::string> World::virtualTargets(const std::string &staticType,
                                               const std::string &method) const {
    // 目标集按“实现名”去重——派发轨迹关心的是调用哪个函数，
    // 不是有多少个类派到它（Puppy 与 RoboDog 都派 Dog::speak，算一个目标）。
    std::vector<std::string> out;
    for (const auto &kv : classes_) {
        std::vector<std::string> path;
        if (subclassTest(kv.first, staticType, path) >= 0) {
            std::string t = dispatchVirtual(kv.first, method);
            if (t != "<无此虚方法>" &&
                std::find(out.begin(), out.end(), t) == out.end())
                out.push_back(t);
        }
    }
    return out;
}

// ================= 匠书增量（§28–29） =================
World::BoundMethod World::bindMethod(const std::string &cls,
                                     const std::string &method, int thisSlot) const {
    // 沿继承链找（与 dispatchVirtual 同策略：子类覆写优先）
    std::string cur = cls;
    while (!cur.empty()) {
        const ClassDecl &c = classes_.at(cur);
        for (const auto &m : c.methods)
            if (m.name == method) return BoundMethod{cur, method, thisSlot};
        cur = c.parent.find(',') == std::string::npos ? c.parent : "";
    }
    return BoundMethod{"", method, thisSlot};   // 未找到（诊断态）
}

bool World::thisUseLegal(const std::string &cls, bool insideMethod) const {
    (void)cls;
    // 教学口径：方法体内的 this 合法；顶层（方法体外）非法。
    // 检测器由调用方提供位置（insideMethod），此处只裁决。
    return insideMethod;
}

World::BoundMethod World::superDispatch(const std::string &cls,
                                        const std::string &method,
                                        int thisSlot) const {
    // 1) 找当前类的父类（super 的查找起点）；2) 从父类起沿链找方法；
    // 3) this 仍绑定原接收者——这就是"换起点不换 this"。
    const ClassDecl &c = classes_.at(cls);
    std::string start = c.parent;
    if (start.find(',') != std::string::npos)
        start = start.substr(0, start.find(','));   // 多继承取主父（教学）
    std::string cur = start;
    while (!cur.empty()) {
        const ClassDecl &p = classes_.at(cur);
        for (const auto &m : p.methods)
            if (m.name == method) return BoundMethod{cur, method, thisSlot};
        cur = p.parent;
    }
    return BoundMethod{"", method, thisSlot};
}

}  // namespace tip
