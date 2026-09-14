#include <iostream>
#include <string>
#include <vector>

namespace winui3_guide::dialog_navigation_control {

enum class PageId {
    Home,
    Settings,
    About
};

struct NavigationState {
    PageId current_page = PageId::Home;
    std::vector<std::string> pages = { "Home", "Settings", "About" };
};

bool confirm_delete(std::string item_name)
{
    return item_name.size() > 0;
}

std::string navigate_to(NavigationState& state, PageId next_page)
{
    state.current_page = next_page;
    switch (next_page) {
    case PageId::Home:
        return "Navigate to Home";
    case PageId::Settings:
        return "Navigate to Settings";
    case PageId::About:
        return "Navigate to About";
    }
    return "Unknown";
}

} // namespace winui3_guide::dialog_navigation_control

int main()
{
    winui3_guide::dialog_navigation_control::NavigationState state;
    std::cout << winui3_guide::dialog_navigation_control::navigate_to(state,
        winui3_guide::dialog_navigation_control::PageId::Settings)
        << '\n';

    std::cout << (winui3_guide::dialog_navigation_control::confirm_delete("demo") ? "Confirmed" : "Canceled") << '\n';
    return 0;
}
