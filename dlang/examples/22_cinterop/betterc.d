// -betterC 模式：无 GC、无运行时、无异常——D 当"更好的 C"用
// 编译：dmd -w -betterC betterc.d '-of=…\22_betterc.exe'
// 关键区别：
//   1. main 必须写成 extern(C) int main()（普通 void main 会引用 _d_run_main → 链接失败）
//   2. 只能用 @nogc 能过的特性：栈数组、malloc、printf
//   3. 没有 GC/异常/TypeInfo；类和内部数组字面量受限
import core.stdc.stdio : printf;
import core.stdc.stdlib : malloc, free;

extern (C) int fib(int n) {
    return n < 2 ? n : fib(n - 1) + fib(n - 2);
}

extern (C) int main() {
    printf("BetterC: fib(20) = %d\n", fib(20));

    // 手动内存 + 栈上切片：全套 C 手感
    enum n = 8;
    int* buf = cast(int*)malloc(int.sizeof * n);
    for (int i = 0; i < n; ++i)
        buf[i] = fib(i);
    printf("fib 数组：");
    for (int i = 0; i < n; ++i)
        printf(" %d", buf[i]);
    printf("\n");
    free(buf);
    return 0;
}
