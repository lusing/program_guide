#include "pch.h"
#include "DrawingPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;
using namespace Microsoft::UI::Xaml::Media;

namespace winrt::CustomGallery::implementation
{
    DrawingPage::DrawingPage()
    {
        InitializeComponent();
    }

    void DrawingPage::OnColorChanged(IInspectable const&, ColorChangedEventArgs const& args)
    {
        if (!LiveDot() || !StatusText()) return;
        // ColorPicker 选色 -> 驱动 Ellipse 的 Fill（SolidColorBrush 直写）
        auto color = args.NewColor();
        LiveDot().Fill(SolidColorBrush(color));
        StatusText().Text(L"color = " + to_hstring(color.R) + L"," + to_hstring(color.G) + L"," + to_hstring(color.B));
    }
}
