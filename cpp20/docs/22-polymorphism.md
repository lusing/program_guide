# 22 · 多态：虚函数与动态分派

> 对应示例：`examples/22_polymorphism/`

第 21 章的继承只完成了"复用"；多态才是它的目的：**同一个调用表达式，按对象的实际类型执行不同版本**。"Shape 的容器里混装圆和矩形，`s->describe()` 各画各的"——运行期才知道具体类型的场景（用户点了什么形状、来了什么报文）全靠它。

## 22.1 虚函数与抽象基类

```cpp
class Shape {
public:
    virtual ~Shape() = default;          // 虚析构：多态删除的生死线（22.5）
    virtual double area() const = 0;     // 纯虚：只定契约，本类不能实例化
    virtual void describe() const {      // 虚 + 默认实现：子类可覆写可继承
        std::println("{}：面积 {:.2f}", name_, area());
    }
};
class Circle : public Shape {
public:
    double area() const override { return std::numbers::pi * r_ * r_; }
};
```

`virtual` 告诉编译器：这个调用**运行期按对象的动态类型分派**（dynamic binding），而不是编译期按指针/引用的静态类型钉死（static binding）。`= 0` 的纯虚函数把 Shape 变成**抽象类**——不能造对象，只能当契约；全部纯虚的抽象类就是其他语言的 interface。**`override` 必写**：拼错函数名、漏个 const、签名对不上时它把"静默的新函数 + 静态绑定"变成编译错误（想想没有它的排查成本）。`final` 反向操作：`double area() const override final` 之后不许再覆写；也能封整个类（`class Rect final`）。

多态的入口只有两个：**指针或引用**。`vector<unique_ptr<Shape>>` 统一持有异质对象（示例 22.1——13 章 `vector<unique_ptr<Task>>` 的伏笔在此兑现），`f(const Shape&)` 收任何子类——按值存/传就切片了（22.6）。

## 22.2 绑定实验：什么动态、什么静态

```cpp
Shape& as_shape = *shapes[0];          // 静态类型 Shape&，动态类型 Circle
as_shape.area();      // 动态分派 → Circle::area
as_shape.kind();      // 非虚函数 → 永远 Shape::kind（静态绑定）
unit.kind("x");       // Circle 里声明了 kind(const char*) —— 遮蔽（第 21 章）
unit.Shape::kind();   // Base:: 穿透遮蔽
```

一句话总纲：**虚函数看动态类型（对象是谁），非虚函数/遮蔽看静态类型（引用声明成谁）**。三个推论：经对象直接调用虚函数也是静态绑定（编译器知道确切类型，直接调）；基类成员函数**内部**调虚函数同样动态分派（`describe()` 里的 `area()`——这就是框架代码的原理）；`static` 成员函数永远静态绑定（没有 this，没有动态类型可言）。

## 22.3 默认实参陷阱：实参静态、函数体动态

```cpp
virtual double cost(double unit = 10) const;            // Shape
double cost(double unit = 100) const override;          // Circle（换了默认值）
as_shape.cost();    // 31.42 —— 基类的 10 × Circle 的 area()！
unit.cost();        // 1256.64 —— Circle 的 100 × Circle 的 area()
```

**默认实参是编译期按静态类型填的，函数体是运行期按动态类型跑的**——两者可以来自不同的类！经 `Shape&` 调 `cost()`，默认实参取 Shape 的 10，执行的是 Circle 的函数体。规矩：**虚函数要么不要默认实参，要么全层次写成同一个值**——这条坑的输出证据在示例里（31.42 vs 1256.64）。

## 22.4 RTTI：dynamic_cast 与 typeid

```cpp
if (auto* rect = dynamic_cast<Rect*>(shapes[1].get()); rect != nullptr) { /* 下转成功 */ }
auto* bad = dynamic_cast<Circle*>(shapes[1].get());   // nullptr —— 不是 UB，可判可查
const Shape& first = *shapes[0];
typeid(first) == typeid(Circle);                       // true：认动态类型
```

向上转（派生→基类）永远安全自动；**向下转必须 `dynamic_cast`**——它运行期检查真实类型，失败给指针返 `nullptr`（引用版抛 `bad_cast`），把"猜错类型"从 UB 降级成可判分支。`static_cast` 下转不检查、猜错即 UB——只在你**能证明**类型时用。`typeid` 查询动态类型（要求是多态类型且经引用/指针），`.name()` 的输出是实现定义的乱码，**别写进输出**；工程口诀：**频繁 dynamic_cast 是设计味道**——多数情况该用虚函数让分派自己发生，下转留给"层次外"的收尾场景。

## 22.5 虚析构：多态删除的生死线

```cpp
class Animal {
public:
    virtual ~Animal() { /* … */ }
};
std::unique_ptr<Animal> pet = std::make_unique<Dog>();
// 离开作用域：~Dog() 先跑，~Animal() 后跑 —— 输出里成对出现
```

经基类指针 `delete` 派生对象时，析构函数**不是虚的 → UB**（标准原文：除非基类有虚析构，否则未定义）——典型症状是派生类析构不执行、资源泄漏。铁律：**类只要有任何虚函数（或打算被多态使用），析构就写 `virtual ~T() = default;`**。派生类析构自动是虚的（名字不同也认）；给派生析构标 `override`（`~Dog() override`）还能反过来验证基类析构确实是虚的。示例输出实证：经 `Animal*` 删除 Dog，`~Dog()` 先执行。

## 22.6 切片实证与"引用不切片"

```cpp
Dog dog;
Animal& ref = dog;
Animal sliced = dog;        // 按值拷贝：Dog 部分被削掉
ref.speak();    // 汪！ —— 引用保持动态类型 Dog
sliced.speak(); // …… —— 对象本体已经是纯 Animal
```

第 21 章的切片在多态语境下最扎眼：**引用/指针是多态的门票，按值是切片的刀**。容器存值（`vector<Animal>`）、函数按值收基类，都会把"汪"削成"……"。

## 22.7 组合优于继承

```cpp
struct Style { std::string color = "#333333"; };
Style st;    // 能力 = 成员，不需要继承
```

继承是最强的耦合（基类实现一动全层次震），is-a 测试过不了时用**组合**（has-a）；能过 is-a 但只想要实现复用时，也优先想想组合 + 一小层接口。经验法则：**接口用继承（纯虚基类），实现复用用组合**；真要多态才开 virtual，而且接口窄一点比宽一点好。

## 22.8 坑位清单

1. **忘虚析构**：经基类指针删派生对象是 UB——有虚函数必有 `virtual ~T() = default;`。
2. **漏写 override**：签名差一点就变成"新函数 + 静态绑定"，静默错——每个覆写都标。
3. **虚函数配默认实参**：实参取静态类型版、函数体取动态类型版——全层次同值或不写。
4. **基类构造/析构里调虚函数**：此时动态类型还是基类（子类部分未建/已拆），分派打不到子类版。
5. **按值传基类切片**：多态必须指针/引用；`vector<Shape>` 是经典事故现场。
6. **static_cast 下转猜类型**：不检查、猜错 UB——向下转一律 dynamic_cast。
7. **非虚函数也想"覆写"**：遮蔽 ≠ 覆写，静态绑定照旧——想覆写就加 virtual（基类）+ override（子类）。
8. **重载虚函数遮蔽全家**：派生类写一个同名重载会遮蔽基类全部同名——用 `using Base::f;` 找回来。
