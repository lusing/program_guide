#include "pch.h"
#include "MainWindow.xaml.h"

#include <algorithm>

using namespace winrt;
using namespace Microsoft::UI::Xaml;
using namespace Microsoft::UI::Xaml::Controls;

namespace winrt::ScratchPad::implementation
{
    MainWindow::MainWindow()
    {
        InitializeComponent();
        Title(L"ScratchPad");
        // 1000x660 逻辑 = 1750x1155 物理 @175%，装得进 2194x1234 的屏：
        // 超屏会被系统钳制，外部再动窗口又会打烂岛的输入变换（冒烟教训）
        if (auto appWindow = AppWindow())
        {
            // 自定位：任何级联位置下都完整在屏内（出屏底部会吃掉注入点击）
            appWindow.MoveAndResize({ 30, 30, 1750, 1085 });
        }
        AddTab();   // 开场给一个空文档，用户零点击即可输入
    }

    void MainWindow::AddTab()
    {
        hstring name = L"untitled-" + to_hstring(m_docs.size() + 1) + L".txt";

        RichEditBox editor;
        editor.AcceptsReturn(true);
        editor.TextWrapping(TextWrapping::Wrap);
        editor.IsSpellCheckEnabled(false);
        editor.PlaceholderText(L"Type something, select it, then toggle Bold");

        TabViewItem tab;
        tab.Header(box_value(name));
        tab.Content(editor);
        Docs().TabItems().Append(tab);
        Docs().SelectedItem(tab);

        TabEntry entry{ tab, name, false };
        m_docs.push_back(std::move(entry));

        // 9 章：TextChanged 只在用户输入后到（程序化 SetText 也会触发，
        // 用"内容非空才置脏"把开场噪声压到最低）
        editor.TextChanged([this, tab](IInspectable const&, IInspectable const&)
        {
            if (auto entry = FindEntry(tab))
            {
                if (!entry->Dirty)
                {
                    entry->Dirty = true;
                    UpdateStatus(L"editing " + entry->Name);
                }
            }
        });
        editor.Focus(FocusState::Programmatic);
    }

    RichEditBox MainWindow::ActiveEditor()
    {
        if (auto tab = Docs().SelectedItem().try_as<TabViewItem>())
        {
            if (auto editor = tab.Content().try_as<RichEditBox>())
            {
                return editor;
            }
        }
        return nullptr;
    }

    TabEntry* MainWindow::FindEntry(TabViewItem const& tab)
    {
        for (auto& entry : m_docs)
        {
            if (entry.Tab == tab) { return &entry; }
        }
        return nullptr;
    }

    void MainWindow::SaveTab(TabViewItem const& tab)
    {
        auto entry = FindEntry(tab);
        if (!entry) { return; }
        if (auto editor = tab.Content().try_as<RichEditBox>())
        {
            hstring text;
            editor.Document().GetText(Microsoft::UI::Text::TextGetOptions::None, text);
            DocStore::Save(entry->Name, text);
            entry->Dirty = false;
            // 写后回读：状态栏确认"真的落盘了"，冒烟验证也以此为准
            hstring check;
            m_saveProbe = DocStore::Load(entry->Name, check)
                ? (L"verified on disk (" + to_hstring(check.size()) + L" chars)")
                : L"WRITE FAILED";
        }
    }

    void MainWindow::CloseTab(TabViewItem const& tab)
    {
        if (auto it = std::find_if(m_docs.begin(), m_docs.end(),
            [&](TabEntry const& e) { return e.Tab == tab; }); it != m_docs.end())
        {
            m_docs.erase(it);
        }
        uint32_t index = 0;
        if (Docs().TabItems().IndexOf(tab, index))
        {
            Docs().TabItems().RemoveAt(index);
        }
    }

    // ---- 菜单 / 命令栏 / 加速器 共用的命令实现 ----

    void MainWindow::OnNewTab(IInspectable const&, RoutedEventArgs const&)
    {
        AddTab();
        UpdateStatus(L"new tab");
    }

    void MainWindow::OnSave(IInspectable const&, RoutedEventArgs const&)
    {
        if (auto tab = Docs().SelectedItem().try_as<TabViewItem>())
        {
            SaveTab(tab);
            if (auto entry = FindEntry(tab))
            {
                UpdateStatus(L"saved " + entry->Name + L" | " + m_saveProbe);
            }
        }
    }

    void MainWindow::OnExit(IInspectable const&, RoutedEventArgs const&)
    {
        Close();
    }

    void MainWindow::OnSelectAll(IInspectable const&, RoutedEventArgs const&)
    {
        if (auto editor = ActiveEditor())
        {
            // 投影里没有 DocumentRange：SetRange 末点给 INT32_MAX，由文档自行钳制
            editor.Document().Selection().SetRange(0, 0x7FFFFFFF);
        }
    }

    void MainWindow::OnToggleFind(IInspectable const&, RoutedEventArgs const&)
    {
        FindPane().IsExpanded(!FindPane().IsExpanded());
        if (FindPane().IsExpanded())
        {
            FindBox().Focus(FocusState::Programmatic);
        }
    }

    void MainWindow::ToggleBold(bool on)
    {
        if (auto editor = ActiveEditor())
        {
            // 9 章：选区字符格式走 ITextSelection.CharacterFormat，
            // FormatEffect::On/Off 与工具栏开关一一对应
            editor.Document().Selection().CharacterFormat().Bold(
                on ? Microsoft::UI::Text::FormatEffect::On : Microsoft::UI::Text::FormatEffect::Off);
            editor.Focus(FocusState::Programmatic);
            UpdateStatus(on ? L"bold on" : L"bold off");
        }
    }

    void MainWindow::OnBold(IInspectable const& sender, RoutedEventArgs const&)
    {
        if (auto toggle = sender.try_as<AppBarToggleButton>())
        {
            ToggleBold(toggle.IsChecked().Value());
        }
    }

    void MainWindow::OnBoldMenu(IInspectable const&, RoutedEventArgs const&)
    {
        // 菜单入口只做"开"切换并同步工具栏状态（Toggle 的三种效果交给工具栏）
        BoldToggle().IsChecked(true);
        ToggleBold(true);
    }

    // ---- 查找 ----

    void MainWindow::UpdateMatches()
    {
        m_matches.clear();
        if (auto editor = ActiveEditor())
        {
            hstring raw;
            editor.Document().GetText(Microsoft::UI::Text::TextGetOptions::None, raw);
            std::wstring hay{ raw };
            std::wstring needle{ FindBox().Text() };
            if (!needle.empty())
            {
                std::transform(hay.begin(), hay.end(), hay.begin(), ::towlower);
                std::wstring lower{ needle };
                std::transform(lower.begin(), lower.end(), lower.begin(), ::towlower);
                for (size_t pos = hay.find(lower); pos != std::wstring::npos;
                     pos = hay.find(lower, pos + lower.size()))
                {
                    m_matches.push_back(static_cast<uint32_t>(pos));
                }
            }
        }
    }

    void MainWindow::OnFindChanged(IInspectable const&, TextChangedEventArgs const&)
    {
        UpdateMatches();
        if (FindBox().Text().empty())
        {
            UpdateStatus(L"");
        }
        else
        {
            UpdateStatus(to_hstring(m_matches.size()) + L" match(es) for '" + FindBox().Text() + L"'");
        }
    }

    void MainWindow::OnFindNext(IInspectable const&, RoutedEventArgs const&)
    {
        if (m_matches.empty()) { UpdateStatus(L"no matches"); return; }
        m_matchIndex = (m_matchIndex + 1) % m_matches.size();
        uint32_t pos = m_matches[m_matchIndex];
        uint32_t len = static_cast<uint32_t>(std::wstring_view(FindBox().Text()).size());
        if (auto editor = ActiveEditor())
        {
            editor.Document().Selection().SetRange(
                static_cast<int32_t>(pos), static_cast<int32_t>(pos + len));
            editor.Focus(FocusState::Programmatic);
            UpdateStatus(L"match " + to_hstring(m_matchIndex + 1) + L"/" + to_hstring(m_matches.size()));
        }
    }

    // ---- TabView ----

    void MainWindow::OnAddTabButton(IInspectable const&, IInspectable const&)
    {
        AddTab();
    }

    Windows::Foundation::IAsyncAction MainWindow::OnTabCloseRequested(
        TabView const&, TabViewTabCloseRequestedEventArgs const& args)
    {
        auto tab = args.Tab();
        auto entry = FindEntry(tab);
        if (entry && entry->Dirty)
        {
            // 24 章 ContentDialog：未保存确认。WinUI 3 必须显式给 XamlRoot
            ContentDialog dlg;
            dlg.Title(box_value(L"Unsaved changes"));
            dlg.Content(box_value(L"Save '" + entry->Name + L"' before closing the tab?"));
            dlg.PrimaryButtonText(L"Save");
            dlg.SecondaryButtonText(L"Discard");
            dlg.CloseButtonText(L"Cancel");
            dlg.DefaultButton(ContentDialogButton::Primary);
            dlg.XamlRoot(Docs().XamlRoot());

            auto choice = co_await dlg.ShowAsync();
            if (choice == ContentDialogResult::Primary)
            {
                SaveTab(tab);
            }
            else if (choice == ContentDialogResult::None)
            {
                co_return;   // Cancel：什么都不关
            }
        }
        CloseTab(tab);
        if (m_docs.empty())
        {
            AddTab();   // 关到最后一个标签时补一个空文档，窗口不至于空转
        }
        UpdateStatus(L"tab closed");
    }

    // ---- 键盘加速器（与菜单同路径） ----

    void MainWindow::OnSaveKey(Input::KeyboardAccelerator const&, Input::KeyboardAcceleratorInvokedEventArgs const& args)
    {
        args.Handled(true);
        OnSave(nullptr, nullptr);
    }

    void MainWindow::OnNewTabKey(Input::KeyboardAccelerator const&, Input::KeyboardAcceleratorInvokedEventArgs const& args)
    {
        args.Handled(true);
        OnNewTab(nullptr, nullptr);
    }

    void MainWindow::OnFindKey(Input::KeyboardAccelerator const&, Input::KeyboardAcceleratorInvokedEventArgs const& args)
    {
        args.Handled(true);
        OnToggleFind(nullptr, nullptr);
    }

    void MainWindow::OnBoldKey(Input::KeyboardAccelerator const&, Input::KeyboardAcceleratorInvokedEventArgs const& args)
    {
        args.Handled(true);
        BoldToggle().IsChecked(true);   // 同步工具栏状态，让命令入口之间不打架
        ToggleBold(true);
    }

    void MainWindow::UpdateStatus(hstring const& extra)
    {
        hstring text;
        if (auto tab = Docs().SelectedItem().try_as<TabViewItem>())
        {
            if (auto entry = FindEntry(tab))
            {
                text = entry->Name + (entry->Dirty ? L" *" : L"") + (extra.empty() ? L"" : L" | " + extra);
            }
        }
        StatusText().Text(text);
    }
}
