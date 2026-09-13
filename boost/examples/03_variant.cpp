#include <boost/variant.hpp>
#include <iostream>
#include <string>

struct Visitor : boost::static_visitor<>
{
    Visitor()
        : boost::static_visitor<>()
    {
    }

    void operator()(int v) const
    {
        std::cout << "int=" << v << '\n';
    }

    void operator()(const std::string& v) const
    {
        std::cout << "string=" << v << '\n';
    }
};

int main()
{
    boost::variant<int, std::string> value = 10;
    boost::apply_visitor(Visitor{}, value);
    value = std::string("boost");
    boost::apply_visitor(Visitor{}, value);
    return 0;
}
