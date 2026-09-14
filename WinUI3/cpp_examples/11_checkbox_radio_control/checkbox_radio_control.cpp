#include <iostream>
#include <string>
#include <vector>

namespace winui3_guide::checkbox_radio_control {

enum class UserMode {
    Developer,
    Release,
    Test
};

struct SettingsModel {
    bool remember_me = true;
    bool auto_save = false;
    UserMode mode = UserMode::Developer;
};

std::string describe(const SettingsModel& model)
{
    std::string result = "remember_me=" + std::string(model.remember_me ? "true" : "false");
    result += ", auto_save=" + std::string(model.auto_save ? "true" : "false");
    result += ", mode=";
    switch (model.mode) {
    case UserMode::Developer:
        result += "Developer";
        break;
    case UserMode::Release:
        result += "Release";
        break;
    case UserMode::Test:
        result += "Test";
        break;
    }
    return result;
}

} // namespace winui3_guide::checkbox_radio_control

int main()
{
    winui3_guide::checkbox_radio_control::SettingsModel model;
    model.auto_save = true;
    model.mode = winui3_guide::checkbox_radio_control::UserMode::Release;

    std::cout << winui3_guide::checkbox_radio_control::describe(model) << '\n';
    return 0;
}
