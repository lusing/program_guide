# 07 · 结构体

> 对应示例：`examples/07_structs/`

## 7.1 值语义：struct 的灵魂

```d
struct Timer {
    string label;
    static int alive;              // static：所有实例共享

    this(string label) {           // 构造器（写任何 this(...) 会隐藏默认构造）
        this.label = label;
        alive++;
    }
    ~this() { alive--; }           // 析构：作用域结束自动调 → RAII
    void show() const { ... }      // const 方法：承诺不改字段
}
```

struct 赋值 = **逐字段拷贝**；离开作用域自动 `~this()`——这是 D 的 RAII 形态（类比 C++ 析构/Zig defer 手动调）。

## 7.2 控制拷贝：postblit 与拷贝构造

```d
struct Buffer {
    int[] data;
    this(this) { data = data.dup; }            // 老机制：postblit（拷贝完修补）
}
struct Buffer2 {
    int[] data;
    this(ref return scope const Buffer2 src) { // 新机制：拷贝构造
        data = src.data.dup;
    }
}
```

默认拷贝是**浅拷贝**——内部有切片/指针时，拷出来的两个对象共享底层。两种深拷贝方案：

| | postblit `this(this)` | 拷贝构造 `this(ref ... const S)` |
|---|---|---|
| 时机 | 拷贝完成后修补 | 拷贝时接管 |
| 现状 | 仍可用 | 新代码推荐 |
| 共存 | 二选一，别同时写 | 同左 |

**移动**（`move(x)`）不触发拷贝钩子——所有权转移，源对象作废。

## 7.3 运算符重载：模板化的 opXXX

```d
struct Vec3 {
    double x, y, z;

    Vec3 opBinary(string op)(Vec3 rhs) const {        // 一网打尽 + - *
        static if (op == "+") return Vec3(x + rhs.x, y + rhs.y, z + rhs.z);
        else static if (op == "-") return Vec3(x - rhs.x, y - rhs.y, z - rhs.z);
        else static assert(0, "不支持的运算符 " ~ op);
    }

    Vec3 opBinary(string op : "*")(double k) const { ... }   // 特化某运算符：v * 2
    double opBinaryRight(string op : "*")(double k) const { ... }   // 2 * v（右操作数版）
    Vec3 opUnary(string op : "-")() const { ... }     // -v
    bool opEquals(const Vec3 o) const { ... }         // ==
    int opCmp(const Vec3 o) const { ... }             // < <= > >=（给排序/A A 键用）
    string toString() const { ... }                   // writeln 直接打
}
```

对比 C++：**一个模板函数管一族运算符**（`opBinary!"+"`、`opBinary!"*"` 是同一模板的实例），而不是每个运算符一个函数；`opCmp` 一个函数生成全部比较（三态返回）。

## 7.4 struct vs class：怎么选

| | struct | class |
|---|---|---|
| 语义 | 值（拷贝传递） | 引用（传指针） |
| 存储 | 栈/内嵌/值语义 | GC 堆（`new`） |
| 析构 | 确定性（作用域结束） | GC 决定（别依赖） |
| 继承 | 无 | 有（08 章） |
| 用途 | 小数据/RAII/POD/数学类型 | 多态/对象图/运行时接口 |

**默认选 struct**——需要多态或复杂对象所有权才上 class。

## 7.5 其他零件

```d
struct Point { int x, y; }
Point p = { x: 1, y: 2 };           // 字段名初始化字面量
Point q = Point(1, 2);              // 位置初始化（更常用）

struct Inner {
    int helper() { return 1; }      // 方法、static 成员、嵌套 struct 都可以
    struct Nested { int z; }
}
```

struct 里还能有 `invariant()`（10 章）、`unittest`（23 章）——D 的类型是"自带说明书"的。

## 7.6 坑位清单

1. **opEquals/opCmp 别用 `ref` 参数**：`bool opEquals(ref const Vec3 o)` 接不了右值（`v == Vec3(1,2,3)` 编译错）——按值传 `const Vec3 o` 即可。class 的 opEquals 例外：参数必须是 `Object`（08 章）。
2. **写了有参构造器会隐藏默认构造**：`this(string)` 之后 `Timer()` 不可用——需要无参场景加 `this() {}`。
3. `static if` 里 `static assert(0, ...)` 报"不支持的运算符"比让编译器吐一堆实例化错误友好。
4. struct 太大时值拷贝有成本——传参用 `const ref`（`in` 也行，05 章）。
5. `toString()` 是 D 的打印协议：writeln/format 发现它就调用——返回 `string`，别写成 `const char*`。
6. postblit 在 `-w` 下未弃用（2.113 实测），但新代码建议直接写拷贝构造——未来版本可能弃用 postblit。

---
