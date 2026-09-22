#include "pch.h"
#include "OverlaysPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::ShellGallery::implementation
{
    OverlaysPage::OverlaysPage()
    {
        InitializeComponent();
    }

    void OverlaysPage::OnTipClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Tip()) return;
        Tip().IsOpen(!Tip().IsOpen());
        StatusText().Text(Tip().IsOpen() ? L"tip open" : L"tip closed");
    }

    void OverlaysPage::OnTipAction(IInspectable const&, IInspectable const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"tip action clicked");
    }

    void OverlaysPage::OnInfoBarClosed(IInspectable const&, IInspectable const&)
    {
        if (!StatusText()) return;
        StatusText().Text(L"info bar closed");
    }

    void OverlaysPage::OnCycleSeverityClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Notice() || !StatusText()) return;
        // 严重度循环：Informational -> Success -> Warning -> Error
        static InfoBarSeverity const severities[]{
            InfoBarSeverity::Informational, InfoBarSeverity::Success,
            InfoBarSeverity::Warning, InfoBarSeverity::Error,
        };
        static hstring const names[]{ L"informational", L"success", L"warning", L"error" };
        m_severity = (m_severity + 1) % 4;
        Notice().Severity(severities[m_severity]);
        Notice().Title(names[m_severity]);
        Notice().IsOpen(true);
        StatusText().Text(L"severity = " + names[m_severity]);
    }
}
