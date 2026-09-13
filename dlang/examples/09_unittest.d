module ex09_unittest;

import std.stdio;

int fib(int n)
{
    if (n <= 1) {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}

unittest
{
    assert(fib(0) == 0);
    assert(fib(1) == 1);
    assert(fib(6) == 8);
}

void main()
{
    writeln("fib(10)=", fib(10));
}
