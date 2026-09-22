#include "pch.h"
#include "StylesPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::CustomGallery::implementation
{
    StylesPage::StylesPage()
    {
        InitializeComponent();
    }

    void StylesPage::OnStyledClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"styled button works");
    }

    void StylesPage::OnTemplatedClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"templated button works");
    }
}
