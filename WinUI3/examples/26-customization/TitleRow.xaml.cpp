#include "pch.h"
#include "TitleRow.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;

namespace winrt::CustomGallery::implementation
{
    TitleRow::TitleRow()
    {
        InitializeComponent();
    }

    hstring TitleRow::Title() { return m_title; }
    void TitleRow::Title(hstring const& value) { m_title = value; }
    hstring TitleRow::Value() { return m_value; }
    void TitleRow::Value(hstring const& value) { m_value = value; }
}
