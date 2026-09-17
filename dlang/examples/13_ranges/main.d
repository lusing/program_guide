// 13 · 区间（Range）：D 代替迭代器的统一抽象
// 一个区间 = 有 empty / front / popFront 三件套的任意类型（鸭子类型，不需要继承）
import std.stdio, std.range, std.array, std.algorithm, std.traits;

// ── 手写一个输入区间：倒数计数器 ────────────────────────────
struct Countdown {
    long current;
    bool empty() const { return current <= 0; }
    long front() const { return current; }
    void popFront() { current--; }
}

// ── 双向区间：多 back / popBack ────────────────────────────
struct Palindrome(R) {          // 包装另一个区间，正读反读一样
    R source;
    bool empty() { return source.empty; }
    auto front() { return source.front; }
    auto back() { return source.back; }
    void popFront() { source.popFront(); }
    void popBack() { source.popBack(); }
}

// ── 无限区间：惰性生成的自然数 ──────────────────────────────
struct Naturals {
    long from = 0;
    enum bool empty = false;             // 编译期常量：永不为空
    long front() const { return from; }
    void popFront() { from++; }
}

// isXxxRange!T 编译期验证区间类型
static assert(isInputRange!Countdown);
static assert(isForwardRange!(int[]));   // 注意 !(int[])：写 !int[] 会被解析成"bool 数组"
static assert(!isRandomAccessRange!string);   // string 是 UTF-8，下标是字节，不算 RA 区间！

void main() {
    // 手写区间直接参与所有算法
    foreach (n; Countdown(3)) write(n, "… ");        // 3… 2… 1…
    writeln();

    // 标准区间工厂
    writeln(iota(1, 6).array);                       // [1, 2, 3, 4, 5]
    writeln(iota(0, 10, 3).array);                   // [0, 3, 6, 9]：步长
    writeln(chain([1, 2], [3, 4]).array);            // 拼接两个区间
    writeln(cycle([1, 2]).take(5).array);            // [1, 2, 1, 2, 1]：循环+截取
    writeln(recurrence!("a[n-1] + a[n-2]")(1, 1).take(8).array);  // 斐波那契！

    // take / drop / retro / stride：全是视图，不拷贝数据
    auto data = [1, 2, 3, 4, 5, 6];
    writeln(data.take(3).array, " ", data.drop(2).array);
    writeln(data.retro.array, " ", data.stride(2).array);

    // zip：并行遍历两个区间（短的截断——所以别拿 iota(1) 当"从 1 开始的无限流"，它是空的！）
    foreach (i, word; zip(iota(1, 4), ["一", "二", "三"]))
        write(i, "→", word, " ");
    writeln();

    // 无限区间：必须有 take 之类的限定才可能终止
    writeln(Naturals().take(5).array);               // [0, 1, 2, 3, 4]
    writeln(Naturals(100).take(3).array);

    // 无限区间 + 算法：找到第一个满足条件的就停（惰性）
    auto firstBigSquare = Naturals()
        .map!(n => n * n)                            // 平方（14 章）
        .find!(n => n % 100 == 0);                   // 第一个整百数
    writeln("第一个整百平方数：", firstBigSquare.front);   // 0? 不——naturals 从 0 开始
    writeln(Naturals(1).map!(n => n * n).find!(n => n % 100 == 0).front);  // 100

    // 区间适配器也适用于自定义类型：双向区间回文判断
    auto nums2 = [1, 2, 3, 2, 1];
    auto pal = Palindrome!(int[])(nums2);
    writeln("回文：", equal(pal, nums2.retro));      // 区间 == 区间比较
}

unittest {
    auto c = Countdown(3);
    assert(!c.empty && c.front == 3);
    c.popFront();
    assert(c.front == 2);
    assert(c.array == [2, 1]);                       // 走到哪算哪（部分消费后）

    assert(Countdown(5).equal([5, 4, 3, 2, 1]));
    assert(iota(5).retro.equal([4, 3, 2, 1, 0]));
    assert(Naturals().take(3).equal([0, 1, 2]));

    assert(isInputRange!(typeof(Naturals())));
    static assert(!isBidirectionalRange!(typeof(Naturals())));

    auto fib = recurrence!("a[n-1] + a[n-2]")(1, 1);
    assert(fib.take(6).equal([1, 1, 2, 3, 5, 8]));

    // string 是"元素为 char 的输入区间"，但不是 RA——UTF-8 陷阱的区间视角
    static assert(isInputRange!string);
}
