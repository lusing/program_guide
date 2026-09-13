#include <boost/algorithm/string.hpp>
#include <iostream>
#include <string>
#include <vector>

int main()
{
    std::string text = "Boost, C++, Library";
    boost::replace_all(text, " ", "");

    std::vector<std::string> parts;
    boost::split(parts, text, boost::is_any_of(","));

    std::cout << "count=" << parts.size() << '\n';
    std::cout << boost::join(parts, "|") << '\n';
    return 0;
}
