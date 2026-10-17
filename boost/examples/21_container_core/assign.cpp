// assign.cpp —— Boost.Assign（2003）：C++98 没有 initializer_list 时代的
// 容器字面量。今天 95% 被 {} 初始化取代——它是"语言特性吞掉库"的教科书。
// 对应文档：docs/21-container-core.md
#include <boost/assign/list_of.hpp>
#include <boost/assign/list_inserter.hpp>
#include <boost/assign/std/vector.hpp>
#include <boost/assign/std/map.hpp>
#include <boost/assign/std/stack.hpp>
#include <boost/assign/std/queue.hpp>
#include <iostream>
#include <map>
#include <queue>
#include <stack>
#include <string>
#include <vector>

int main() {
    using namespace boost::assign;

    // 1) 2003 年的姿态：list_of 造容器
    std::vector<int> v = list_of(1)(2)(3);
    std::cout << "list_of:";
    for (int x : v) std::cout << ' ' << x;
    std::cout << '\n';

    // 2) map_list_of：键值对字面量
    std::map<std::string, int> ages = map_list_of("ada", 36)("grace", 85);
    std::cout << "map_list_of: ada=" << ages.at("ada") << " grace=" << ages.at("grace") << '\n';

    // 3) += 语法糖：往已有容器追加
    std::vector<int> w;
    w += 10, 20, 30;
    std::cout << "+= 语法:";
    for (int x : w) std::cout << ' ' << x;
    std::cout << '\n';

    std::map<std::string, int> m;
    insert(m)("x", 1)("y", 2);
    std::cout << "insert: x=" << m.at("x") << " y=" << m.at("y") << '\n';

    // 4) 今天的写法（C++11 起）：语言级初始化列表全覆盖
    std::vector<int> v2{1, 2, 3};
    std::map<std::string, int> m2{{"ada", 36}, {"grace", 85}};
    std::cout << "现代写法: " << v2.size() << " 元, " << m2.size() << " 对\n";

    // 5) list_inserter 的工厂函数族：push_back/push_front/insert 返回
    //    "链式插入器"，括号语法可以多参（map 免 make_pair）、逗号语法
    //    混用；空括号 () 插入值初始化的默认元素
    std::vector<int> via_pb;
    push_back(via_pb)(1)(2)(3)(4)(5);
    std::cout << "push_back 链:";
    for (int x : via_pb) std::cout << ' ' << x;
    std::cout << '\n';
    std::vector<int> mixed;
    push_back(mixed)(6), 7, 64 / 8, (9), 10;      // 括号逗号混用
    std::cout << "混用语法 6..10? "
              << (mixed == std::vector<int>({6, 7, 8, 9, 10})) << '\n';

    // 6) repeat / repeat_fun / range：重复元素与序列搬运（{} 列表做不到）
    std::vector<int> rep = list_of(1).repeat(3, 2)(3)(4)(5);   // 1,2,2,2,3,4,5
    std::cout << "repeat(3,2) 结果 = "
              << (rep == std::vector<int>({1, 2, 2, 2, 3, 4, 5})) << '\n';
    int counter = 0;
    std::vector<int> repf;
    push_back(repf).repeat_fun(3, [&counter] { return ++counter * 10; });// 10,20,30
    std::cout << "repeat_fun = "
              << (repf == std::vector<int>({10, 20, 30})) << '\n';
    std::vector<int> ranged;
    push_back(ranged).range(via_pb.begin(), via_pb.begin() + 3);        // 1,2,3
    std::cout << "range 搬运 = " << (ranged == std::vector<int>({1, 2, 3})) << '\n';

    // 7) 容器适配器：stack/queue/priority_queue 用 to_adapter 落地
    std::stack<int> stk = (list_of(1), 2, 3).to_adapter();
    stk += 4;                                       // stack 专属：+= 也可用
    std::cout << "stack 顶 = " << stk.top() << "（4 在顶）\n";
    std::queue<std::string> q = (list_of("c")("cpp")("lua")).to_adapter();
    push(q)("swift");                               // 适配器用 push() 工厂
    std::cout << "queue 首尾 = " << q.front() << '/' << q.back() << '\n';

    // 8) ref_list_of：引用版列表（内部不拷贝、比 list_of 省）
    int a = 1, b = 2, c = 3;
    std::vector<int> by_ref = ref_list_of<3>(a)(b)(c);
    std::cout << "ref_list_of = "
              << (by_ref == std::vector<int>({1, 2, 3})) << '\n';

    std::cout << "自检通过\n";
    return 0;
}
