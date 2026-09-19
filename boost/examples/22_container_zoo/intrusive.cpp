// intrusive.cpp —— Boost.Intrusive（2005）：侵入式容器——链/树节点长在
// 对象里，容器零分配。性能敏感（游戏引擎、内存池生态）的王牌。
// 对应文档：docs/22-container-zoo.md
#include <boost/intrusive/list.hpp>
#include <boost/intrusive/set.hpp>
#include <iostream>
#include <vector>

namespace bi = boost::intrusive;

struct Task : bi::list_base_hook<>, bi::set_base_hook<> {
    int id;
    explicit Task(int i) : id(i) {}
    bool operator<(const Task& o) const { return id < o.id; }   // set 的比较
};

// make_list 方式：不用钩子基类也行（成员钩子）；这里用基类钩子最直观
using TaskList = bi::list<Task>;
using TaskSet  = bi::set<Task, bi::constant_time_size<false>>;

int main() {
    std::vector<Task> tasks;                    // 对象的真正归属（一次分配）
    for (int i = 3; i >= 1; --i) tasks.emplace_back(i * 10);

    TaskList list;
    TaskSet  set;
    for (Task& t : tasks) {
        list.push_back(t);                      // 不分配：只改指针
        set.insert(t);
    }

    std::cout << "list 按插入序:";
    for (const Task& t : list) std::cout << ' ' << t.id;
    std::cout << '\n';

    std::cout << "set 按 id 排序:";             // set 默认按 < 比较——用 id
    for (const Task& t : set) std::cout << ' ' << t.id;
    std::cout << '\n';

    // 高速拔插：从容器摘除 O(1)，无任何内存操作
    list.erase(list.iterator_to(tasks[0]));
    std::cout << "拔掉一个后 list:";
    for (const Task& t : list) std::cout << ' ' << t.id;
    std::cout << '\n';

    // 危险区：对象析构前必须从所有容器摘除（侵入式不管理生命周期）
    list.clear(); set.clear();                  // 只解链，不 delete
    std::cout << "自检通过\n";
    return 0;
}
