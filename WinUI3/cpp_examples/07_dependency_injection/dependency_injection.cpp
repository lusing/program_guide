#include <iostream>
#include <memory>
#include <string>

namespace winui3_guide::dependency_injection {

class ILogger {
public:
    virtual ~ILogger() = default;
    virtual void info(const std::string& message) = 0;
};

class ConsoleLogger final : public ILogger {
public:
    void info(const std::string& message) override
    {
        std::cout << "[info] " << message << '\n';
    }
};

class UserService {
public:
    explicit UserService(std::shared_ptr<ILogger> logger)
        : logger_(std::move(logger))
    {
    }

    void login(const std::string& name)
    {
        logger_->info("User login: " + name);
    }

private:
    std::shared_ptr<ILogger> logger_;
};

} // namespace winui3_guide::dependency_injection

int main()
{
    auto logger = std::make_shared<winui3_guide::dependency_injection::ConsoleLogger>();
    winui3_guide::dependency_injection::UserService service(logger);
    service.login("guide-user");
    return 0;
}
