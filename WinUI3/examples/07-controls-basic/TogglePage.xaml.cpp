#include "pch.h"
#include "TogglePage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;
using namespace Microsoft::UI::Xaml::Controls::Primitives;   // ToggleButton 住在这里

namespace winrt::BasicGallery::implementation
{
    TogglePage::TogglePage()
    {
        InitializeComponent();
    }

    void TogglePage::OnAutoSaveToggled(IInspectable const&, RoutedEventArgs const&)
    {
        // IsOn 是普通 bool——与 CheckBox 的 IReference<bool> 三态对照
        StatusText().Text(AutoSaveSwitch().IsOn() ? L"autosave on" : L"autosave off");
    }

    void TogglePage::OnModeToggled(IInspectable const& sender, RoutedEventArgs const&)
    {
        auto button = sender.as<ToggleButton>();
        auto name = button.Content().as<hstring>();
        // IsChecked 是 IReference<bool>（继承自 CheckBox 家族的语义）
        bool on = button.IsChecked().Value();
        StatusText().Text(name + (on ? L" = on" : L" = off"));
    }
}
