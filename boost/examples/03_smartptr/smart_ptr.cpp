// smart_ptr.cpp —— Boost.SmartPtr：所有权族谱全览
// 对应文档：docs/03-smartptr.md
#include <boost/smart_ptr.hpp>          // scoped/shared/weak/intrusive 一站式
#include <boost/make_shared.hpp>
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

int main() {
    std::cout << "== 1. scoped_ptr：独占、不可拷贝（unique_ptr 的直系祖先）==\n";
    {
        boost::scoped_ptr<Sensor> s{new Sensor("scoped")};
        std::cout << "  name=" << s->name << '\n';
        // boost::scoped_ptr<Sensor> s2 = s;   // 编译错误：不可拷贝也不可移动
    }   // 作用域结束自动析构
    std::cout << "  离开作用域后自动释放\n";

    std::cout << "== 2. shared_ptr：引用计数共享 ==\n";
    boost::shared_ptr<Sensor> a = boost::make_shared<Sensor>("shared");
    std::cout << "  a 引用计数 = " << a.use_count() << '\n';
    {
        boost::shared_ptr<Sensor> b = a;               // 拷贝：计数 +1
        std::cout << "  拷贝后 use_count = " << a.use_count() << '\n';
    }
    std::cout << "  b 析构后 use_count = " << a.use_count() << '\n';

    std::cout << "== 3. weak_ptr：观察不拥有（打破循环/缓存）==\n";
    boost::weak_ptr<Sensor> w = a;
    std::cout << "  expired() = " << std::boolalpha << w.expired() << '\n';
    if (boost::shared_ptr<Sensor> locked = w.lock()) { // lock() 临时提升
        std::cout << "  lock 成功: " << locked->name << '\n';
    }
    a.reset();
    std::cout << "  释放最后一个 shared 后 expired() = " << w.expired() << '\n';

    std::cout << "== 4. 自定义删除器：shared_ptr 管任意资源 ==\n";
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

    std::cout << "== 5. intrusive_ptr：计数长在对象身上（零控制块开销）==\n";
    {
        boost::intrusive_ptr<Node> n{new Node{"node"}};
        std::cout << "  refs = " << n->refs << '\n';
        boost::intrusive_ptr<Node> n2 = n;
        std::cout << "  拷贝后 refs = " << n->refs << '\n';
    }

    std::cout << "== 6. enable_shared_from_this：对象内部拿到自己的 shared_ptr ==\n";
    struct Task : boost::enable_shared_from_this<Task> {
        boost::shared_ptr<Task> self() { return shared_from_this(); }
    };
    boost::shared_ptr<Task> t = boost::make_shared<Task>();
    boost::shared_ptr<Task> t2 = t->self();
    std::cout << "  self() 拿到同一对象, use_count = " << t.use_count() << '\n';

    std::cout << "自检通过\n";
    return 0;
}
