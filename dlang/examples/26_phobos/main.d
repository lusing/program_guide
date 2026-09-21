// 26 · 标准库全景：libphobos（std.*）+ druntime（core.*）功能巡礼
// 每段对应文档 26.3 的一个模块域；unittest 即模块行为说明书
import std.stdio, std.algorithm, std.range, std.array;
import std.meta : AliasSeq, staticMap, Filter;
import std.traits : isNumeric, Unqual, Fields;
import std.typecons : Tuple, tuple, Nullable;
import std.conv : to;
import std.format : format;
import std.sumtype : SumType, match;
import std.bigint : BigInt;
import std.regex : regex, matchFirst;
import std.digest.md : md5Of;
import std.digest : toHexString, LetterCase;
import std.base64 : Base64;
import std.uuid : UUID, randomUUID, parseUUID;
import std.datetime : Date, DateTime;
import core.time : days;
import std.container.rbtree : redBlackTree;
import std.experimental.allocator : make, dispose;
import std.experimental.allocator.mallocator : Mallocator;

// ── 元编程三件套（std.meta / std.traits）：编译期类型列表操作 ──
static assert(Fields!DateTime.length == 2);          // DateTime = Date + TimeOfDay 两个字段
unittest {
    // staticMap：对类型列表逐元变换
    alias Clean = staticMap!(Unqual, const int, immutable string, const double);
    static assert(is(Clean == AliasSeq!(int, string, double)));

    // Filter：按谓词模板过滤
    alias Nums = Filter!(isNumeric, int, string, double);
    static assert(is(Nums == AliasSeq!(int, double)));
}

// ── 类型构造器（std.typecons）：给类型系统"补件" ─────────────
unittest {
    Tuple!(int, "x", int, "y") p = tuple!(int, int)(3, 4);
    assert(p.x == 3 && p[1] == 4);                    // 具名 + 下标双访问
    Nullable!int n;                                    // 可空而不裸指针
    assert(n.isNull);
    n = 42;
    assert(!n.isNull && n.get == 42);
}

// ── 代数数据类型（std.sumtype）：安全的 tagged union ──────────
unittest {
    SumType!(int, string) id;
    id = 7;
    // match：穷举各类型分支取值（漏分支编译错——比裸 union 强的地方）
    assert(id.match!((int x) => x, (string s) => -1) == 7);
    id = "007";
    assert(id.match!((int x) => "", (string s) => s) == "007");
}

// ── 大数与精度（std.bigint）：超出 64 位的整数 ────────────────
unittest {
    BigInt f = 1;
    foreach (i; 2 .. 31) f *= i;                     // 30! 远超 ulong
    assert(f.to!string == "265252859812191058636308480000000");
}

// ── 正则（std.regex）：CTFE 编译正则串，运行时匹配 ────────────
unittest {
    auto m = matchFirst("2026-09-21", regex(r"(\d+)-(\d+)-(\d+)"));
    assert(m.captures[1] == "2026" && m.captures[3] == "21");
    assert(m.captures[0] == "2026-09-21");            // 第 0 组是整匹配
}

// ── 编码与摘要（std.digest / std.base64 / std.uuid）──────────
unittest {
    // toHexString 默认大写；要小写给 LetterCase 模板参（第三个坑见 26.7）
    assert(md5Of("abc").toHexString!(LetterCase.lower) == "900150983cd24fb0d6963f7d28e17f72");
    // 2.113：Base64 的单参便捷版已移除——缓冲区自己开（encodeLength/decodeLength 算长）
    ubyte[] data = [1, 2, 3];
    auto enc = Base64.encode(data, new char[Base64.encodeLength(data.length)]);
    assert(enc == "AQID");
    auto dec = Base64.decode(enc, new ubyte[Base64.decodeLength(enc.length)]);
    assert(dec == [1, 2, 3]);
    auto u = randomUUID();
    assert(parseUUID(u.toString) == u);               // 序列化往返
}

// ── 日期（std.datetime）：Date/DateTime/Duration 类型安全运算 ─
unittest {
    auto d = Date(2026, 9, 21) + 5.days;
    assert(d == Date(2026, 9, 26));                   // 跨月进位自动
    assert(Date(2024, 2, 28) + 1.days == Date(2024, 2, 29)); // 闰年
}

// ── 容器（std.container）：GC 数组之外的正式容器 ──────────────
unittest {
    auto t = redBlackTree(5, 3, 1, 4, 2);
    assert(t.array == [1, 2, 3, 4, 5]);               // 中序 = 有序
    t.removeKey(3);
    assert(3 !in t);
}

// ── 可插拔分配器（std.experimental.allocator）───────────────
unittest {
    auto p = make!int(Mallocator.instance, 42);       // C malloc 上建 int
    assert(*p == 42);
    dispose(Mallocator.instance, p);                  // 显式归还（@nogc 路径的零件）
}

// ── 文本装配（std.format / std.conv / UFCS 管道）────────────
unittest {
    assert(format!"%04d-%s"(7, "x") == "0007-x");     // 编译期格式串检查
    assert("42".to!int + 1 == 43);
    auto r = 10.iota.map!(n => n * n).filter!(n => n % 2 == 0).array;
    assert(r == [0, 4, 16, 36, 64]);
}

void main() {
    writeln("libphobos 巡礼（26 章）：每个域一行代表作");
    writefln("std.meta     staticMap 去修饰  -> %s", staticMap!(Unqual, const int, immutable string).stringof);
    writefln("std.sumtype  SumType!(int,string) 大小 = %d 字节", SumType!(int, string).sizeof);

    BigInt f = 1;
    foreach (i; 2 .. 51) f *= i;
    writefln("std.bigint   50! 的前 20 位 = %s…", f.to!string[0 .. 20]);

    writefln("std.regex    %s", matchFirst("version 2.113", regex(r"\d+\.\d+")).captures[0]);
    writefln("std.digest   md5(\"abc\") = %s", md5Of("abc").toHexString);
    writefln("std.uuid     %s", randomUUID());
    writefln("std.datetime 2026-09-21 + 5 天 = %s", Date(2026, 9, 21) + 5.days);
    writefln("std.container 红黑树: %s", redBlackTree(5, 3, 1, 4, 2).array);

    // druntime 侧（26.2 的表）：GC/线程/原子/TypeInfo 都住在 core.*，
    // 本程序自身就运行在它上面——`GC.stats()`、`core.thread` 演示见 15 章。
    version (linux) writeln("druntime     version(linux) 分支 = Linux 系统 API（core.sys.linux）");
    else version (Windows) writeln("druntime     version(Windows) 分支 = Win32 API（core.sys.windows）");
}
