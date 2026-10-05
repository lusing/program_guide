// file: src/objmodel.hpp
// 第 46 章配套：迷你对象模型（虎书 §14 自包含蒸馏）。
#ifndef TIP_OBJMODEL_HPP
#define TIP_OBJMODEL_HPP

#include <map>
#include <string>
#include <vector>

namespace tip {

struct Method {
    std::string name;
    bool isVirtual = false;
};

struct VTable {
    std::vector<std::string> slotNames;
    std::vector<std::string> slots;   // 槽 → 实现名（“类::方法”）
};

struct ClassDecl {
    std::string name;
    std::string parent;              // 空 = 根；"B1,B2" = 多继承（教学两级）
    std::vector<std::string> fields;
    std::vector<Method> methods;
    // finalize() 后填：
    std::vector<std::string> layout; // 展平字段表（含继承）
    int baseOffset = 0;              // 主父子对象在自身内的偏移（教学恒 0）
    int secondaryOffset = -1;        // 多继承第二父子对象偏移
    std::string secondaryParent;
    VTable vtable;
};

class World {
public:
    ClassDecl &declare(const std::string &name, const std::string &parent,
                       const std::vector<std::string> &fields,
                       const std::vector<Method> &methods);
    void finalize();   // 布局 + vtable 一次算完（两遍：先声明后闭包）

    int fieldOffset(const std::string &cls, const std::string &field) const;

    // 类成员测试：cls 是 ancestor 的（间接）子类？返回继承深度，非子类 -1。
    // path 收集途经类名（display 方案的“逐级上行”实录）。
    int subclassTest(const std::string &cls, const std::string &ancestor,
                     std::vector<std::string> &path) const;

    // 派发：虚方法沿 vtable（子类覆写优先）；静态方法沿继承链直呼。
    std::string dispatchVirtual(const std::string &cls, const std::string &method) const;
    std::string dispatchStatic(const std::string &cls, const std::string &method) const;

    // 虚调用的可能目标集合（0-CFA 口径：静态类型 T ⇒ T 及其全部子类的实现）。
    std::vector<std::string> virtualTargets(const std::string &staticType,
                                            const std::string &method) const;

    const std::map<std::string, ClassDecl> &classes() const { return classes_; }

private:
    std::map<std::string, ClassDecl> classes_;
};

}  // namespace tip

#endif  // TIP_OBJMODEL_HPP
