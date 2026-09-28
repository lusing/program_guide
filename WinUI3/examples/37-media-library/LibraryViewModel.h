// ViewModels/LibraryViewModel.h -- see docs/37-sqlite-storage.md 37.4.
#pragma once
#include "LibraryViewModel.g.h"
#include "LibraryStore.h"

namespace winrt::MediaLibrary::implementation
{
    struct LibraryViewModel : LibraryViewModelT<LibraryViewModel>
    {
        LibraryViewModel();

        // INotifyPropertyChanged
        winrt::event_token PropertyChanged(
            Microsoft::UI::Xaml::Data::PropertyChangedEventHandler const& handler);
        void PropertyChanged(winrt::event_token const& token);

        winrt::hstring Status();
        void Status(winrt::hstring const& value);
        winrt::hstring DbPath() { return m_dbPath; }
        bool HasSelection() const { return m_hasSelection; }
        void HasSelection(bool value);

        winrt::Windows::Foundation::Collections::IObservableVector<
            winrt::MediaLibrary::MediaItem> Items();

        winrt::hstring SelectedCategory();
        void SelectedCategory(winrt::hstring const& value);

        void AddItem();
        void DeleteSelected();
        void SelectItem(winrt::MediaLibrary::MediaItem const& item);
        void ClearSelection();

        // Startup: open the database on a background thread, then refresh on the
        // UI thread. Fire-and-forget from the window; holds a strong reference.
        winrt::Windows::Foundation::IAsyncAction InitializeAsync();

    private:
        winrt::event<Microsoft::UI::Xaml::Data::PropertyChangedEventHandler>
            m_propertyChanged;
        winrt::Windows::Foundation::Collections::IObservableVector<
            winrt::MediaLibrary::MediaItem> m_items{ nullptr };

        MediaStore::LibraryStore m_store;
        winrt::MediaLibrary::MediaItem m_selectedItem{ nullptr };
        bool m_hasSelection{ false };
        winrt::hstring m_status;
        winrt::hstring m_selectedCategory{ L"All" };
        winrt::hstring m_dbPath;
        int m_addedCount{ 0 };

        // The queue the WinUI 3 UI thread actually pumps (32.7: resume_foreground
        // never resumes here; TryEnqueue is the supported switch-back).
        Microsoft::UI::Dispatching::DispatcherQueue m_dispatcherQueue{ nullptr };

        void RaisePropertyChanged(winrt::hstring const& propertyName);
        winrt::Windows::Foundation::IAsyncAction ReloadAsync(
            std::wstring statusPrefix, std::wstring statusSuffix);
        winrt::Windows::Foundation::IAsyncAction AddItemAsync(
            std::wstring name, std::wstring category);
        winrt::Windows::Foundation::IAsyncAction DeleteItemAsync(int64_t id);
    };
}

namespace winrt::MediaLibrary::factory_implementation
{
    struct LibraryViewModel : LibraryViewModelT<LibraryViewModel, implementation::LibraryViewModel>
    {
    };
}
