#pragma once
#include "HomePage.g.h"

namespace winrt::ShellGallery::implementation
{
    struct HomePage : HomePageT<HomePage>
    {
        HomePage();
    };
}

namespace winrt::ShellGallery::factory_implementation
{
    struct HomePage : HomePageT<HomePage, implementation::HomePage>
    {
    };
}
