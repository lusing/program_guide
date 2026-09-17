// 包内模块：module 名必须与"目录.文件名"一致
module dguide_dub.mathutil;

int triple(int x) {
    return 3 * x;
}

/// 斐波那契数列前 n 项（数组版，递推）
long[] fibTake(size_t n) {
    long[] r;
    long a = 1, b = 1;
    foreach (_; 0 .. n) {
        r ~= a;
        auto next = a + b;
        a = b;
        b = next;
    }
    return r;
}

unittest {
    assert(triple(0) == 0);
    assert(fibTake(0) == []);
    assert(fibTake(1) == [1]);
    assert(fibTake(8) == [1, 1, 2, 3, 5, 8, 13, 21]);
}
