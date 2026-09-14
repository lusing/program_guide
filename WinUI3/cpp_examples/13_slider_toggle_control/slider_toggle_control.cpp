#include <iostream>
#include <string>

namespace winui3_guide::slider_toggle_control {

struct SettingsState {
    double volume = 45.0;
    bool notifications_enabled = true;
    bool compact_mode = false;
};

std::string describe(const SettingsState& state)
{
    std::string result = "volume=" + std::to_string(state.volume);
    result += ", notifications=" + std::string(state.notifications_enabled ? "on" : "off");
    result += ", compact_mode=" + std::string(state.compact_mode ? "on" : "off");
    return result;
}

void set_volume(SettingsState& state, double new_value)
{
    state.volume = new_value;
}

void set_notifications(SettingsState& state, bool enabled)
{
    state.notifications_enabled = enabled;
}

} // namespace winui3_guide::slider_toggle_control

int main()
{
    winui3_guide::slider_toggle_control::SettingsState state;
    winui3_guide::slider_toggle_control::set_volume(state, 80.0);
    winui3_guide::slider_toggle_control::set_notifications(state, false);
    std::cout << winui3_guide::slider_toggle_control::describe(state) << '\n';
    return 0;
}
