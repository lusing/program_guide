#include <memory>
#include <mutex>

class Singleton {
public:
    static std::shared_ptr<Singleton> instance() {
        std::call_once(init_flag, [] {
            instance_ptr = std::shared_ptr<Singleton>(new Singleton());
        });
        return instance_ptr;
    }

    void do_work() {
        std::cout << "Working...\n";
    }

private:
    Singleton() = default;
    ~Singleton() = default;

    static std::shared_ptr<Singleton> instance_ptr;
    static std::once_flag init_flag;
};

std::shared_ptr<Singleton> Singleton::instance_ptr = nullptr;
std::once_flag Singleton::init_flag;
