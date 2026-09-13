module ex02_types_control;

import std.conv : to;
import std.stdio;

void main()
{
    int total = 0;
    foreach (i; 1 .. 6) {
        total += i;
    }

    const category = total > 10 ? "big" : "small";
    const parsed = to!int("123");

    writeln("total=", total, ", category=", category);
    writeln("parsed=", parsed);
}
