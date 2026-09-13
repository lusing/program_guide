module ex06_ranges_algorithms;

import std.algorithm : filter, map;
import std.algorithm.iteration : sum;
import std.range : iota;
import std.stdio;

void main()
{
    auto evenSquare = iota(1, 11)
        .filter!(n => n % 2 == 0)
        .map!(n => n * n);

    auto total = evenSquare.sum;
    writeln("sum=", total);
}
