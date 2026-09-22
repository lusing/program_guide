#include "pch.h"
#include "Converters.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::MvvmApp::implementation
{
    static bool UnboxBool(IInspectable const& value)
    {
        if (auto ref = value.try_as<Windows::Foundation::IReference<bool>>())
        {
            return ref.Value();
        }
        return false;
    }

    Windows::Foundation::IInspectable DoneToTextConverter::Convert(
        IInspectable const& value, Windows::UI::Xaml::Interop::TypeName const&,
        IInspectable const&, hstring const&)
    {
        return box_value(UnboxBool(value) ? L"done!" : L"");
    }

    Windows::Foundation::IInspectable DoneToTextConverter::ConvertBack(
        IInspectable const&, Windows::UI::Xaml::Interop::TypeName const&,
        IInspectable const&, hstring const&)
    {
        throw hresult_not_implemented();
    }

    Windows::Foundation::IInspectable DoneToOpacityConverter::Convert(
        IInspectable const& value, Windows::UI::Xaml::Interop::TypeName const&,
        IInspectable const&, hstring const&)
    {
        return box_value(UnboxBool(value) ? 0.55 : 1.0);
    }

    Windows::Foundation::IInspectable DoneToOpacityConverter::ConvertBack(
        IInspectable const&, Windows::UI::Xaml::Interop::TypeName const&,
        IInspectable const&, hstring const&)
    {
        throw hresult_not_implemented();
    }
}
