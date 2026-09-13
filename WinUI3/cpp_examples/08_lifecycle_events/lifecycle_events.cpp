#include <iostream>
#include <string>
#include <vector>

namespace winui3_guide::lifecycle_events {

class AppLifecycle {
public:
    void on_launched()
    {
        events_.push_back("Launched");
    }

    void on_activated()
    {
        events_.push_back("Activated");
    }

    void on_suspending()
    {
        events_.push_back("Suspending");
    }

    [[nodiscard]] std::string trace() const
    {
        std::string result;
        for (std::size_t i = 0; i < events_.size(); ++i) {
            result += events_[i];
            if (i + 1 < events_.size()) {
                result += " -> ";
            }
        }
        return result;
    }

private:
    std::vector<std::string> events_;
};

} // namespace winui3_guide::lifecycle_events

int main()
{
    winui3_guide::lifecycle_events::AppLifecycle app;
    app.on_launched();
    app.on_activated();
    app.on_suspending();
    std::cout << app.trace() << '\n';
    return 0;
}
