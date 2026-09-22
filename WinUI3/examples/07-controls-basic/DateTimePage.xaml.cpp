#include "pch.h"
#include "DateTimePage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;
namespace wf = Windows::Foundation;

namespace winrt::BasicGallery::implementation
{
    DateTimePage::DateTimePage()
    {
        InitializeComponent();
    }

    void DateTimePage::OnDateChanged(IInspectable const&,
        DatePickerValueChangedEventArgs const& args)
    {
        if (!StatusText()) return;
        // 元数据实测：args.NewDate() 返回裸 DateTime 结构体（编译级 C2451 教训：
        // 它不是 IReference，没有可空语义，直接用）
        auto date = args.NewDate();
        StatusText().Text(L"date ticks = "
            + winrt::to_hstring(date.time_since_epoch().count()));
    }

    void DateTimePage::OnTodayClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Pick()) return;
        // 程序化设值触发 DateChanged（与用户改 spinner 同一事件）
        Pick().Date(winrt::clock::now());
    }
}
