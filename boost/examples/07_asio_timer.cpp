#include <boost/asio.hpp>
#include <chrono>
#include <iostream>

int main()
{
    boost::asio::io_context io;
    boost::asio::steady_timer timer(io, std::chrono::milliseconds(5));
    timer.async_wait([](const boost::system::error_code& ec) {
        if (!ec) {
            std::cout << "timer fired\n";
        }
    });
    io.run();
    return 0;
}
