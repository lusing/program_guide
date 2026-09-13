module ex03_functions_slices;

import std.stdio;

int square(int value)
{
    return value * value;
}

int[] firstN(const int[] data, size_t n)
{
    const end = n < data.length ? n : data.length;
    return data[0 .. end].dup;
}

void main()
{
    int[] values = [1, 2, 3, 4, 5];
    auto part = firstN(values, 3);

    int total = 0;
    foreach (v; part) {
        total += square(v);
    }

    writeln("sum of squares=", total);
}
