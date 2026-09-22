#include "pch.h"
#include "TaskListPage.xaml.h"
#include "TaskViewModel.h"
#include "Task.h"

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::TaskFlow::implementation
{
    TaskListPage::TaskListPage()
    {
        InitializeComponent();
        m_viewModel = make<TaskViewModel>();
        m_viewModel.Load();
    }

    TaskFlow::TaskViewModel TaskListPage::ViewModel() { return m_viewModel; }

    void TaskListPage::OnAddClicked(IInspectable const&, RoutedEventArgs const&)
    {
        (void)ShowAddDialogAsync();
    }

    Windows::Foundation::IAsyncAction TaskListPage::ShowAddDialogAsync()
    {
        // 24 章模式：ContentDialog 承载自定义表单（TextBox + 重要标记）
        TextBox input;
        input.Header(box_value(L"Task title"));
        input.PlaceholderText(L"what needs doing?");
        CheckBox important;
        important.Content(box_value(L"Important (adds !)"));

        StackPanel form;
        form.Spacing(12);
        form.Margin({ 0, 8, 0, 0 });
        form.Children().Append(input);
        form.Children().Append(important);

        ContentDialog dialog;
        dialog.Title(box_value(L"Add task"));
        dialog.Content(form);
        dialog.PrimaryButtonText(L"Add");
        dialog.CloseButtonText(L"Cancel");
        dialog.DefaultButton(ContentDialogButton::Primary);
        dialog.XamlRoot(rootPanel().XamlRoot());

        auto result = co_await dialog.ShowAsync();
        if (result == ContentDialogResult::Primary)
        {
            m_viewModel.Add(input.Text(), important.IsChecked().Value());
        }
    }

    void TaskListPage::OnRowToggled(IInspectable const& sender, RoutedEventArgs const&)
    {
        // 行内勾选变化：TwoWay 绑定已改 Task.Done，这里只负责持久化
        if (m_viewModel) { (void)m_viewModel.SaveAsync(); }
    }

    void TaskListPage::OnRemoveClicked(IInspectable const& sender, RoutedEventArgs const&)
    {
        auto item = sender.as<FrameworkElement>().DataContext().as<TaskFlow::Task>();
        m_viewModel.Remove(item);
    }
}
