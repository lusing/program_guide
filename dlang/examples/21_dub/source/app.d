// 21 · 构建与 DUB：模块、包与项目管理
// 本示例是一个 DUB 工程：dub.json + source/ 目录（入口约定 app.d）
// 验证：dub test / dub run；不用 DUB 的替代：dmd -w -i -run source/app.d
import std.stdio;
import dguide_dub.mathutil;        // 普通 import：模块内容直接进当前作用域（不用加前缀！）
import dguide_dub.util.format;     // 子包目录 util/ 下的模块 format
static import dguide_dub.util.convert;  // static import：只能用全路径访问（两种姿势对照）

void main() {
    writeln("== DUB 工程示例 ==");

    // 普通 import：像本地函数一样裸调用
    writeln("triple(14) = ", triple(14));
    writeln("Fib 前 8 项 = ", fibTake(8));
    writeln("格式化：", formatMoney(1234567.891));

    // static import：必须全路径（适合刻意避免名字污染的场景）
    writeln("更深的子包：", dguide_dub.util.convert.celsiusToF(36.6));

    // 模块是编译单元：一个 .d 文件 = 一个 module；目录 = 包
    // import 路径由"包名.模块名"决定，与文件路径一致（dmd -i 自动按 import 找文件）

    // 编译期拿构建信息：version 标签（dub test 自动置 unittest 版本标签）
    version (unittest)     writeln("当前带 -unittest 编译（dub test）");
    else                   writeln("当前是常规编译（dub run/build）");
}

unittest {
    // dub test 会把所有模块的 unittest 收进测试可执行文件并运行
    assert(triple(3) == 9);
    assert(fibTake(6) == [1, 1, 2, 3, 5, 8]);
    assert(formatMoney(0.5) == "0.50 元");
    assert(dguide_dub.util.convert.celsiusToF(100) == 212);
}
