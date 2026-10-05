// file: src/main.cpp
// 第 55 章驱动（无参运行，走“简单程序”对账协议）：
//   类层级（单继承链 + 多继承钻石教学子集）→ 布局表 → vtable 表 →
//   静态/虚派发轨迹 → 类成员测试路径 → 虚调用 0-CFA 目标集 → 对账。
#include "objmodel.hpp"

#include <iostream>

namespace {

void showVec(const std::vector<std::string> &v, const char *sep = " ") {
    std::cout << "{";
    for (size_t i = 0; i < v.size(); ++i)
        std::cout << (i ? sep : "") << v[i];
    std::cout << "}";
}

}  // namespace

int main() {
    tip::World w;
    // Animal（根）：字段 name；方法 speak（虚）、kind（静态）
    w.declare("Animal", "", {"name"},
              {{"speak", true}, {"kind", false}});
    // Dog < Animal：+字段 barkHz；覆写 speak（虚）；新方法 fetch（虚）
    w.declare("Dog", "Animal", {"barkHz"},
              {{"speak", true}, {"fetch", true}});
    // Puppy < Dog：+字段 cute
    w.declare("Puppy", "Dog", {"cute"}, {});
    // Robot（独立根）：字段 serial；方法 speak（虚）——不同根的同名虚方法
    w.declare("Robot", "", {"serial"}, {{"speak", true}});
    // RoboDog < Dog,Robot：多继承教学子集
    w.declare("RoboDog", "Dog,Robot", {"firmware"}, {});
    w.finalize();

    std::cout << "== 布局（单继承前缀法）==\n";
    for (const auto &kv : w.classes()) {
        const tip::ClassDecl &c = kv.second;
        std::cout << "  " << c.name << " [";
        for (size_t k = 0; k < c.layout.size(); ++k)
            std::cout << (k ? " " : "") << k << ":" << c.layout[k];
        std::cout << "]";
        if (c.secondaryOffset >= 0)
            std::cout << "  (第二父 " << c.secondaryParent
                      << " 子对象偏移 " << c.secondaryOffset << ")";
        std::cout << '\n';
    }

    std::cout << "== vtable ==\n";
    for (const auto &kv : w.classes()) {
        const tip::ClassDecl &c = kv.second;
        std::cout << "  " << c.name << ": ";
        for (size_t k = 0; k < c.vtable.slotNames.size(); ++k)
            std::cout << "[" << k << "]" << c.vtable.slotNames[k]
                      << "->" << c.vtable.slots[k] << " ";
        std::cout << '\n';
    }

    std::cout << "== 静态派发 ==\n";
    std::cout << "  Puppy.kind  = " << w.dispatchStatic("Puppy", "kind") << '\n';
    std::cout << "  Dog.kind    = " << w.dispatchStatic("Dog", "kind") << '\n';

    std::cout << "== 虚派发（沿 vtable）==\n";
    std::cout << "  Animal.speak = " << w.dispatchVirtual("Animal", "speak") << '\n';
    std::cout << "  Dog.speak    = " << w.dispatchVirtual("Dog", "speak") << '\n';
    std::cout << "  Puppy.speak  = " << w.dispatchVirtual("Puppy", "speak") << '\n';
    std::cout << "  Puppy.fetch  = " << w.dispatchVirtual("Puppy", "fetch") << '\n';

    std::cout << "== 类成员测试（display 上行）==\n";
    for (const auto &pair : std::vector<std::pair<std::string, std::string>>{
             {"Puppy", "Animal"}, {"RoboDog", "Robot"}, {"Robot", "Animal"}}) {
        std::vector<std::string> path;
        int d = w.subclassTest(pair.first, pair.second, path);
        std::cout << "  " << pair.first << " instanceof " << pair.second
                  << " : " << (d >= 0 ? "yes" : "no");
        if (d >= 0) std::cout << " (深度 " << d << ", 途经 ";
        if (d >= 0) showVec(path, "->");
        if (d >= 0) std::cout << ")";
        std::cout << '\n';
    }

    std::cout << "== 虚调用的 0-CFA 目标集 ==\n";
    for (const auto &st : {"Animal", "Dog"}) {
        std::cout << "  静态类型 " << st << ".speak() 可能调用: ";
        showVec(w.virtualTargets(st, "speak"));
        std::cout << '\n';
    }

    std::cout << "== 对账 ==\n";
    // 手工核对清单（每行一个断言，正文 46.5 逐条解读）
    bool ok1 = w.fieldOffset("Puppy", "name") == 0 &&
               w.fieldOffset("Puppy", "barkHz") == 1 &&
               w.fieldOffset("Puppy", "cute") == 2;
    bool ok2 = w.dispatchVirtual("Puppy", "speak") == "Dog::speak";
    bool ok3 = w.virtualTargets("Animal", "speak").size() == 2;   // Animal:: + Dog::（Robot 不同根）
    bool ok4 = w.subclassTest("RoboDog", "Robot", *new std::vector<std::string>) >= 0;
    std::cout << "  前缀法偏移（name@0 barkHz@1 cute@2）: " << (ok1 ? "yes" : "NO") << '\n';
    std::cout << "  Puppy.speak 命中 Dog 覆写槽: " << (ok2 ? "yes" : "NO") << '\n';
    std::cout << "  Animal 引用的目标集恰 2 个: " << (ok3 ? "yes" : "NO") << '\n';
    std::cout << "  多继承成员测试可达第二父: " << (ok4 ? "yes" : "NO") << '\n';

    // ================= 匠书增量（§28–29）：方法即闭包 =================
    std::cout << "== bound method（方法即闭包）==\n";
    tip::World::BoundMethod bm = w.bindMethod("Puppy", "speak", 7);
    std::cout << "  var m = Puppy.speak; -> 定义类=" << bm.className
              << " 方法=" << bm.methodName << " 捕获this=对象" << bm.thisSlot << '\n';
    bool ok5 = bm.className == "Dog" && bm.thisSlot == 7;
    std::cout << "  延迟调用 this 不丢（绑定类 Dog、this=7）: " << (ok5 ? "yes" : "NO") << '\n';
    std::cout << "  对比 vtable 派发（每次调用查表）: " << w.dispatchVirtual("Puppy", "speak")
              << "（同名同源——闭包缓存了查找结果）\n";

    std::cout << "== this 逃逸检测 ==\n";
    std::cout << "  方法体内 this: " << (w.thisUseLegal("Puppy", true) ? "合法" : "非法") << '\n';
    std::cout << "  顶层 this:     " << (w.thisUseLegal("Puppy", false) ? "合法" : "非法")
              << "（静态拒绝）\n";
    bool ok6 = w.thisUseLegal("Puppy", true) && !w.thisUseLegal("Puppy", false);

    std::cout << "== super 链（换起点不换 this）==\n";
    // Puppy 自己不覆写 speak（继承 Dog 的）——super 从父链 Dog 起查，
    // 命中 Dog::speak（super 的语义：跳过**自己的**定义，不是跳过全部覆写）
    tip::World::BoundMethod sup = w.superDispatch("Puppy", "speak", 7);
    std::cout << "  super.speak 从 " << sup.className << " 找到，this 仍是对象" << sup.thisSlot << '\n';
    bool ok7 = sup.className == "Dog" && sup.thisSlot == 7;
    std::cout << "  Puppy 的 super 命中 Dog、this 不换: " << (ok7 ? "yes" : "NO") << '\n';
    // Dog 覆写了 speak——Dog 内的 super 跳过自己的覆写、直达 Animal
    tip::World::BoundMethod sup2 = w.superDispatch("Dog", "speak", 3);
    bool ok8 = sup2.className == "Animal" && sup2.thisSlot == 3;
    std::cout << "  Dog 的 super 跳过自身覆写到 Animal、this=3 保持: " << (ok8 ? "yes" : "NO") << '\n';
    std::cout << "== 对账（增量）==\n";
    std::cout << "  bound/super/this 检测: "
              << ((ok5 && ok6 && ok7 && ok8) ? "all yes" : "FAIL") << '\n';
    return (ok1 && ok2 && ok3 && ok4 && ok5 && ok6 && ok7 && ok8) ? 0 : 1;
}
