# 08 · 类与 RAII：C++ 资源管理的灵魂

> 对应示例：`examples/08_classes/`

## 8.1 从 struct 到 class：封装

```cpp
class Vec2 {
public:
    Vec2(double x, double y) : x_{x}, y_{y} {}

    double x() const { return x_; }
    // ……
private:
    double x_;
    double y_;
};
```

struct 是"裸数据包"，class 是"数据 + 行为 + 访问控制"。`public:` 之下是接口（外界能用什么），`private:` 之下是实现（外界碰不到）——**封装的目的不是保密，是缩小"改坏了会炸"的面积**：私有成员随便重构，公有接口动之前先想想调用方。

构造函数与**成员初始化列表**（`: x_{x}, y_{y}`）：成员在进入函数体之前就地初始化，比函数体内赋值高效（少了"先默认构造再赋值"一步）。习惯从命名上区分成员与参数：本教程成员带下划线尾（`x_`）。成员声明顺序与初始化列表顺序不一致时，**按声明顺序**初始化（/W4 的 C5038 会提醒），列表顺序照着声明写就永远不踩。

## 8.2 const 成员函数：只读接口

```cpp
double x() const { return x_; }
double length() const { return std::sqrt(x_ * x_ + y_ * y_); }
```

函数签名后缀 `const` = "本函数不修改任何成员"。三个理由：**const 对象只能调 const 函数**（没有它，拿到 const Vec2& 的代码就废了）；**能 const 就 const** 让编译器替你抓"意外修改"；文档价值——读签名就知道这个调用无副作用。getter 一律 const，计算属性（length）也是 const。

## 8.3 RAII：资源获取即初始化

```cpp
class Session {
public:
    explicit Session(std::string name) : name_{std::move(name)} {
        std::println("[{}] 进入会话", name_);
    }
    ~Session() {  // 作用域结束自动调用——异常也拦不住它
        std::println("[{}] 离开会话", name_);
    }
    Session(const Session&) = delete;
    Session& operator=(const Session&) = delete;

private:
    std::string name_;
};
// ……
{
    Session s1{"外层"};
    {
        Session s2{"内层"};
        std::println("  工作中……");
    }  // s2 先析构：[内层] 离开会话
}  // s1 后析构：[外层] 离开会话
```

**RAII（Resource Acquisition Is Initialization）是全教程最重要的一节**。规则一句话：**把资源（内存、文件、锁、连接）的生死绑给一个栈对象的生死**——构造函数获取，析构函数归还。收益在于析构的触发是**语言保证**，三种退出路径一个不漏：

| 退出方式 | 手工管理（fopen/fclose） | RAII |
|---|---|---|
| 正常 return | 要记得写 fclose | 析构自动跑 |
| 提前 break/continue | 容易漏 | 析构自动跑 |
| **异常抛出** | 直接漏（泄漏） | **栈展开时析构照跑** |

析构顺序与构造严格**逆序**（示例输出可见 s2 先走）。GC 语言靠 finally/using/defer 补课，C++ 把它做进了对象模型——**C++ 程序员从不手写 cleanup**，只定义"谁拥有资源"。vector、string、智能指针（第 09 章）、lock_guard（第 19 章）全是 RAII 的实例，你已经在不知情地用了两章。

`explicit` 关键字顺手记：禁掉"单参构造函数被用作隐式转换"（`Session s = "名字";` 这种诡异写法编译不过）。单参构造默认都该标。

## 8.4 运算符重载：让类像内建类型

```cpp
Vec2 operator+(const Vec2& rhs) const { return {x_ + rhs.x_, y_ + rhs.y_}; }
Vec2 operator*(double k) const { return {x_ * k, y_ * k}; }
// ……
Vec2 c = a + b;       // (4, 5)
Vec2 d = c * 2;
```

运算符就是名字特殊的成员函数（`a + b` 即 `a.operator+(b)`）。**该不该重载的判据：类的数学语义是否自然**——向量加、复数乘、金额比较：重载让代码更像数学；字符串做"减法"、列表做"与"：别，起个有名函数。返回 const 值、参数 const 引用、自身 const——三个 const 一颗不缺，这套签名形状可以直接抄。

## 8.5 三路比较 `<=>`（C++20）

```cpp
bool operator==(const Vec2&) const = default;  // C++20：默认相等

std::partial_ordering operator<=>(const Vec2& o) const {
    if (auto c = x_ <=> o.x_; c != 0) {
        return c;
    }
    return y_ <=> o.y_;
}
// ……
std::println("a == b? {}", a == b);
std::println("a > b? {}", (a <=> b) > 0);
```

C++20 之前，给类型配全六个比较运算符要写六遍。现在**一个 `<=>`（三路比较/spaceship）+ 一个 `==` 就全有了**：编译器从 `<=>` 合成 <、<=、>、>=，从 `==` 合成 !=。简单情况 `= default` 全自动；需要自定义字典序（先比 x 再比 y）就手写如上。

返回类型分三档：`strong_ordering`（整数：全序且可替换）、`partial_ordering`（浮点：**NaN 不可比**）、`weak_ordering`（可比较但不可替换，如大小写不敏感字符串）。double 成员就返回 partial——本例如此。`a <=> b` 与 0 比较（`(a <=> b) > 0` 即 a > b）。

## 8.6 拷贝控制与 rule of zero/five

Session 里两行 `= delete` 删掉了拷贝——这牵出 C++ 最著名的规则。**五个特殊成员函数**：析构、拷贝构造、拷贝赋值、移动构造、移动赋值（后两个第 15 章才动手）。

- **rule of five**：你要亲手写其中任何一个（通常因为管理资源），就该考虑五个全写。
- **rule of zero（首选）**：**一个都不写**——让成员自己管自己（string 管、vector 管、智能指针管），类就没有资源要管。本教程 95% 的类都该走这条。

`= delete` 是显式禁用（拷贝对"会话"这种独占语义没意义）；`~Session()` 手写是因为要在析构时打印。两者都是"打破 zero"的理由，但注意 Session 并没有裸资源——它示范的是"析构即钩子"。

## 8.7 inline 静态成员

```cpp
class Counter {
public:
    static int next() { return ++count_; }

private:
    inline static int count_ = 0;  // C++17 起：不再需要类外定义
};
```

`static` 成员属于类不属于对象（所有实例共享一份）。C++17 之前 static 成员要在 .cpp 里再定义一次（`int Counter::count_ = 0;`），`inline static`（C++17）允许类内直接初始化——头文件里的类终于自包含了。

## 8.8 deducing this 一瞥（C++23）

```cpp
Vec2& negate(this Vec2& self) {
    self.x_ = -self.x_;
    self.y_ = -self.y_;
    return self;
}
```

C++23 允许把隐式的 `this` 写成**显式首个形参**（`this Vec2& self`），函数体内用 self 而不是裸成员。日常价值：`const`/非`const` 两个重载合并成一个模板、链式调用的写法更顺。目前见个脸熟即可，存量代码里罕见。

## 8.9 坑位清单

1. **忘虚析构**：基类指针 delete 派生类对象时，析构不是虚的→只析构基类部分（UB）。有多态就 `virtual ~Base() = default;`——第 16 章正面展开。
2. **构造函数里调虚函数**：此时对象还是基类（派生部分未构造），虚分派打不到子类版本。构造/析构中只调非虚函数。
3. **成员初始化顺序按声明走**：列表里写得再花哨，实际按**类内声明顺序**初始化；依赖另一成员初始化时顺序错了就是读未初始化。
4. **实参求值顺序未指定**：示例 `Counter::next()` 连打三次，MSVC/GCC 从右往左求值输出 `3 2 1`，clang 从左往右输出 `1 2 3`——多个带副作用的实参别指望从左到右，拆成多行。**这个示例是故意这么写的**（用来演示这条坑），所以跨编译器校验脚本把它登记成"已知差异"，输出不同不算错。
5. **类里放裸资源**：`class File { FILE* f_; }` 然后手写 open/close——直接用 RAII 库类型（fstream、智能指针），rule of zero。
6. **大对象按值传参**：`void f(Vec2 v)` 拷贝一份。小数学类型按值无妨；带 string/vector 的类一律 `const T&`。
