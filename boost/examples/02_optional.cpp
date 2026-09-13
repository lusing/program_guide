#include <boost/optional.hpp>
#include <iostream>

boost::optional<int> parse_positive(int value)
{
    if (value > 0) {
        return value;
    }
    return boost::none;
}

int main()
{
    const auto ok = parse_positive(42);
    const auto bad = parse_positive(-1);
    std::cout << (ok ? *ok : 0) << '\n';
    std::cout << (bad ? 1 : 0) << '\n';
    return 0;
}
