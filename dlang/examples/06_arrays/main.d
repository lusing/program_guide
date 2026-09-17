// 06 · 数组、切片与关联数组：D 内建的集合三件套
import std.stdio, std.array, std.algorithm, std.range, std.conv,
       std.utf : byDchar;

void main() {
    // ── 静态数组：长度编译期定，值语义，整个赋值=全量拷贝 ────
    int[3] fixed = [1, 2, 3];
    auto copy = fixed;            // 12 字节整体拷贝
    copy[0] = 99;
    writeln(fixed[0], " ", copy[0]);          // 1 99：互不影响
    writeln("静态数组大小：", fixed.sizeof);   // 12 = 3 × int.sizeof

    // ── 动态数组与切片：同一块内存的多个视图 ────────────────
    auto a = [10, 20, 30, 40, 50];
    auto head = a[0 .. 2];        // 切片 [10, 20]：与 a 共享内存！
    head[0] = -1;
    writeln(a);                   // [-1, 20, 30, 40, 50]：改切片=改原数组
    writeln("长度 ", a.length, "，容量 ", a.capacity);

    // 拼接 ~ / ~= 生成新内存（或扩容原地）
    auto b = a ~ [60, 70];
    a ~= 80;                      // 追加元素
    writeln(b.length, " ", a.length);

    // dup / idup：真拷贝（idup 拷成不可变，给 string 用）
    auto indep = a[0 .. 3].dup;
    indep[0] = 0;
    writeln(a[0], " ", indep[0]);

    // ── string 就是 immutable(char)[]：UTF-8 字节切片 ────────
    string s = "D 语言";
    writeln("length = ", s.length);            // 8：UTF-8 字节数，不是字符数！
    writeln("字符数 = ", s.byDchar.walkLength); // 4：按码点数（大坑，见下）
    // s[0] = 'd';        // 编译错：immutable 不能改
    auto mutable = s.dup;                      // char[] 可变副本
    // 中文一个字符 = 3 字节，按下标切会切碎 UTF-8 序列
    writeln(s[0 .. 1], " ← 第 1 字节只是 'D'");

    // ── 关联数组（AA）：内建的哈希表 ─────────────────────────
    int[string] ages;                // 声明：值[键]
    ages["D"] = 26;                  // 插入/更新
    ages["Go"] = 17;
    ages["Zig"] = 10;
    writeln(ages);                   // 顺序不保证（哈希）

    // 读不存在的键：直接 aa[k] 会抛 RangeError（大坑）！
    // 三种安全姿势：in（判存在）/ get（带默认值）/ require（带默认值并存入）
    if (auto p = "Go" in ages)                   // in 返回指针，null = 不存在
        writeln("Go 在表里，值 ", *p);
    writeln("不存在 = ", ages.get("Rust", 0));   // 0，不抛异常
    // ages["Rust"];                             // ← 打开这行：RangeError 崩溃

    ages.remove("Zig");                          // 删除键
    writeln("还剩 ", ages.length, " 个键");

    // 字面量初始化 + 遍历（注意：AA 字面量就是 [键: 值] 数组形态）
    string[string] zh = ["D": "D 语言", "Go": "Go 语言"];
    foreach (k, v; zh) writeln("  ", k, " → ", v);

    // AA 的 .get(key, 默认值)、byKey/byValue/byKeyValue
    writeln(ages.get("Java", -1));               // -1
    auto keys = ages.byKey.array;
    writeln(keys.sort.equal(["D", "Go"]));

    // 多维：数组的数组
    int[][] grid = [[1, 2], [3, 4]];
    writeln(grid[1][0], " 行数 ", grid.length);

    // 数组即区间：std.array / std.algorithm 的函数全可用（UFCS）
    auto stats = [4, 1, 3, 2]
        .sort!((x, y) => x > y)      // 自定义比较器：降序
        .array;
    writeln("降序：", stats);
}

unittest {
    auto a = [1, 2, 3, 4, 5];
    auto s = a[1 .. 4];
    assert(s == [2, 3, 4]);
    s[0] = 20;
    assert(a[1] == 20);                        // 切片共享

    int[string] aa = ["x": 1];
    aa["y"] = 2;
    assert(aa.length == 2 && aa["x"] == 1 && "z" !in aa);
    aa.remove("x");
    assert(aa.length == 1);

    string han = "一二三";
    assert(han.length == 9);                   // 3 字符 × 3 字节
    assert(han.byDchar.walkLength == 3);

    assert([3, 1, 2].sort.equal([1, 2, 3]));
    assert([1, 2, 3].map!(x => x * 2).array == [2, 4, 6]);
}
