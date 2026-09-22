#include "pch.h"
#include "CustomControlPage.xaml.h"
#include "LabeledValueControl.xaml.h"
#include "TitleRow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::CustomGallery::implementation
{
    CustomControlPage::CustomControlPage()
    {
        InitializeComponent();
    }

    void CustomControlPage::OnBumpClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Meter() || !StatusText()) return;
        Meter().Value(to_hstring(m_value += 1));
        StatusText().Text(L"value = " + to_hstring(m_value));
    }

    void CustomControlPage::OnReadRowClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Row() || !StatusText()) return;
        StatusText().Text(L"title row = " + Row().Title() + L" / " + Row().Value());
    }
}
