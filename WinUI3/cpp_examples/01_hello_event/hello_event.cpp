#include <iostream>
#include <string>
#include <string_view>

namespace winui3_guide::hello_event {

class MainWindowViewModel {
public:
    std::string build_greeting(std::string_view name) const
    {
        if (name.empty()) {
            return "Hello, WinUI3!";
        }
        return "Hello, " + std::string(name) + "!";
    }
};

void on_say_hello_click(const MainWindowViewModel& vm, std::string_view name)
{
    std::cout << vm.build_greeting(name) << '\n';
}

} // namespace winui3_guide::hello_event

int main()
{
    const winui3_guide::hello_event::MainWindowViewModel vm;
    winui3_guide::hello_event::on_say_hello_click(vm, "Developer");
    return 0;
}
