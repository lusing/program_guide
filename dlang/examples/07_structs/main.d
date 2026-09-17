// 07 · 结构体：值语义、RAII 与运算符重载
import std.stdio, std.conv;

// ── 基本结构体：字段 + 方法 + 构造器 ────────────────────────
struct Timer {
    string label;
    static int alive;              // static：所有实例共享

    this(string label) {           // 构造器（有参构造会屏蔽默认 .init 构造）
        this.label = label;
        alive++;
    }

    ~this() {                      // 析构：作用域结束自动调（RAII 的 D 形态）
        alive--;
    }

    void show() const {            // const 方法：承诺不改字段
        writeln("  [", label, "] 存活实例：", alive);
    }
}

// ── 值语义 + 深拷贝：postblit 与拷贝构造 ─────────────────────
struct Buffer {
    int[] data;

    this(this) {                   // postblit：拷贝后修补（老机制，仍在用）
        data = data.dup;           // 默认浅拷贝后，把引用字段换成独立副本
    }
}

struct Buffer2 {
    int[] data;
    // 新式拷贝构造（与 postblit 二选一，别同时写）
    this(ref return scope const Buffer2 src) {
        data = src.data.dup;
    }
}

// ── 运算符重载：opBinary / opCmp / opEquals ──────────────────
struct Vec3 {
    double x, y, z;

    Vec3 opBinary(string op)(Vec3 rhs) const {    // 一网打尽 + - *
        static if (op == "+") return Vec3(x + rhs.x, y + rhs.y, z + rhs.z);
        else static if (op == "-") return Vec3(x - rhs.x, y - rhs.y, z - rhs.z);
        else static assert(0, "不支持的运算符 " ~ op);
    }

    double opBinaryRight(string op : "*")(double k) const {   // 2 * v
        return k * magnitude();
    }

    Vec3 opBinary(string op : "*")(double k) const {          // v * 2
        return Vec3(x * k, y * k, z * k);
    }

    Vec3 opUnary(string op : "-")() const {                   // -v
        return Vec3(-x, -y, -z);
    }

    double magnitude() const {
        import std.math : sqrt;
        return sqrt(x * x + y * y + z * z);
    }

    bool opEquals(const Vec3 rhs) const {                     // ==（不取 ref：要能接右值）
        return x == rhs.x && y == rhs.y && z == rhs.z;
    }

    int opCmp(const Vec3 rhs) const {                         // < <= > >=（按模长）
        auto a = magnitude(), b = rhs.magnitude();
        return a < b ? -1 : (a > b ? 1 : 0);
    }

    string toString() const { return formatVec(); }
private:
    string formatVec() const { return "(" ~ x.to!string ~ ", " ~ y.to!string ~ ")"; }
}

void main() {
    // RAII：作用域即生命周期（离开 main 前看 alive 计数变化）
    {
        Timer t1 = Timer("外层");
        t1.show();                             // 存活 1
        {
            Timer t2 = Timer("内层");
            t2.show();                         // 存活 2
        }                                      // t2 析构
        t1.show();                             // 存活 1
    }
    writeln("作用域结束，alive = ", Timer.alive);

    // 深拷贝
    auto b1 = Buffer([1, 2, 3]);
    auto b2 = b1;                              // 触发 postblit
    b2.data[0] = 99;
    writeln("b1=", b1.data[0], " b2=", b2.data[0]);   // 1 99
    auto c1 = Buffer2([7, 8]);
    auto c2 = c1;                              // 触发拷贝构造
    c2.data[0] = 0;
    writeln("c1=", c1.data[0]);                // 7

    // 运算符重载
    auto v = Vec3(1, 2, 2), w = Vec3(3, 4, 0);
    auto sum = v + w, diff = w - v, scaled = v * 2;
    writeln("v + w = ", sum);
    writeln("|v| = ", v.magnitude());
    writeln("2 * |v| = ", 2 * v);
    writeln("-v = ", -v);
    writeln("v == Vec3(1,2,2)? ", v == Vec3(1, 2, 2));
    writeln("v < w ? ", v < w);                // 3 < 5

    // 结构体在数组里：元素本身就是值，拷贝数组=拷贝全部
    auto vecs = [v, w];
    auto vecsCopy = vecs;
    writeln("数组长度一致：", vecs.length == vecsCopy.length);
}

unittest {
    auto v = Vec3(1, 2, 2), w = Vec3(3, 4, 0);
    assert(v.magnitude() == 3);
    assert(v + w == Vec3(4, 6, 2));
    assert(v * 2 == Vec3(2, 4, 4));
    assert(v < w && w > v);
    assert((-v).x == -1);

    auto b = Buffer([1]);
    auto b2 = b;
    assert(b.data.ptr !is b2.data.ptr);        // 深拷贝：指针不同

    assert(Timer.alive == 0);                  // 全部析构
}
