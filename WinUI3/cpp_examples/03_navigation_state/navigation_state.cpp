#include <iostream>
#include <string>
#include <unordered_map>

namespace winui3_guide::navigation_state {

enum class PageId {
    Home,
    Settings,
    About
};

class NavigationService {
public:
    void navigate(PageId page)
    {
        current_page_ = page;
    }

    [[nodiscard]] PageId current_page() const
    {
        return current_page_;
    }

    [[nodiscard]] std::string current_page_name() const
    {
        static const std::unordered_map<PageId, std::string> names{
            {PageId::Home, "Home"},
            {PageId::Settings, "Settings"},
            {PageId::About, "About"}
        };
        return names.at(current_page_);
    }

private:
    PageId current_page_{PageId::Home};
};

} // namespace winui3_guide::navigation_state

int main()
{
    winui3_guide::navigation_state::NavigationService nav;
    nav.navigate(winui3_guide::navigation_state::PageId::Settings);
    std::cout << "Current page: " << nav.current_page_name() << '\n';
    return 0;
}
