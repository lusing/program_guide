#pragma once
#include "DateTimePage.g.h"

namespace winrt::BasicGallery::implementation
{
    struct DateTimePage : DateTimePageT<DateTimePage>
    {
        DateTimePage();

        void OnDateChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::DatePickerValueChangedEventArgs const& args);
        void OnTodayClicked(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::RoutedEventArgs const& args);
    };
}

namespace winrt::BasicGallery::factory_implementation
{
    struct DateTimePage : DateTimePageT<DateTimePage, implementation::DateTimePage>
    {
    };
}
