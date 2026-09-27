#include <print>
#include <string>
#include <vector>

// 05 指针与引用：地址、解引用与 new/delete

struct Session {
    std::string name;
};

// ═══ 5.7 引用与指针的分工：函数参数 ═══
void via_pointer(int* p, int* q) {
    if (p != nullptr) {   // 指针要判空——它可能什么都不指
        *p += 1;
    }
    (void)q;              // 本例不用 q，标明是刻意保留
}
void via_reference(int& r) {
    r += 1;               // 引用不用判空——它必然绑定着对象
}

int main() {
    // ═══ 5.1 指针 = 存地址的变量：& 取地址，* 解引用 ═══
    int count{42};
    int* pcount{&count};          // “pointer to int”：只能存 int 的地址
    *pcount = 7;                  // 解引用：改的就是 count 本尊
    std::println("count = {}", count);

    int* pnull{nullptr};          // “什么都不指”的固定写法
    std::println("空指针？{}", pnull == nullptr);

    // 所有指针一样宽（存的是地址，与指向类型无关）
    std::println("sizeof: double {} 字节，但 double* 与 char* 都是 {} / {} 字节",
                 sizeof(double), sizeof(double*), sizeof(char*));

    // ═══ 5.2 指针的 const 组合：右到左读 ═══
    int value{10};
    const int* ptr_to_const{&value};   // 指向常量的指针：*ptr_to_const 只读
    int* const const_ptr{&value};      // 常量指针：只能指着 value，不能换目标
    // *ptr_to_const = 11;              // 编译错：经它改数据不许
    *const_ptr = 11;                   // 可以：数据不是 const，指针才是
    std::println("*ptr_to_const 读到 {}，*const_ptr 改成 {}", *ptr_to_const, *const_ptr);
    int other{99};
    ptr_to_const = &other;             // 可以：换目标
    // const_ptr = &other;             // 编译错：常量指针不许换目标
    std::println("ptr_to_const 换目标后读到 {}", *ptr_to_const);

    // ═══ 5.3 指针与数组：数组名会退化成首元素指针 ═══
    int data[5]{2, 4, 6, 8, 10};
    int* p{data};                      // 等价 &data[0]
    std::println("p[2] = {}，*(p + 2) = {}，*data = {}", p[2], *(p + 2), *data);
    ++p;                               // 指针算术按元素宽度跳：前进 4 字节
    std::println("++p 后 *p = {}（第二个元素）", *p);
    std::println("*p + 1 = {}（先解引用再加 1，不是移动指针）", *p + 1);
    int* p1{&data[4]};
    int* p2{&data[1]};
    std::println("指针差 p1 - p2 = {} 个元素（不是字节数）", p1 - p2);

    // ═══ 5.4 对象指针用 -> 访问成员 ═══
    Session s{"登录"};
    Session* ps{&s};
    std::println("会话名：{}", ps->name);        // 等价 (*ps).name，括号不能省
    std::vector<int> v{1, 2, 3};
    std::vector<int>* pv{&v};
    pv->push_back(4);                            // 指针调成员函数同样用 ->
    std::println("容器经指针 push_back 后 size = {}", pv->size());

    // ═══ 5.5 堆与 new/delete：对象活得比作用域久 ═══
    double* pd{new double{3.14}};                // 在自由存储上造一个 double
    std::println("堆上的 double = {}", *pd);
    delete pd;                                   // 用完必须还；delete nullptr 无害
    pd = nullptr;                                // 还完置空——防悬垂的基本纪律

    int* arr{new int[4]{1, 2, 3, 4}};            // 动态数组：长度可以运行期才定
    arr[0] = 100;                                // 下标照常可用
    std::println("动态数组首元素 = {}，sizeof(指针) = {}（数组长度不进指针）",
                 arr[0], sizeof(arr));
    delete[] arr;                                // new[] 配 delete[]——配错是未定义行为
    arr = nullptr;

    // ═══ 5.6 引用：必然绑定、永不换绑的别名 ═══
    int n{5};
    int& ref{n};        // 引用从出生起就是 n 的别名
    ref = 8;            // 不是“让 ref 改指别人”，是给 n 赋 8
    int m{20};
    ref = m;            // 仍然是给 n 赋值（n 变 20）——引用不能换绑
    std::println("n = {}, m = {}", n, m);

    via_pointer(&n, nullptr);    // 指针：调用方看得见“传的是地址”
    via_reference(n);            // 引用：调用点与按值传参长一样
    std::println("经函数修改后 n = {}", n);

    std::println("自检通过");
}
