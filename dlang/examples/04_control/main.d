// 04 · 控制流：foreach 的十八般武艺、switch 与标签跳转
import std.stdio;
import std.utf : byDchar;

void main() {
    auto langs = ["D", "Go", "Zig"];

    // ── foreach：比 C 的 for 强得多 ───────────────────────
    foreach (lang; langs) write(lang, " ");       // 正向
    writeln();
    foreach_reverse (lang; langs) write(lang, " "); // 逆向
    writeln();
    foreach (i, lang; langs)                       // 带索引（自动解包元组）
        writeln("  [", i, "] ", lang);

    foreach (n; 1 .. 5) write(n, " ");             // 区间 [1, 5)
    writeln();

    // foreach 改元素要 ref
    auto nums = [1, 2, 3];
    foreach (ref n; nums) n *= 10;
    writeln(nums);                                 // [10, 20, 30]

    // 关联数组（AA）：解包键值
    int[string] scores = ["D": 1999, "Go": 2009, "Zig": 2016];
    foreach (name, year; scores)
        writeln("  ", name, " → ", year);

    // 字符串默认按只读切片遍历；按码点遍历用 byDchar
    foreach (ch; "汉a".byDchar) write("[", ch, "]");  // [汉][a]
    writeln();

    // ── if / else ─────────────────────────────────────────
    int guess = 42;
    if (guess > 100)      writeln("大");
    else if (guess > 40)  writeln("中等");
    else                  writeln("小");

    // ── switch：支持范围 case 与字符串 ─────────────────────
    auto score = 85;
    switch (score) {
        case 90: .. case 100: writeln("优秀");  break;   // 范围 case 的写法
        case 80: .. case 89:  writeln("良好");  break;
        case 60: .. case 79:  writeln("及格");  break;
        default:              writeln("重修");
    }

    auto cmd = "list";
    final switch (cmd) {          // final：必须穷尽（无 default 时编译器把关）
        case "list":  writeln("列出文件"); break;
        case "add":   writeln("添加文件"); break;
        case "del":   writeln("删除文件"); break;
    }

    // 枚举 + final switch 是 D 的经典组合：加枚举值忘了补 case，编译期就报错
    enum Color { red, green, blue }
    auto c = Color.green;
    final switch (c) {
        case Color.red:   writeln("红"); break;
        case Color.green: writeln("绿"); break;   // 命中这行
        case Color.blue:  writeln("蓝"); break;
        // 试删掉 blue 那行：编译器直接报"not all paths covered"
    }

    // ── 标签 break/continue：跳出多层循环 ──────────────────
    outer:
    foreach (i; 0 .. 3) {
        foreach (j; 0 .. 3) {
            if (i * j == 4) break outer;
            if (j > i) continue outer;
            write("(", i, ",", j, ") ");
        }
    }
    writeln();

    // ── with：省略重复的成员限定 ───────────────────────────
    struct Point { int x, y; }
    Point p = { x: 1, y: 2 };
    with (p) writeln("x + y = ", x + y);

    // 三元是表达式，可以出现在赋值右侧
    auto parity = guess % 2 == 0 ? "偶" : "奇";
    writeln(parity);
}

unittest {
    auto a = [1, 2, 3, 4];
    long total = 0;
    foreach (x; a) total += x;
    assert(total == 10);
    int[string] aa = ["k": 5];
    foreach (k, v; aa) assert(k == "k" && v == 5);
}
