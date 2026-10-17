// smart_ptr.cpp —— Boost.SmartPtr：所有权族谱全览（四类指针的完整合同）
// 对应文档：docs/03-smartptr.md
#include <boost/smart_ptr.hpp>          // scoped/shared/weak/intrusive 一站式
#include <boost/smart_ptr/intrusive_ref_counter.hpp>
#include <boost/smart_ptr/make_unique.hpp>   // 注意：make_unique 不在总头里
#include <iostream>
#include <string>

struct Sensor {
    std::string name;
    explicit Sensor(std::string n) : name(std::move(n)) {
        std::cout << "  Sensor(" << name << ") 构造\n";
    }
    ~Sensor() { std::cout << "  Sensor(" << name << ") 析构\n"; }
};

// intrusive_ptr 的引用计数就存在对象里—— intrusive_ptr_add_ref/release
// 两个钩子函数告诉 Boost 怎么操作它
struct Node {
    std::string tag;
    int refs = 0;
    explicit Node(std::string t) : tag(std::move(t)) {}
};
inline void intrusive_ptr_add_ref(Node* p) { ++p->refs; }
inline void intrusive_ptr_release(Node* p) { if (--p->refs == 0) delete p; }

// intrusive_ref_counter：不想手写钩子时的现成基类（默认线程安全计数）
struct Counted : boost::intrusive_ref_counter<Counted> {
    int x = 0;
};

int main() {
    std::cout << "== 1. scoped_ptr：独占、不可拷贝（unique_ptr 的直系祖先）==\n";
    {
        boost::scoped_ptr<Sensor> s{new Sensor("scoped")};
        std::cout << "  name=" << s->name << '\n';
        // boost::scoped_ptr<Sensor> s2 = s;   // 编译错误：不可拷贝也不可移动
        if (s) std::cout << "  bool 语境测试有效\n";       // 显式 bool 转型
        std::cout << "  与 nullptr 比较 = " << (s != nullptr) << '\n';
        // 合同要点（编译期保证，注释里存档）：
        //   s++ / std::prev(s)  → 编译错误：没有指针算术
        //   delete s.get()      → 运行期灾难：get() 拿到的指针脱离管理
        //   reset(p)            → 删旧存新；reset() 即置空
        //   持有 scoped_ptr 成员的类 → 整个类自动不可拷贝（连带传染）
    }   // 作用域结束自动析构
    std::cout << "  离开作用域后自动释放\n";

    std::cout << "== 2. make_unique：C++14 补课的 Boost 前身 ==\n";
    {
        // boost::make_unique 在单独的头文件里（不在 smart_ptr.hpp 中），
        // 位于 boost 名字空间——C++11 定了 unique_ptr 却忘了配工厂函数，
        // boost 先补的课，C++14 std 才跟上。
        auto u = boost::make_unique<int>(10);
        std::cout << "  boost::make_unique = " << *u << '\n';
        auto us = std::make_unique<std::string>("std 版同款");
        std::cout << "  std::make_unique = " << *us << '\n';
    }

    std::cout << "== 3. shared_ptr：引用计数共享 ==\n";
    boost::shared_ptr<Sensor> a = boost::make_shared<Sensor>("shared");
    std::cout << "  a 引用计数 = " << a.use_count() << '\n';
    {
        boost::shared_ptr<Sensor> b = a;               // 拷贝：计数 +1
        std::cout << "  拷贝后 use_count = " << a.use_count() << '\n';
        // unique() 比 use_count()==1 更快更可靠；use_count 仅调试用
        std::cout << "  a.unique() = " << a.unique() << '\n';
    }
    std::cout << "  b 析构后 use_count = " << a.use_count() << '\n';
    // 显式 bool 的边界：if/assert 里可隐式，做返回值/实参必须显式转型
    bool held = static_cast<bool>(a);
    std::cout << "  static_cast<bool>(a) = " << held << '\n';
    // reset()：计数 -1，不为 0 不删；带参版本 = 先减后接管新指针
    {
        boost::shared_ptr<Sensor> c = a;
        a.reset();
        std::cout << "  reset 后 a 空? " << (!a) << " c 仍活(计数="
                  << c.use_count() << ")\n";
        a = c;                                         // 拿回来继续用
    }

    std::cout << "== 4. weak_ptr：观察不拥有（打破循环/缓存）==\n";
    boost::weak_ptr<Sensor> w = a;
    std::cout << "  expired() = " << std::boolalpha << w.expired()
              << " empty() = " << w.empty() << '\n';
    if (boost::shared_ptr<Sensor> locked = w.lock()) { // lock() 临时提升
        std::cout << "  lock 成功: " << locked->name << '\n';
    }
    a.reset();
    std::cout << "  释放最后一个 shared 后 expired() = " << w.expired()
              << " lock 得空指针 = " << (!w.lock()) << '\n';

    std::cout << "== 5. 自定义删除器：shared_ptr 管任意资源 ==\n";
    {
        struct Conn { int id; };
        // shared_ptr 不只管内存——任何"需要释放的东西"都能托管：
        // 删除器换成 fclose / CloseHandle / sqlite3_close，套路一模一样
        boost::shared_ptr<Conn> conn(new Conn{7}, [](Conn* p) {
            delete p;
            std::cout << "  连接已由删除器关闭\n";
        });
        std::cout << "  conn->id = " << conn->id << '\n';
    }

    std::cout << "== 6. intrusive_ptr：计数长在对象身上（零控制块开销）==\n";
    {
        boost::intrusive_ptr<Node> n{new Node{"node"}};
        std::cout << "  refs = " << n->refs << '\n';
        boost::intrusive_ptr<Node> n2 = n;
        std::cout << "  拷贝后 refs = " << n->refs << '\n';
        // 第二构造参数 add_ref=false：不增加计数地"弱观察"（类似 weak_ptr）
        boost::intrusive_ptr<Node> observer(n.get(), false);
        std::cout << "  add_ref=false 观察（refs 仍 = " << n->refs << "）\n";
        // detach()：交出指针并放弃管理（unique_ptr::release 的同族）
        Node* raw = n2.detach();
        std::cout << "  detach 后 n2 空? " << (!n2) << " raw 仍受 n 管\n";
        boost::intrusive_ptr<Node> reattach(raw);      // 重新接管，计数 +1
        (void)reattach;
        // intrusive_ref_counter：现成基类，免手写钩子
        boost::intrusive_ptr<Counted> c{new Counted};
        c->x = 42;
        std::cout << "  intrusive_ref_counter: x = " << c->x
                  << " use_count = " << c->use_count() << '\n';
    }

    std::cout << "== 7. enable_shared_from_this：对象内部拿到自己的 shared_ptr ==\n";
    struct Task : boost::enable_shared_from_this<Task> {
        boost::shared_ptr<Task> self() { return shared_from_this(); }
    };
    boost::shared_ptr<Task> t = boost::make_shared<Task>();
    boost::shared_ptr<Task> t2 = t->self();
    std::cout << "  self() 拿到同一对象, use_count = " << t.use_count() << '\n';
    // 头号陷阱（不可运行演示，UB）：栈对象 Task t2; t2.self(); ← 控制块
    // 不存在，运行期未定义行为（boost 调试模式断言、std C++17 抛
    // bad_weak_ptr）。另一个陷阱：构造函数里调 shared_from_this() 同样 UB。

    std::cout << "自检通过\n";
    return 0;
}
