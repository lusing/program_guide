# 16 · 继承与多态：同一接口，多种实现

> 对应示例：`examples/16_inheritance/`

## 16.1 抽象基类：纯虚函数定契约

```cpp
class Shape {
public:
    explicit Shape(std::string name) : name_{std::move(name)} {}
    virtual ~Shape() = default;  // 虚析构：多态删除的生死线

    const std::string& name() const { return name_; }
    virtual double area() const = 0;  // 纯虚：本类不能实例化
    virtual void describe() const {   // 虚：子类可覆写
        std::println("{}：面积 {:.2f}", name_, area());
    }

private:
    std::string name_;
};

class Circle : public Shape {
public:
    explicit Circle(double r) : Shape{"圆"}, r_{r} {}
    double area() const override {  // override：拼错会编译报错
        return std::numbers::pi * r_ * r_;
    }
private:
    double r_;
};
```

继承三件套逐个看：**`virtual`** 标记"此函数允许子类覆写、通过基类引用调用时按实际类型分派”；**`= 0`（纯虚）**表示"子类必须实现”——含纯虚函数的类是**抽象类**，不能实例化，只当契约（"是 Shape 就必须会说 area"）。**`override`**（C++11）声明"我在覆写基类的虚函数”——拼错函数名、签名对不上时直接编译错（没有它就是"悄悄定义了个新函数”，基类版本照跑，bug 静默）。**新代码每个覆写都写 override**，零成本保险。

构造链：子类构造先调基类构造（`Shape{"圆"}` 写在初始化列表），销毁反之。基类有的能力（name）子类直接继承，不用重写。

## 16.2 虚析构：多态删除的生死线

```cpp
virtual ~Shape() = default;
```

这一行是**有继承就必须有**的铁律。没有它：`std::unique_ptr<Shape> p = make_unique<Circle>(1.0);` 析构 p 时**只跑 Shape 的析构**，Circle 新增成员（如未来的缓冲区）无人清理——未定义行为。有了虚析构，析构按实际类型（Circle）走，链条完整。规则简化版：**类里出现第一个 virtual 函数的那一刻，析构就必须 virtual**；反过来，不打算被继承的类不用写（std::string 就没有虚函数）。

## 16.3 动态分派：虚表心智模型

```cpp
std::vector<std::unique_ptr<Shape>> shapes;
shapes.push_back(std::make_unique<Circle>(1.0));
shapes.push_back(std::make_unique<Rect>(3.0, 4.0));
for (const auto& s : shapes) {
    s->describe();  // 动态分派：各自版本的 area/describe
}
// 圆：面积 3.14
// （宽 3 高 4）矩形：面积 12.00
```

`s->describe()` 怎么知道调谁？心智模型（不必到汇编）：**每个多态类有一张虚表（vtable，函数指针表），每个对象藏着指向所属类的虚表的指针**。调用虚函数 = 查表跳转。代价因此可量化：每对象多一个指针、每次调用多一次间接跳转（还阻碍内联）。**90% 的场景这点开销无所谓**； hotspot 里逐元素虚调用（如百万次 `shape->area()`）才值得改设计（模板/variant）。

Rect::describe 展示了**覆写中复用基类**的姿势：先做自己的事，再显式 `Shape::describe()` 调基类版本（加类名限定，否则无限递归）。

## 16.4 dynamic_cast：带检查的下转

```cpp
Rect* rect = dynamic_cast<Rect*>(shapes[1].get());
if (rect != nullptr) {
    std::println("确实是个矩形");
}
```

从 `Shape*` 转 `Rect*`（下转）用 `dynamic_cast`：运行期检查实际类型，失败给 nullptr。引用版本失败抛 bad_cast（引用没有"空"）。**需要 dynamic_cast 常常是设计味道**——你把本该在子类里的逻辑放到了外面；先想"这个行为该不该是 Shape 的虚函数"。它真正的正当场景：插件系统、老代码适配、调试打印。频率参考：健康代码库里 dynamic_cast 出现次数应接近个位数。

## 16.5 切片：按值收基类的静默事故

```cpp
Dog dog;
Animal& ref = dog;
Animal sliced = dog;  // 拷贝了 Animal 子对象，Dog 部分被丢掉
std::println("引用说话：{}", ref.speak());     // 汪！（动态类型是 Dog）
std::println("切片说话：{}", sliced.speak());  // ……（静态类型 Animal 的版本）
```

同一个 dog，经引用和经拷贝判若两狗：引用保留完整身份（动态分派到 Dog）；**按值拷贝进基类变量时只复制基类部分，Dog 的成员和虚表被削掉**——这就是对象切片（slicing）。事故高发位：`void feed(Animal a)`（该写 `const Animal&`）、`vector<Animal>` 装子类（该写 `vector<unique_ptr<Animal>>`）。一句话纪律：**多态对象一律经指针或引用流转**。

## 16.6 组合优于继承

```cpp
struct Style {
    std::string color = "#333333";
};
Style st;
std::println("样式颜色 {}（组合：成员即能力，不需要继承）", st.color);
```

继承表达"**是一个**"（Circle 是 Shape）；组合表达"**有一个**"（Shape 有一份名字）。新人最爱犯的错是拿继承当代码复用工具——"Rect 想用 Style 的功能就继承 Style"——耦合了类型层次，改一处抖全身。判断口诀：

- 回答"X 是 Y 吗"自然吗？→ 继承；
- 只是"X 想用 Y 的功能"？→ 组合（成员）/ 模板参数（第 13 章）/ 自由函数。

现代 C++ 的风向：继承面收窄（接口 + 少量框架钩子），**能力靠组合与模板**注入——标准库几乎全部走组合/模板路线（vector 不继承任何东西）。

## 16.7 坑位清单

1. **忘虚析构**：基类指针删除派生对象→UB。见 16.2，铁律。
2. **基类构造函数里调虚函数**：此刻派生部分尚未构造，虚分派只到基类版本——行为反直觉。构造/析构里只调非虚函数（或明确标注的钩子）。
3. **覆写没写 override**：签名手滑（const 漏了、参数类型变了）→ 变成新函数，基类版本照跑。每个覆写必写 override。
4. **public 继承里隐藏基类非虚函数**：子类定义同名函数会**隐藏**基类所有重载（连参数不同的也藏）——非虚函数就不要在子类重定义。
5. **切片**：值传参/值容器装多态对象。多态走指针/引用（16.5）。
6. **深层继承链**：超过 2 层基本都在还债。出现第 3 层时重新审视——多半该拆组合。
7. **在基类里存派生类指针反向引用**："基类知道自己被谁继承"是层次颠倒的味道，说明该分家了。
