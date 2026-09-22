#include "pch.h"
#include "AnimationPage.xaml.h"

#include <chrono>

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::CustomGallery::implementation
{
    AnimationPage::AnimationPage()
    {
        InitializeComponent();
    }

    void AnimationPage::OnAnimateClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!Bar() || !StatusText()) return;
        ++m_shots;

        // Storyboard：Width 40 -> 320（1s，结束保持）
        winrt::Microsoft::UI::Xaml::Media::Animation::Storyboard sb;
        winrt::Microsoft::UI::Xaml::Media::Animation::DoubleAnimation widthAnim;
        widthAnim.From(40.0);
        widthAnim.To(320.0);
        widthAnim.Duration(winrt::Microsoft::UI::Xaml::Duration{ winrt::Windows::Foundation::TimeSpan{ std::chrono::seconds(1) } });
        winrt::Microsoft::UI::Xaml::Media::Animation::Storyboard::SetTarget(widthAnim, Bar());
        winrt::Microsoft::UI::Xaml::Media::Animation::Storyboard::SetTargetProperty(widthAnim, L"Width");
        sb.Children().Append(widthAnim);
        sb.Begin();

        StatusText().Text(L"animated, shots = " + to_hstring(m_shots));
    }

    void AnimationPage::OnToggleFadeClicked(IInspectable const&, RoutedEventArgs const&)
    {
        if (!FadeBox() || !StatusText()) return;
        bool visible = FadeBox().Visibility() == Visibility::Visible;
        FadeBox().Visibility(visible ? Visibility::Collapsed : Visibility::Visible);
        StatusText().Text(visible ? L"fade box hidden" : L"fade box shown");
    }
}
