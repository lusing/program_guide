#include "pch.h"
#include "SliderPage.xaml.h"

#include <cmath>

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;
using namespace Microsoft::UI::Xaml::Controls::Primitives;

namespace winrt::BasicGallery::implementation
{
    SliderPage::SliderPage()
    {
        InitializeComponent();
    }

    void SliderPage::OnVolumeChanged(IInspectable const&,
        RangeBaseValueChangedEventArgs const& args)
    {
        // NewValue/OldValue 都在 args 里（TextBox.TextChanged 没有的待遇）
        // 防护：XAML 解析期/析构期触发时，相邻控件可能尚未建立或已释放
        if (!SyncBar() || !StatusText()) return;
        auto v = args.NewValue();
        // 防重入：在值变更通知路径上回写同一个 RangeBase 是禁区——
        // 值没变就早退，避免 IsIndeterminate 切换等框架内部 Value 调整触发重入（实测 AV）
        if (std::abs(SyncBar().Value() - v) < 0.5) return;
        StatusText().Text(L"volume = " + winrt::to_hstring(v));
        // 确定进度条直写联动（无绑定版；x:Bind 函数绑定见 32 章）
        SyncBar().Value(v);
    }

    void SliderPage::OnToggleBusyClicked(IInspectable const&, RoutedEventArgs const&)
    {
        BusyRing().IsActive(!BusyRing().IsActive());
        StatusText().Text(BusyRing().IsActive() ? L"ring busy" : L"ring idle");
    }

    void SliderPage::OnRatingChanged(IInspectable const&, IInspectable const&)
    {
        // RatingControl.ValueChanged 的 args 是裸 IInspectable（元数据核对），值直接读控件
        if (!Importance() || !StatusText()) return;
        StatusText().Text(L"rating = " + winrt::to_hstring(Importance().Value()));
    }
}
