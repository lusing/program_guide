// 14 · 算法库：map/filter/reduce 与惰性管道
// std.algorithm 的函数几乎都返回惰性区间——不调用 .array/.walkLength 就不算账
import std.stdio, std.algorithm, std.range, std.array, std.conv;
import std.math : abs;
import std.typecons : tuple;

void main() {
    auto nums = [4, 8, 15, 16, 23, 42];

    // ── 变换三剑客：map / filter / reduce ───────────────────
    auto doubled = nums.map!(x => x * 2);            // 惰性：此刻一个数都没算
    writeln(doubled.array);                          // .array 才消费

    auto evens = nums.filter!(x => x % 2 == 0);
    writeln(evens.array);

    auto total = nums.reduce!((a, b) => a + b);       // 无种子：用前两个元素起步
    // 带种子版是 (seed, range) 参数序，UFCS 会让 range 抢到 seed 位置——干脆别 UFCS
    auto seeded = reduce!((a, b) => a + b)(100, nums);
    writeln(total, " ", seeded);                      // 108 208

    // fold：起点在类型上更自由（int[] → long 结果）
    auto sum = nums.fold!((a, b) => a + b);
    writeln("fold sum = ", sum);

    // ── 管道组合：UFCS 串起来，逐元素一次通过 ────────────────
    auto pipeline = 100.iota                          // 0..99
        .filter!(n => n % 3 == 0)                    // 3 的倍数
        .map!(n => n * n)                            // 平方
        .filter!(n => n < 10_000)                    // 小于一万
        .array;
    writeln("管道产出 ", pipeline.length, " 个，头几个：", pipeline.take(5));

    // ── 搜索与判断 ─────────────────────────────────────────
    writeln(nums.canFind(23), " ", nums.canFind(99));
    writeln(nums.count!(x => x > 15), " 个大于 15");
    writeln(nums.countUntil(16), " ← 16 在下标");    // 找不到返回 -1
    writeln([1, 2, 3].all!(x => x > 0), " ", [1, 2, 3].any!(x => x > 2));

    // ── 排序：sort 返回 SortedRange（就地排序，保留"已排序"信息）──
    auto data = [5, 2, 8, 1, 9, 3];
    auto sorted = data.sort;                          // 默认升序，就地排（不是副本！）
    writeln(sorted);
    auto desc = [5, 2, 8, 1].sort!"a > b";            // 比较器：字符串形式的模板参数
    writeln(desc);
    auto byAbs = [-5, 2, -8, 1].sort!((a, b) => abs(a) < abs(b));
    writeln(byAbs);
    // 多键排序：schwartzian 变换——"先变换再排"
    auto words = ["banana", "kiwi", "apple"];
    auto byLen = words.sort!((a, b) => a.length < b.length || (a.length == b.length && a < b));
    writeln(byLen);

    // ── 切分与聚合 ─────────────────────────────────────────
    writeln([1, 1, 2, 2, 2, 3].group.array);          // 相邻分组 [(1,2),(2,3),(3,1)]
    writeln([3, 1, 4, 1, 5].uniq.array);              // 相邻去重 [3, 1, 4, 1, 5]
    writeln([1, 2, 2, 3].sum, " ", [1.5, 2.5].sum);   // sum / min / max
    writeln([3, 1, 4].minElement, " ", [3, 1, 4].maxElement);

    // each!：命令式遍历（替代 foreach 的函数式姿势）
    [1, 2, 3].each!(x => write(x * 10, " "));
    writeln();

    // chunk / evenChunks：分块处理大数据（内存友好）
    foreach (chunk; 10.iota.chunks(4))
        write(chunk.array, " ");
    writeln();

    // 惰性验证：无限区间 + 管道 = 只算需要的部分
    // 注意 iota(0) 是"空区间"（单参数是 stop！），无限序列用 sequence!"n"
    auto firstTenSquaresOfEvens = sequence!"n"(0)
        .filter!(n => n % 2 == 0)
        .map!(n => n * n)
        .take(3);
    writeln("前 3 个偶数平方：", firstTenSquaresOfEvens.array);
}

unittest {
    auto a = [4, 8, 15, 16, 23, 42];
    assert(a.map!(x => x + 1).array == [5, 9, 16, 17, 24, 43]);
    assert(a.filter!(x => x % 2 == 1).equal([15, 23]));
    assert(a.fold!((x, y) => x + y) == 108);
    assert(a.reduce!min == 4);                        // reduce!binaryOp 复用运算符
    assert([5, 2, 8].sort.equal([2, 5, 8]));
    assert([-3, 1, -2].sort!((x, y) => abs(x) < abs(y)).equal([1, -2, -3]));
    assert([1, 1, 2].group.array == [tuple(1, 2), tuple(2, 1)]);
    int[][] parts = 5.iota.chunks(2).map!(c => c.array).array;   // 每个 chunk 也是惰性区间
    assert(parts == [[0, 1], [2, 3], [4]]);
    auto inf = sequence!"n"(0).filter!(n => n > 5).take(2);
    assert(inf.equal([6, 7]));
    static assert(isInfinite!(typeof(sequence!"n"(0))));
}
