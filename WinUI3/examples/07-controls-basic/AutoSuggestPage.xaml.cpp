#include "pch.h"
#include "AutoSuggestPage.xaml.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::BasicGallery::implementation
{
    AutoSuggestPage::AutoSuggestPage()
    {
        InitializeComponent();
        m_allFruits = single_threaded_vector<hstring>({
            L"apple", L"apricot", L"avocado",
            L"banana", L"blueberry",
            L"cherry", L"coconut",
        });
    }

    void AutoSuggestPage::OnFruitTextChanged(IInspectable const&,
        AutoSuggestBoxTextChangedEventArgs const& args)
    {
        if (!FruitBox() || !m_allFruits) return;

        // 关键机制：Reason 区分用户输入与程序性变更（更新 ItemsSource 引发的
        // Text 变化是 Programmatic），防止"过滤 -> 设列表 -> 再过滤"的重入
        if (args.Reason() != AutoSuggestionBoxTextChangeReason::UserInput) return;

        auto text = FruitBox().Text();
        auto filtered = single_threaded_vector<hstring>();
        for (auto const& fruit : m_allFruits)
        {
            if (fruit.starts_with(text)) filtered.Append(fruit);
        }
        FruitBox().ItemsSource(filtered);
    }

    void AutoSuggestPage::OnFruitChosen(IInspectable const&,
        AutoSuggestBoxSuggestionChosenEventArgs const& args)
    {
        if (!StatusText()) return;
        StatusText().Text(L"chosen = " + args.SelectedItem().as<hstring>());
    }

    void AutoSuggestPage::OnFruitQuerySubmitted(IInspectable const&,
        AutoSuggestBoxQuerySubmittedEventArgs const& args)
    {
        if (!StatusText()) return;
        // 回车/提交：QueryText 是框里的原文（可能是没选建议的自由文本）
        StatusText().Text(L"query = " + args.QueryText());
    }
}
