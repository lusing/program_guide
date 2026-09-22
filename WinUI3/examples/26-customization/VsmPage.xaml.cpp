#include "pch.h"
#include "VsmPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::CustomGallery::implementation
{
    VsmPage::VsmPage()
    {
        InitializeComponent();
    }

    void VsmPage::OnForceNarrow(IInspectable const&, RoutedEventArgs const&)
    {
        // 手动 GoToState：确定性切换（自动化验证路径；AdaptiveTrigger 是 resize 自动）
        bool used{};
        VisualStateManager::GoToState(*this, L"NarrowState", false);
        StatusText().Text(L"state = narrow (manual)");
    }

    void VsmPage::OnForceWide(IInspectable const&, RoutedEventArgs const&)
    {
        VisualStateManager::GoToState(*this, L"WideState", false);
        StatusText().Text(L"state = wide (manual)");
    }
}
