// Converters.h -- IValueConverter implementations, see docs/32-binding-mvvm.md 32.8
#pragma once
#include "DoneToTextConverter.g.h"
#include "DoneToOpacityConverter.g.h"

namespace winrt::MvvmApp::implementation
{
    // bool(done) -> "done!" / ""
    struct DoneToTextConverter : DoneToTextConverterT<DoneToTextConverter>
    {
        Windows::Foundation::IInspectable Convert(
            Windows::Foundation::IInspectable const& value,
            Windows::UI::Xaml::Interop::TypeName const& targetType,
            Windows::Foundation::IInspectable const& parameter,
            hstring const& language);

        Windows::Foundation::IInspectable ConvertBack(
            Windows::Foundation::IInspectable const& value,
            Windows::UI::Xaml::Interop::TypeName const& targetType,
            Windows::Foundation::IInspectable const& parameter,
            hstring const& language);
    };

    // bool(done) -> 0.55 / 1.0
    struct DoneToOpacityConverter : DoneToOpacityConverterT<DoneToOpacityConverter>
    {
        Windows::Foundation::IInspectable Convert(
            Windows::Foundation::IInspectable const& value,
            Windows::UI::Xaml::Interop::TypeName const& targetType,
            Windows::Foundation::IInspectable const& parameter,
            hstring const& language);

        Windows::Foundation::IInspectable ConvertBack(
            Windows::Foundation::IInspectable const& value,
            Windows::UI::Xaml::Interop::TypeName const& targetType,
            Windows::Foundation::IInspectable const& parameter,
            hstring const& language);
    };
}

namespace winrt::MvvmApp::factory_implementation
{
    struct DoneToTextConverter : DoneToTextConverterT<DoneToTextConverter, implementation::DoneToTextConverter>
    {
    };

    struct DoneToOpacityConverter : DoneToOpacityConverterT<DoneToOpacityConverter, implementation::DoneToOpacityConverter>
    {
    };
}
