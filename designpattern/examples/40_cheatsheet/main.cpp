// 40 速查表：23 模式 ×（一句话意图 / 现代替代）固定文本逐行打印，行数断言 23。
#include <cassert>
#include <print>
#include <string>
#include <string_view>
#include <vector>

namespace {

struct Row {
    std::string_view name;
    std::string_view intent;
    std::string_view modern;
};

// 23 行固定文本：意图栏一句话说清"什么会变集中到哪"；现代栏给 C++23 的替代/搭档。
const std::vector<Row>& rows() {
    static const std::vector<Row> r = {
        {"Abstract Factory", "产品族的成套创建", "concept 工厂 / 直接构造"},
        {"Builder",         "分步组装复杂对象",   "聚合初始化 / 指定初始化器"},
        {"Factory Method",  "子类决定实例化哪个类", "构造函数私有 + 工厂函数"},
        {"Prototype",       "按原型克隆创建",     "拷贝构造 / clone()"},
        {"Singleton",       "全局唯一实例",       "Meyers 单例 / 依赖注入"},
        {"Adapter",         "接口转换",          "concept 适配 / lambda 包装"},
        {"Bridge",          "抽象与实现两维分离", "variant × 策略双参数"},
        {"Composite",       "树形统一接口",       "variant 递归 + unique_ptr 拆环"},
        {"Decorator",       "包装叠行为",         "std::function 链 / lambda 组合"},
        {"Facade",          "一键门面",          "自由函数封装 / make_xxx"},
        {"Flyweight",       "共享不可变内部状态", "intern 表 / shared_ptr 缓存"},
        {"Proxy",           "控制访问（懒/守卫/远程）", "operator-> 智能指针 / RAII 守卫"},
        {"Chain of Resp.",  "过闸链，一关否决即止", "Guard 管道（std::function 序列）"},
        {"Command",         "操作对象化可撤销",   "lambda + 可逆记录"},
        {"Interpreter",     "文法规则即类",       "variant 节点 + visit 求值"},
        {"Iterator",        "遍历与容器解耦",     "range / view（已下沉语言设施）"},
        {"Mediator",        "网状交互改星型",     "EventBus（话题字符串解耦）"},
        {"Memento",         "快照存取时点",       "值语义快照 / shared_ptr COW"},
        {"Observer",        "订阅名单的解耦通知", "std::function 订阅 / RAII 句柄"},
        {"State",           "状态驱动行为切换",   "variant 状态 / constexpr 转移表"},
        {"Strategy",        "算法可整体替换",     "concept 策略 / std::function"},
        {"Template Method", "骨架固定步骤下放",   "CRTP / 模板参数注入"},
        {"Visitor",         "结构冻结操作开放",   "variant + overload 组合子"},
    };
    return r;
}

}  // namespace

int main() {
    assert(rows().size() == 23);   // 23 行速查表，增删模式此处即红
    for (const auto& r : rows()) {
        std::println("{:<16} | {:<14} | {}", r.name, r.intent, r.modern);
    }
    std::println("速查表: 23 行 × 3 栏（模式 / 意图 / 现代替代）");
    std::println("自检通过");
}
