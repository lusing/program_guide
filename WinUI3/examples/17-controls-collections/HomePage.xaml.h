#pragma once
#include "HomePage.g.h"

namespace winrt::CollectionsGallery::implementation
{
    struct HomePage : HomePageT<HomePage>
    {
        HomePage();
    };
}

namespace winrt::CollectionsGallery::factory_implementation
{
    struct HomePage : HomePageT<HomePage, implementation::HomePage>
    {
    };
}
