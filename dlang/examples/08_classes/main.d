// 08 · 类与接口：引用语义、继承与多态
import std.stdio, std.conv;

// ── 接口：可以带 final 默认实现 ──────────────────────────────
interface Serializer {
    string dump() const;                       // 抽象：实现类必须给
    final string header() const {              // 默认实现必须 final（坑位）
        return "<" ~ kind() ~ ">";
    }
    final string kind() const { return "data"; }
}

// ── 抽象类 vs 接口：抽象类可带状态与构造器 ───────────────────
abstract class Animal {
protected:
    string name;                               // protected：子类可见
public:
    this(string name) { this.name = name; }    // 构造器
    abstract string speak() const;             // 纯虚函数
    string intro() const {                     // 虚函数：子类可覆盖
        return name ~ "：" ~ speak();
    }
    final string tag() const { return "动物"; } // final：禁止覆盖
}

class Dog : Animal {
    this(string name) { super(name); }         // 必须显式调 super 构造
    override string speak() const { return "汪汪"; }
    override string intro() const {            // 覆盖父类行为
        return super.intro() ~ "（会看家）";
    }
}

class Cat : Animal {
    private int meows = 0;
    this(string name) { super(name); }
    override string speak() const { return "喵"; }
    final void meow() { meows++; }             // 实例状态
    int meowCount() const { return meows; }
}

// ── 实现接口的类：Object 是所有类的根 ────────────────────────
class Point : Serializer {
    int x, y;
    this(int x, int y) { this.x = x; this.y = y; }

    override string dump() const { return "Point(" ~ x.to!string ~ ", " ~ y.to!string ~ ")"; }

    // Object 的三大虚方法：toString / opEquals / toHash
    override string toString() const { return dump(); }
    override bool opEquals(Object o) const {           // 参数必须是 Object
        auto p = cast(Point)o;
        return p !is null && x == p.x && y == p.y;
    }
    override size_t toHash() const {
        return cast(size_t)(x * 31 + y);
    }
}

void main() {
    // 多态：基类引用指向子类对象
    Animal[] zoo = [new Dog("旺财"), new Cat("咪咪"), new Dog("来福")];
    foreach (a; zoo) writeln("  ", a.intro());

    // 引用语义：赋值/传参不拷贝对象，只拷贝引用
    auto d1 = new Dog("阿黄");
    auto d2 = d1;                              // 同一个对象！
    writeln(d1 is d2);                         // true：同一性比较用 is

    // typeid：运行时类型信息（RTTI 是内建的）
    writeln(typeid(d1));                       // class Dog
    auto a = cast(Animal)d1;
    writeln(typeid(a));                        // 仍是 Dog（动态类型）

    // 向下转型：cast 失败得 null（引用语义下 cast 是"检查"而非暴力重释）
    auto maybeCat = cast(Cat)zoo[0];
    writeln("狗转猫 = ", maybeCat is null);

    // Object 方法：writeln 直接调 toString
    auto p1 = new Point(1, 2), p2 = new Point(1, 2), p3 = new Point(3, 4);
    writeln(p1, " == ", p2, " ? ", p1 == p2);  // true：值相等（opEquals）
    writeln(p1 is p2);                         // false：不同对象
    writeln("p3 != p1 ? ", p3 != p1);

    // 接口默认方法
    Serializer s = p1;
    writeln(s.header(), s.dump());

    // 类做 AA 键要用 toHash + opEquals（这里用 Point 演示哈希一致性）
    writeln("hash(p1) == hash(p2)? ", p1.toHash == p2.toHash);
}

unittest {
    auto zoo = [new Dog("A"), new Cat("B")];
    assert(typeid(zoo[0]) == typeid(Dog));
    assert(cast(Cat)zoo[0] is null);
    assert(cast(Cat)zoo[1] !is null);

    auto p1 = new Point(1, 2), p2 = new Point(1, 2);
    assert(p1 == p2 && !(p1 is p2));
    assert(p1.toHash == p2.toHash);            // opEquals 相等 → toHash 必须相等

    auto cat = new Cat("咪");
    cat.meow(); cat.meow();
    assert(cat.meowCount == 2);

    Serializer s = p1;
    assert(s.header == "<data>" && s.dump == "Point(1, 2)");
}
