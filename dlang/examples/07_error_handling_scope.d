module ex07_error_handling_scope;

import std.exception : enforce;
import std.stdio;

int divide(int a, int b)
{
    enforce(b != 0, "b cannot be zero");
    return a / b;
}

void main()
{
    scope (exit) writeln("cleanup done");

    try {
        writeln("10 / 2 = ", divide(10, 2));
        writeln("1 / 0 = ", divide(1, 0));
    } catch (Exception ex) {
        writeln("caught: ", ex.msg);
    }
}
