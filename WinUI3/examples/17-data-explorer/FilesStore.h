#pragma once

#include "pch.h"

namespace winrt::DataExplorer::implementation
{
    // The explorer's static data set: four categories, a dozen rows.
    struct FilesStore
    {
        static Windows::Foundation::Collections::IVector<winrt::DataExplorer::FileItem> All();
    };
}
