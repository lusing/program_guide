#include <boost/property_tree/json_parser.hpp>
#include <boost/property_tree/ptree.hpp>
#include <iostream>
#include <sstream>
#include <string>

int main()
{
    std::stringstream ss(R"({"app":{"name":"guide","port":8080}})");
    boost::property_tree::ptree root;
    boost::property_tree::read_json(ss, root);

    std::cout << root.get<std::string>("app.name") << '\n';
    std::cout << root.get<int>("app.port") << '\n';
    return 0;
}
