#pragma once
#include "AnimationPage.g.h"

namespace winrt::CustomGallery::implementation
{
    struct AnimationPage : AnimationPageT<AnimationPage>
    {
        AnimationPage();

        void OnAnimateClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
        void OnToggleFadeClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);

    private:
        int m_shots{ 0 };
    };
}

namespace winrt::CustomGallery::factory_implementation
{
    struct AnimationPage : AnimationPageT<AnimationPage, implementation::AnimationPage>
    {
    };
}
