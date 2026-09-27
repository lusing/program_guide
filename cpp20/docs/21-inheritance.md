# 21 · 继承：派生类的构造、访问与切片

> 对应示例：`examples/21_inheritance/`

继承解决"**is-a**"：`Carton` 是一种 `Box`——派生类自动拥有基类的全部成员，再加自己的。它是第 22 章多态的地基，但即使永远不写 `virtual`，构造链/访问控制/切片这三件事也必须门儿清。

## 21.1 派生类与 is-a 测试

```cpp
class Carton : public Box {          // Carton 是一种 Box
    // 新增成员：material_
};
```

用之前先过 **is-a 测试**：任何派生类对象都"是"基类对象（狗是动物 ✔）。过不了就别继承——`Table` 和 `Dog` 都有四条腿，但桌子不是狗。替代关系是 **has-a（组合）**：汽车*有一个*引擎——把 Engine 做成成员变量（第 22 章末尾"组合优于继承"正面讲）。is-a 也要复核：基类能断言的事对派生类必须全部成立（"鸵鸟是鸟"遇上"鸟会飞"就是坏基类——把"会飞"下放到 FlyingBird）。

## 21.2 访问控制：public / protected / private

| 基类成员 | 类外 | 派生类内 | 备注 |
|---|---|---|---|
| `public` | ✅ | ✅ | 接口 |
| `protected` | ❌ | ✅ | "只对子孙开放" |
| `private` | ❌ | **❌** | 继承了 ≠ 访问得到 |

**基类的 private 成员派生类也看不见**——它们被继承（占内存、随构造）但不对你开放。protected 是为此发明的中间档，但**成员变量原则上仍该 private**（protected 变量 = "缩水的 public"：派生类一多，基类改实现照样牵一发动全身）——本教程示例偶尔用 protected 是为了教学直白。派生类写法里的 `public`（`class Carton : public Box`）叫**基类访问说明符**，决定继承来的成员在派生类里的对外可见性：默认是 private（struct 是 public）——**永远显式写 `public`**，另外两种（protected/private 继承）在真实代码里凤毛麟角，认得即可。

## 21.3 构造链：基类先建，派生类后建

```cpp
Carton(double l, double w, double h, std::string material)
    : Box{l, w, h}, material_{std::move(material)} {}    // 初始化列表转发给基类
```

每个派生类构造函数**第一件事都是先调基类构造函数**（多层继承一路向上到根基类，再逐层回来）。两条规则：

- **想在初始化列表里初始化基类成员？不行**——`m_length` 是 Box 的，只能经 Box 的构造函数转交（列表里写 `Box{l,w,h}`，不是拆开写三个成员）；
- 不显式转发就调基类**默认构造函数**——示例输出第 1 段可见 `Carton("纸板")` 版先打 `Box()`（1×1×1）再进派生构造。

**拷贝构造是重灾区**：

```cpp
Carton(const Carton& other) : Box{other}, material_{other.material_} {}   // ✔
// Carton(const Carton& other) : material_{other.material_} {}            // ✘ 静默 bug
```

漏写 `Box{other}` 也能编译！但基类部分走的是**默认构造**——拷出来的纸箱长宽高全变 1（示例第 3 段的输出就是"写了正确版"的证据：先 `Box(copy)` 再 `Carton(copy)`，体积 21.6 而不是 1）。**派生类拷贝构造必须显式把整个 `*this` 的基类子对象交给基类拷贝构造**（`Box{other}` 里 other 自动切片成 Box&，第 21.6 节的"好切片"）。

析构严格反向：**先 ~Carton 后 ~Box**（示例输出末尾成对出现）——对象先拆自己的部分，再拆基类部分。`using Box::Box;` 可直接**继承基类构造函数**（编译器生成"同参转发"版）；`using Box::volume;` 在类内还能调整被继承成员的可见性——多继承消歧义时它是正解（21.5）。

## 21.4 同名遮蔽：Base:: 前缀穿透

```cpp
class Carton : public Box {
    double volume() const { return 0.9 * Box::volume(); }   // 派生版
};
big.volume();          // 21.6 —— 派生版（静态类型是 Carton）
big.Box::volume();     // 24   —— 限定调用基类版
```

派生类出现同名成员（哪怕签名不同）就**遮蔽**基类的所有同名——想用基类版必须 `Box::` 限定。注意这里**没有多态**：调谁由**静态类型**（变量的声明类型）决定——经 `Box*`/`Box&` 调 `volume()` 永远是 Box 版。想让"经基类引用也调到派生版"？那是 `virtual` 的事，下一章。

## 21.5 多重继承：语法简单，坑在二义性

```cpp
class Tablet : public Powered, public Networked {};   // 两个基类都有 source()
Tablet t;
t.source();                              // ✘ 编译错：二义
using Powered::source;                   // 类内 using 一次指明 → t.source() == "电池"
static_cast<Networked&>(t).source();     // 或引用转换后调用 → "Wi-Fi"
```

多重继承把两个基类的成员都搬进来；两个基类**同名成员**直接二义性编译错。解法：类内 `using` 指明用哪个（推荐——用户不用每次限定），或调用点 `static_cast<基类&>` / `基类::` 限定。菱形继承（同一基类经两条路进来、存两份）用 `virtual` 基类消重——进阶话题，工程上更常见的答案是"能单继承就单继承，能力用组合"。

## 21.6 切片：按值收基类会"削平"派生部分

```cpp
Box sliced = big;      // 只拷贝 Box 子对象
sliced.volume();       // 24 —— 九折算法、material_ 全没了
```

派生对象赋值/拷贝给**基类对象**（不是引用/指针）时，只有基类子对象被拷贝，派生部分被"削掉"（slicing）。它有时是想要的（21.3 拷贝构造转交基类部分），更多时候是静默事故：**函数按值收 `Box`、容器存 `vector<Box>`** 都会把 Carton 削成 Box。**要多态就经指针/引用传**（`Box&`/`Box*`/`unique_ptr<Box>`），切片的实证与"引用不切片"的对照见第 22 章。

## 21.7 坑位清单

1. **拷贝构造漏 `Base{other}`**：基类部分被默认构造——能编译、值全错，最阴险的一个。
2. **初始化列表直接写基类成员**：编译错——成员归基类构造函数管，转交参数而不是越级。
3. **误以为 private 成员"继承即可见"**：占内存但不可访问——要开放给子类用 protected（慎重）或 public 访问器。
4. **同名遮蔽当多态**：非虚函数经基类指针永远调基类版——分派看静态类型（第 22 章 virtual 才动态）。
5. **按值收基类悄悄切片**：参数与容器一律引用/指针/智能指针。
6. **多重继承同名二义**：类内 `using` 指明，或干脆组合。
7. **忘了 `class C : Box` 默认私有继承**：基类 public 成员在 C 里全变 private——永远显式写 `: public`。
