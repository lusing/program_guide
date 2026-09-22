#include "pch.h"
#include "NumberBoxPage.xaml.h"

#include <cmath>

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::BasicGallery::implementation
{
    NumberBoxPage::NumberBoxPage()
    {
        InitializeComponent();
    }

    void NumberBoxPage::OnQuantityChanged(IInspectable const&,
        NumberBoxValueChangedEventArgs const& args)
    {
        // 防护（12.5 教训）：解析期/析构期触发时控件未必就绪
        if (!Quantity() || !StatusText()) return;
        double v = args.NewValue();
        if (std::isnan(v))
        {
            StatusText().Text(L"quantity = (empty)");
        }
        else
        {
            StatusText().Text(L"quantity = " + winrt::to_hstring(v));
        }
    }

    void NumberBoxPage::OnDoubleClicked(IInspectable const&, RoutedEventArgs const&)
    {
        // 程序化写 Value：走同一套解析与校验路径，并再次触发 ValueChanged
        double v = Quantity().Value();
        if (!std::isnan(v)) Quantity().Value(v * 2);
    }

    void NumberBoxPage::OnClearClicked(IInspectable const&, RoutedEventArgs const&)
    {
        // 置 NaN = 空输入态（Value 是 double，"空"就是 NaN）
        Quantity().Value(std::numeric_limits<double>::quiet_NaN());
    }
}
