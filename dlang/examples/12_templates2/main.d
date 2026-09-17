// 12 · 模板 II：CTFE、static if、mixin 与编译期反射
import std.stdio, std.conv, std.traits, std.string;

// ── CTFE：普通函数在编译期上下文中自动求值 ──────────────────
// 不需要 constexpr 关键字：用在编译期位置（enum/static assert/模板实参）就是编译期
long factorial(long n) {
    long r = 1;
    foreach (i; 2 .. n + 1) r *= i;
    return r;
}

// 编译期字符串处理（CTFE 不限数字，字符串、数组都行）
string slug(string s) {
    string out_;
    char prev = '_';
    foreach (c; s) {
        if (c >= 'A' && c <= 'Z') {          // 大写 → 前插下划线 + 转小写
            if (prev != '_') out_ ~= '_';
            out_ ~= [cast(char)(c + 32)];
        } else out_ ~= [c];
        prev = c;
    }
    return out_;
}

// ── static if：编译期分支（D 比 C++20 更早的原生条件编译）──
string typeInfoOf(T)() {
    static if (isIntegral!T)        return T.stringof ~ "（整数族）";
    else static if (isFloatingPoint!T) return T.stringof ~ "（浮点族）";
    else static if (is(T == string))    return "string（UTF-8 切片）";
    else                            return T.stringof;
}

// ── string mixin：把"编译期生成的代码"注入程序 ──────────────
string genGetters(names...)() {          // CTFE 生成源码字符串
    string code;
    foreach (n; names) code ~= "int " ~ n ~ "; ";
    return code;
}

// ── template mixin：混入"现成的声明块" ──────────────────────
mixin template Traceable() {             // 混入字段+方法，多个 struct 复用
    string tag;
    void trace() const { writeln("  [trace] ", typeid(typeof(this)), " tag=", tag); }
}

// ── __traits：编译器内省 ────────────────────────────────────
struct Config {
    string host = "localhost";
    int port = 8080;
    mixin(genGetters!"extra");           // string mixin：注入生成出来的字段
    mixin Traceable;                     // template mixin：注入一整块声明
}

void main() {
    // CTFE：enum 右侧、static assert 里都是编译期
    enum f10 = factorial(10);                    // 编译期算好，不占运行时
    static assert(f10 == 3_628_800);
    writeln("20! = ", factorial(20));            // 运行时调用同一个函数也行！
    pragma(msg, "编译期：slug(DLangGuide) = ", slug("DLangGuide"));   // 编译期打印

    // static if 分派
    writeln(typeInfoOf!int, " / ", typeInfoOf!double, " / ", typeInfoOf!string);

    // string mixin 生成的字段就在这
    Config cfg;
    cfg.extra = 5;
    cfg.tag = "server";                          // template mixin 的字段
    writeln("cfg.extra = ", cfg.extra, ", port 默认 = ", cfg.port);
    cfg.trace();

    // __traits 反射：字段名、编译期验证
    foreach (i, member; __traits(allMembers, Config))
        writeln("  成员[", i, "]：", member);
    static assert(__traits(compiles, cfg.extra));       // 能编译过 = true
    static assert(!__traits(compiles, cfg.nope));       // 不存在 = false

    // 组合拳：static foreach + mixin 生成一段 switch（04 章欠的账在这还）
    enum Color { red, green, blue }
    auto pick(Color c) {
        final switch (c) {
            static foreach (m; EnumMembers!Color) {
                case m: return m.to!string;      // return 天然终止，不需要 break
            }
        }
    }
    writeln("颜色名：", pick(Color.green));
}

unittest {
    static assert(factorial(6) == 720);
    static assert(slug("DLangGuide") == "d_lang_guide");
    enum stage = factorial(5);           // enum 变量触发编译期求值
    static assert(stage == 120);

    assert(typeInfoOf!int == "int（整数族）");
    assert(typeInfoOf!string == "string（UTF-8 切片）");

    Config c;
    assert(c.host == "localhost" && c.extra == 0);

    enum Color { red, green, blue }
    // __traits(compiles)：测试"这段代码能不能编译"的探针
    static assert(__traits(compiles, Color.red.to!int));
}
