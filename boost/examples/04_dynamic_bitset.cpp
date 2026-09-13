#include <boost/dynamic_bitset.hpp>
#include <iostream>

int main()
{
    boost::dynamic_bitset<> flags(8);
    flags.set(1);
    flags.set(5);

    std::cout << flags << '\n';
    std::cout << "count=" << flags.count() << '\n';
    return 0;
}
