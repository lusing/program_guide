// 10 · 错误处理 II：nothrow、Nullable、契约式编程
import std.stdio, std.exception, std.typecons, std.conv,
       std.math : isNaN;

// ── nothrow：编译器保证"这个函数不会抛" ─────────────────────
nothrow double safeRatio(double a, double b) {
    return b == 0 ? double.nan : a / b;      // 要是在这里 to!int 抛异常 → 编译错
}

// ── Nullable!T：可能没有值的"半类型" ───────────────────────
Nullable!long findUserId(string[] names, string target) {
    foreach (i, n; names)
        if (n == target)
            return nullable(cast(long)i);    // 有值：包一层
    return Nullable!long();                  // 无值：默认构造 = null
}

// ── 契约：in / out / invariant ──────────────────────────────
// 表达式式：最紧凑
int clampPos(int x)
    in (x > -100, "输入不能小于 -100")              // 入口契约
    out (r; r >= 0 && r <= 1000, "输出必须在 [0, 1000]")  // 出口契约（可引用返回值 r）
{
    return x < 0 ? 0 : (x > 1000 ? 1000 : x);
}

// 块式：契约复杂时用
int divide(int a, int b)
    in {
        assert(b != 0, "除数不能为 0");
        assert(a >= int.min / 2 && b >= int.min / 2, "防溢出");
    }
    out (r) {
        assert(b * r <= a, "商乘除数不能超过被除数");
    }
do {
    return a / b;
}

// invariant：类的每个 public 方法进出时自动检查（对象必须自洽）
class BankAccount {
private:
    long balance_;
    invariant() {                              // 类不变式
        assert(balance_ >= 0, "余额不能为负");
    }
public:
    this(long init) { balance_ = init; }
    long balance() const { return balance_; }
    void withdraw(long amount) {
        assert(amount > 0);                    // 这是普通断言，不是契约
        balance_ -= amount;                    // 若结果 < 0，invariant 在方法出口报错
    }
    void deposit(long amount) { balance_ += amount; }
}

void main() {
    // nothrow
    writeln(safeRatio(10, 4), " ", safeRatio(1, 0).isNaN);

    // Nullable
    auto names = ["Alice", "Bob", "Carol"];
    auto found = findUserId(names, "Bob");
    auto missing = findUserId(names, "Dave");
    writeln("Bob 的 id：", found.get);                  // 1
    writeln("Dave 存在？", !missing.isNull);            // false
    writeln("Dave 默认 -1：", missing.get(-1));         // 带默认值取值
    // Nullable 参与 AA / 函数传参都安全——比"魔数 -1 表示没有"诚实

    // 契约
    writeln(clampPos(500), " ", divide(-9, 3));

    // invariant 演示：透支会在方法出口被抓住
    auto acc = new BankAccount(100);
    acc.deposit(50);
    writeln("余额：", acc.balance());
    try {
        acc.withdraw(999);        // balance 将变 -849 → invariant 抛 AssertError
    } catch (Error e) {
        writeln("invariant 抓到：", e.msg);
    }

    // 错误分类速查（注释形式给读者）：
    // - Exception：可恢复，程序应能 catch 后继续 → 业务错误用它
    // - Error：不可恢复（断言/契约/RangeError）→ 让它崩，别 catch Error
    // - assert：开发期检查，-release 编译会被剥离（契约同理）
}

unittest {
    assert(safeRatio(0, 5) == 0);
    assertThrown!ConvException("abc".to!int);       // ConvException 也是 Exception

    auto n = findUserId(["x"], "x");
    assert(!n.isNull && n == 0);
    assert(findUserId(["x"], "y").isNull);

    assert(clampPos(2000) == 1000);
    assertThrown!Error(clampPos(-200));             // 契约违反抛的是 AssertError（Error 的子类）
    assertThrown!Error(divide(1, 0));
}
