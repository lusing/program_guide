// sp_patterns.cpp —— shared_ptr 应用模式全家：pimpl / 工厂 / 删除器 / void /
//                    转型 / 别名构造 / owner_less / 容器 / 循环引用
// 对应文档：docs/03-smartptr.md
#define _CRT_SECURE_NO_WARNINGS   // 例程要用 fopen/fclose 演示删除器（须在最前）
#include <boost/smart_ptr.hpp>
#include <boost/smart_ptr/owner_less.hpp>
#include <fstream>
#include <iostream>
#include <map>
#include <set>
#include <vector>

// ═══ 模式一：pimpl（桥接模式）——头文件只声明，实现藏在 impl ═══
// 真实工程里 sample 声明在头文件、impl 定义在 cpp；单文件演示时
// 用两段式模拟"头文件可见的部分"与"实现文件的部分"。
class sample {
public:
    sample();                       // 头文件里只有这两个声明
    void print() const;
private:
    class impl;                     // 不完整声明：外界不知道实现细节
    boost::shared_ptr<impl> p;      // 桥：shared_ptr 支持不完整类型
};

class sample::impl {                // "实现文件"部分
public:
    void print() const { std::cout << "  pimpl: impl print（实现细节被桥接隐藏）\n"; }
};
sample::sample() : p(new impl) {}
void sample::print() const { p->print(); }

// ═══ 模式二：工厂模式 + 保护析构函数 ═══
// abstract 的析构是 protected：用户拿不到 delete 的权利，
// 只能通过工厂返回的 shared_ptr 间接管理生命周期。
class abstract {
public:
    virtual void f() = 0;
    virtual void g() = 0;
protected:
    virtual ~abstract() = default;  // protected：外界 delete q 编译不过
};
class impl_final : public abstract {
public:
    void f() override { std::cout << "  工厂: impl f\n"; }
    void g() override { std::cout << "  工厂: impl g\n"; }
};
boost::shared_ptr<abstract> create() { return boost::make_shared<impl_final>(); }

// ═══ 模式三：shared_ptr<void> + 删除器 = 退出作用域执行任意函数 ═══
void any_func(void*) { std::cout << "  void 技巧: 退出作用域时执行了任意函数\n"; }

// ═══ 模式四：循环引用对照组（析构打印验证泄漏与否） ═══
struct node_shared {
    const char* tag;
    boost::shared_ptr<node_shared> next;     // 强引用：成环 = 泄漏
    explicit node_shared(const char* t) : tag(t) {}
    ~node_shared() { std::cout << "    " << tag << " 析构\n"; }
};
struct node_weak {
    const char* tag;
    boost::weak_ptr<node_weak> next;         // 弱引用：成环也能正常析构
    explicit node_weak(const char* t) : tag(t) {}
    ~node_weak() { std::cout << "    " << tag << " 析构\n"; }
};

int main() {
    using boost::shared_ptr;
    using boost::make_shared;

    std::cout << "== 1. pimpl（桥接模式）==\n";
    sample s;                          // 用户只见接口，不见实现
    s.print();

    std::cout << "== 2. 工厂模式 + 保护析构 ==\n";
    auto p = create();                 // 工厂返回 shared_ptr
    p->f();
    p->g();
    // 想绕过去？abstract* q = p.get(); delete q;  ← 编译错误：
    // abstract 的析构函数是 protected，外界无权 delete。
    // 这正是"接口类配工厂"的标准姿势：资源只能从工厂出来、由智能指针管。

    std::cout << "== 3. 定制删除器：FILE 一样能 RAII ==\n";
    {
        std::ofstream("sp_demo.txt") << "hello deleter";  // 先造一个文件
        shared_ptr<std::FILE> fp(std::fopen("sp_demo.txt", "r"), std::fclose);
        std::cout << "  FILE 打开? " << (fp != nullptr) << '\n';
        int c = fp ? std::fgetc(fp.get()) : EOF;
        std::cout << "  首字符 = " << static_cast<char>(c) << '\n';
    }                                  // 析构 → fclose 自动执行
    std::remove("sp_demo.txt");
    // get_deleter：查看/触摸控制块里存的删除器
    shared_ptr<int> di(new int(42), [](int* x) { delete x; });
    if (auto* d = boost::get_deleter<std::function<void(int*)>>(di))
        std::cout << "  get_deleter 取到函数对象? " << static_cast<bool>(*d) << '\n';

    std::cout << "== 4. shared_ptr<void>：任意类型的容器 + 任意善后 ==\n";
    {
        shared_ptr<void> guard(nullptr, any_func);
        shared_ptr<void> box = make_shared<int>(7);   // void* 装任意类型
        std::cout << "  box 存了 int? "
                  << (*boost::static_pointer_cast<int>(box) == 7) << '\n';
    }                                  // guard 析构 → any_func() 被调用

    std::cout << "== 5. 转型三件套（返回转型后的 shared_ptr）==\n";
    shared_ptr<std::exception> se(new std::bad_exception);
    auto be = boost::dynamic_pointer_cast<std::bad_exception>(se);   // 下行
    auto back = boost::static_pointer_cast<std::exception>(be);      // 上行
    std::cout << "  dynamic 成功? " << static_cast<bool>(be)
              << " 回转同源? " << (back == se) << '\n';

    std::cout << "== 6. 别名构造 + owner_less ==\n";
    {
        auto whole = make_shared<std::pair<int, int>>(0, 1);
        shared_ptr<int> second(whole, &whole->second);   // 别名构造：
        // 共享 whole 的计数，但 get() 指向 second 成员
        std::cout << "  use_count 同源? "
                  << (whole.use_count() == 2 &&
                      whole.use_count() == second.use_count())
                  << " 指向不同? "
                  << (static_cast<void*>(whole.get()) !=
                      static_cast<void*>(second.get()))
                  << " *second = " << *second << '\n';
        // 别名构造让"指针值比较"失真，owner_less 按"所有权"排序：
        typedef shared_ptr<int> int_ptr;
        typedef boost::owner_less<int_ptr> int_ptr_less;
        int n = 20;
        int_ptr p1(new int(10));
        int_ptr p2(p1, &n);            // 与 p1 同源（等价）
        std::cout << "  p1 与别名 p2 等价（不小于互不成立）? "
                  << (!int_ptr_less()(p1, p2) && !int_ptr_less()(p2, p1))
                  << '\n';
        // 【对第 5 版书的实测勘误】书说"默认 set 按指针值比较、要 owner_less
        // 才按所有权去重"。实测 1.92：shared_ptr 的 operator< 本来就是
        // **所有权序**（std 也这么规定），默认 set 与 owner_less set
        // 都是 1。owner_less 的真正用途是显式表达意图、以及比较器要
        // 单独声明的场合（std::map 的第三个模板参数）。
        std::set<int_ptr> by_default;
        by_default.insert(p1);
        by_default.insert(p2);         // 同源别名 → 默认序下也只算一个
        std::set<int_ptr, int_ptr_less> os;
        os.insert(p1);
        os.insert(p2);
        std::cout << "  默认 set 大小 = " << by_default.size()
                  << " owner_less set 大小 = " << os.size() << '\n';
    }

    std::cout << "== 7. 容器里的 shared_ptr ==\n";
    {
        std::vector<shared_ptr<int>> v(3);
        int i = 0;
        for (auto& slot : v) slot = make_shared<int>(++i * 10);
        // 迭代器版要解两次引用：*( *pos )，range-for 直接拿到 shared_ptr
        auto pos = v.begin();
        std::cout << "  迭代器双解引用 = " << **pos
                  << "  range-for = " << *v[2] << '\n';
        std::map<shared_ptr<std::string>, int> m;   // operator< 可作关联容器键
        m[make_shared<std::string>("one")] = 111;
        std::cout << "  二次 make_shared 查不到（每次都是新对象）? "
                  << (m.find(make_shared<std::string>("one")) == m.end())
                  << '\n';
    }

    std::cout << "== 8. 循环引用：shared 成环泄漏 vs weak 解环 ==\n";
    {
        auto a1 = make_shared<node_shared>("A(shared)");
        auto b1 = make_shared<node_shared>("B(shared)");
        a1->next = b1;
        b1->next = a1;                 // 成环：双方计数都是 2
        std::cout << "  shared 成环 use_count=2? "
                  << (a1.use_count() == 2 && b1.use_count() == 2) << '\n';
    }                                  // 离开作用域：计数各降到 1，无人析构
    std::cout << "  （上面没有出现 A/B 析构——这就是泄漏）\n";
    {
        auto a2 = make_shared<node_weak>("A(weak)");
        auto b2 = make_shared<node_weak>("B(weak)");
        a2->next = b2;
        b2->next = a2;                 // weak 环：不增加计数
        std::cout << "  weak 成环 use_count=1? "
                  << (a2.use_count() == 1 && b2.use_count() == 1) << '\n';
        if (!a2->next.expired()) {     // 先验活再提升
            auto n = a2->next.lock();
            std::cout << "  lock 拿到 B? " << (n->tag[0] == 'B') << '\n';
        }
    }                                  // 离开作用域：正常析构（见下方打印）

    std::cout << "自检通过\n";
    return 0;
}
