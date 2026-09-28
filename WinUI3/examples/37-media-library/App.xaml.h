#pragma once
#include "App.g.h"

namespace winrt::MediaLibrary::implementation
{
    struct App : AppT<App>
    {
        App();

        void OnLaunched(Microsoft::UI::Xaml::LaunchActivatedEventArgs const& args);

    private:
        Microsoft::UI::Xaml::Window window{ nullptr };
    };
}
