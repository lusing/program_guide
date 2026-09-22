#pragma once
#include "AutoSuggestPage.g.h"

namespace winrt::BasicGallery::implementation
{
    struct AutoSuggestPage : AutoSuggestPageT<AutoSuggestPage>
    {
        AutoSuggestPage();

        void OnFruitTextChanged(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::AutoSuggestBoxTextChangedEventArgs const& args);
        void OnFruitChosen(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::AutoSuggestBoxSuggestionChosenEventArgs const& args);
        void OnFruitQuerySubmitted(
            Windows::Foundation::IInspectable const& sender,
            Microsoft::UI::Xaml::Controls::AutoSuggestBoxQuerySubmittedEventArgs const& args);

    private:
        Windows::Foundation::Collections::IVector<hstring> m_allFruits{ nullptr };
    };
}

namespace winrt::BasicGallery::factory_implementation
{
    struct AutoSuggestPage : AutoSuggestPageT<AutoSuggestPage, implementation::AutoSuggestPage>
    {
    };
}
