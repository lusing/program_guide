# 05 · 函数：程序的乐高积木

> 对应示例：`examples/05_functions/`

## 5.1 值传递：拿到的是副本

```cpp
void double_it(int x) {
    x *= 2;  // 改的是副本，外面看不见
}
```

C++ 参数默认**按值拷贝**——函数拿到的是快照，改了也白改。这不是缺陷而是默认安全：调用方永远不被意外篡改。想要"改得动"或"不想拷贝大对象"，看下两节。

## 5.2 引用传递：真的改原件

```cpp
void double_ref(int& x) {
    x *= 2;
}
// ……
int v = 21;
double_it(v);   // 副本被翻倍，v 纹丝不动
double_ref(v);  // 引用：v 真的变了
std::println("v = {}", v);  // 42
```

`int&` 是**引用**（别名）：函数内对 x 的操作就是对 v 本尊的操作。引用与指针的区别：引用必须绑定、不能换绑、没有"空引用"——比指针安全一档。C++ 没有 C# 的 `ref`/`out` 关键字，引用类型本身就写在签名里，调用方**看调用点分不出**是否引用传递（这是被诟病的可读性弱点，靠命名弥补：`double_ref` 这类名字自带信号）。

## 5.3 const 引用：只读 + 不拷贝

```cpp
int total_length(const std::vector<std::string>& words) {
    int total = 0;
    for (const auto& w : words) {
        total += static_cast<int>(w.size());
    }
    return total;
}
```

`const std::vector<std::string>&` 是**大对象传参的标准姿势**：不拷贝（vector 拷贝是真金白银的内存分配）也不可改。三种传法一张表定终身：

| 签名 | 能改吗 | 拷贝吗 | 用于 |
|---|---|---|---|
| `void f(T x)` | 改副本 | ✅ | 小类型（int/double/指针/span） |
| `void f(T& x)` | ✅ | ❌ | 输出参数、就地修改 |
| `void f(const T& x)` | ❌ | ❌ | **大对象默认**（string/vector/容器） |

判型口诀：**小按值、要改用引用、大用 const 引用**。string 字面量为什么能传给 `const std::string&`？临时 string 会就地构造——合法但有一次隐藏分配，高频接口用 `std::string_view` 更优（第 06 章）。

## 5.4 默认实参与重载

```cpp
void greet(const std::string& name, const std::string& greeting = "你好") {
    std::println("{}，{}！", greeting, name);
}
int twice(int v) { return v * 2; }
double twice(double v) { return v * 2; }  // 重载：同名不同参
// ……
greet("阿 C");            // 你好，阿 C！——用默认问候
greet("World", "Hello");  // Hello，World！——覆盖默认
std::println("{} {}", twice(21), twice(1.5));  // 42 3
```

**默认实参**从右侧连续排列（`f(int a, int b = 1, int c = 2)` 合法，`f(int a = 1, int b)` 非法）——调用只能从右往左省略。**重载**是同名函数按参数类型分派：`twice(21)` 选 int 版、`twice(1.5)` 选 double 版，编译期决定（零运行开销）。重载的边界：只有返回值不同不算重载；两个版本都"够得着"时编译器报二义（如 `twice(3L)` 到底转 int 还是 double）——见坑位。

## 5.5 [[nodiscard]]：返回值不许扔

```cpp
[[nodiscard]] int square(int v) {
    return v * v;
}
```

`square(9);` 不接返回值，/W4 直接警告（C4834）。适用场景：算出来的结果就是函数全部意义（`erase` 返回删除数、`insert` 返回是否成功）。**纯计算函数都值得标**——它把"调了等于没调"的 bug 在编译期揪出来。

## 5.6 lambda：就地写函数对象

```cpp
auto add = [](int a, int b) { return a + b; };
int factor = 3;
auto scale = [factor](int x) { return x * factor; };  // 按值捕获外部变量
std::println("{} {}", add(2, 3), scale(7));  // 5 21
```

`[捕获](参数) { 体 }` 就地定义一个匿名函数对象。捕获是 lambda 与普通函数的本质差异：**它能记住定义处的变量**（`[factor]` 拷走一份快照）。第 11 章会把捕获讲透（值/引用/悬垂陷阱）；这里先建立"就地小函数"的直觉——容器算法（第 11 章）里它无处不在。返回类型自动推导，复杂分枝想写明用 `-> T`。

## 5.7 作用域、声明与前置声明

块作用域 `{}` 圈定变量生死；同名内层遮蔽外层（/W4 的 C4456 会提醒）。函数必须**先声明后使用**——main 在前、被调函数在后时，要么挪顺序，要么在文件头放前置声明 `int twice(int);`（这 就是头文件原理的最小样，第 18 章展开）。多个 .cpp 间共享函数：声明进头文件、实现留在自己的 .cpp。

## 5.8 坑位清单

1. **返回局部变量的引用/指针**：`const T& f() { T local; return local; }`——函数返回局部即销毁，引用悬垂，用到就是 UB。按值返回（有 RVO，第 15 章证明它不亏）。
2. **默认实参写在定义处**：声明与定义分离时默认值只能写在**声明**（头文件）里，两处都写直接编译错。
3. **重载二义**：`f(int)` 与 `f(double)` 并存时传 `3L`/字面量 `3.0f`，两边都要转换→编译器弃疗报 ambiguous。重载族之间留出清晰的无交集区。
4. **lambda 引用捕获悬垂**：`[&x]` 捕的局部变量死了，lambda 还活着（存进了容器/跨线程）→ 调用时 UB。第 11 章展开。
5. **在头文件里定义非 inline 函数**：两个 .cpp 都 include 它→链接期"重定义"错误。头文件里的函数定义要 `inline`（第 18 章）。
6. **参数太多**：超过 4–5 个参数说明该有 struct 了（第 06 章）——参数列表是坏味道探测器。
