module ex04_structs_ufcs;

import std.math : sqrt;
import std.stdio;

struct Vec2
{
    double x;
    double y;

    double length() const
    {
        return sqrt(x * x + y * y);
    }
}

Vec2 scale(Vec2 v, double factor)
{
    return Vec2(v.x * factor, v.y * factor);
}

Vec2 translate(Vec2 v, double dx, double dy)
{
    return Vec2(v.x + dx, v.y + dy);
}

void main()
{
    auto v = Vec2(3, 4).scale(2).translate(1, -1);
    writeln("x=", v.x, ", y=", v.y, ", len=", v.length());
}
