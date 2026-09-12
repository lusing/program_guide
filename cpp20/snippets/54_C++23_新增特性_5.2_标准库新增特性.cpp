#include <vector>
#include <string>

// std::vector::resize_as_and_capacity
std::vector<int> v;
v.resize(100);
v.shrink_to_fit();  // C++23 可能更高效

// std::basic_string::contains
std::string s = "Hello, World!";
if (s.contains("World")) {
    std::cout << "Found!\n";
}

// std::basic_string::replace
s.replace("World", "C++23");
