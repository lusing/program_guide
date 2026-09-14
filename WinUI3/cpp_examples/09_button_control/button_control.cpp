#include <iostream>
#include <string>
#include <vector>

namespace winui3_guide::button_control {

struct MainViewModel {
    std::string title = "WinUI 3 Button Demo";
    std::vector<std::string> messages;

    void add_message(std::string value)
    {
        messages.push_back(std::move(value));
    }
};

void on_save_clicked(MainViewModel& vm, std::string user_name)
{
    vm.add_message("Saved user: " + user_name);
}

void on_cancel_clicked(MainViewModel& vm)
{
    vm.add_message("Cancel clicked - form reset");
}

} // namespace winui3_guide::button_control

int main()
{
    winui3_guide::button_control::MainViewModel vm;
    winui3_guide::button_control::on_save_clicked(vm, "Alice");
    winui3_guide::button_control::on_cancel_clicked(vm);

    for (const auto& item : vm.messages) {
        std::cout << item << '\n';
    }

    return 0;
}
