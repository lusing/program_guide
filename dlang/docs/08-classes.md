# 08 · 类与接口

> 对应示例：`examples/08_classes/`

## 8.1 引用语义 + GC 堆

```d
class Animal {
protected:
    string name;                              // protected：子类可见
public:
    this(string name) { this.name = name; }   // 构造器
    abstract string speak() const;            // 抽象方法
    string intro() const { return name ~ "：" ~ speak(); }   // 虚函数
    final string tag() const { return "动物"; }              // final：禁覆盖
}

class Dog : Animal {
    this(string name) { super(name); }        // 必须显式调 super 构造
    override string speak() const { return "汪汪"; }
    override string intro() const { return super.intro() ~ "（会看家）"; }
}
```

- class 永远是**引用**：`auto d2 = d1` 拷的是引用，`d1 is d2` 才是同一性判断。
- 所有 class 隐式继承 **Object**——`toString`/`opEquals`/`toHash` 都从这来。
- 覆盖必须写 **`override`**（防手滑拼错函数名）；`abstract`/`final` 和 Java 同义。

## 8.2 接口：可以带 final 默认实现

```d
interface Serializer {
    string dump() const;                            // 抽象：实现类必须给
    final string header() const { return "<data>"; } // 带实现的方法必须 final（坑）
}
```

**接口方法体必须 `final`**——D 接口不是 C++ 的纯抽象类，带实现的成员就是"打包进接口的工具方法"。

## 8.3 Object 三大虚方法

```d
class Point : Serializer {
    int x, y;

    override string toString() const { return "Point(...)"; }

    override bool opEquals(Object o) const {        // 参数类型必须是 Object
        auto p = cast(Point)o;
        return p !is null && x == p.x && y == p.y;
    }

    override size_t toHash() const {
        return cast(size_t)(x * 31 + y);
    }
}
```

铁律：**`a == b` 为真 ⇒ `a.toHash == b.toHash`**——重写 opEquals 必须同时重写 toHash（AA 拿类当键时全靠它）。

## 8.4 类型信息与转型

```d
Animal a = new Dog("旺财");
writeln(typeid(a));                 // main.Dog —— 动态类型（RTTI 内建）

auto maybeCat = cast(Cat)a;         // 向下转型：失败得 null（不抛异常！）
if (maybeCat is null) { ... }       // 用 is null 判失败
```

`cast(子类)` 在 class 上是**带检查的动态转型**（等价 C++ dynamic_cast），失败给 null——这和 struct/数值的 cast（暴力重释）语义不同，注意区分。

## 8.5 多态数组

```d
Animal[] zoo = [new Dog("旺财"), new Cat("咪咪")];
foreach (a; zoo) writeln(a.intro());    // 各自的 speak 被虚分发
```

数组元素是引用——`zoo[0] = new Dog("x")` 只换引用，不动对象。

## 8.6 struct vs class 回顾

详见 07 章对照表。经验法则：

- 生命周期确定/小对象/要 RAII → struct（07 章 Timer）。
- 运行时多态/对象图/跨模块边界 → class。
- 栈上造 class 对象？→ `std.typecons.scoped!T`（15 章，绕过 GC 分配）。

## 8.7 坑位清单

1. **接口带方法体必须 `final`**：裸写 `string name() const { ... }` 编译错（"function body only allowed in final functions in interface"）。
2. **class 的 opEquals 参数必须是 `Object`**（不能用具体类型）——内部自己 `cast` + 判 null；这正是 07 章 struct 按值传参的差别所在。
3. **子类构造器必须显式 `super(...)`**：父类有无参构造时可以省，写了有参构造就不能。
4. `==`（值相等，走 opEquals）与 `is`（同一对象）分清楚：`p1 == p2 && !(p1 is p2)` 完全正常。
5. 默认 `Object.toHash` 按**对象地址**算——不重写 toHash 的类做 AA 键，"值相等"的两个对象哈希不同，查找失败。
6. `typeid(c)` 返回 `TypeInfo_Class`（ClassInfo）——反射元数据在 12 章 `__traits` 那还有一层语言级内省。

---
