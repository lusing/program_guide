#pragma once
#include "MainWindow.g.h"

namespace winrt::ThemeLab::implementation
{
    struct MainWindow : MainWindowT<MainWindow>
    {
        MainWindow();

        void OnPresetSelected(Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::SelectionChangedEventArgs const& args);
        void OnAccentChanged(Microsoft::UI::Xaml::Controls::ColorPicker const& sender,
            Microsoft::UI::Xaml::Controls::ColorChangedEventArgs const& args);

    private:
        void ApplyAccent(Windows::UI::Color const& color);
        void BuildChart();
        void PlaySkinTransition();

        std::vector<implementation::Preset> m_presets;
        std::vector<Microsoft::UI::Xaml::Shapes::Rectangle> m_bars;   // 柱子跟踪当前 accent
    };
}

namespace winrt::ThemeLab::factory_implementation
{
    struct MainWindow : MainWindowT<MainWindow, implementation::MainWindow>
    {
    };
}
