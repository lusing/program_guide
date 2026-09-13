#include <boost/multi_index/member.hpp>
#include <boost/multi_index/ordered_index.hpp>
#include <boost/multi_index_container.hpp>
#include <iostream>
#include <string>

struct User
{
    int id;
    std::string name;
};

int main()
{
    using namespace boost::multi_index;
    using Users = multi_index_container<
        User,
        indexed_by<
            ordered_unique<member<User, int, &User::id>>,
            ordered_non_unique<member<User, std::string, &User::name>>>>;

    Users users;
    users.insert({1, "alice"});
    users.insert({2, "bob"});
    users.insert({3, "alice"});

    std::cout << "size=" << users.size() << '\n';
    return 0;
}
