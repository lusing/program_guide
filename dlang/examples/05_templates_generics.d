module ex05_templates_generics;

import std.stdio;
import std.traits : isIntegral;

T clampToZero(T)(T value) if (isIntegral!T)
{
    return value < 0 ? 0 : value;
}

T maxOf(T)(T a, T b)
{
    return a > b ? a : b;
}

void main()
{
    writeln("clamp(-3)=", clampToZero(-3));
    writeln("max int=", maxOf(10, 22));
    writeln("max double=", maxOf(1.5, 0.25));
}
