// LibraryStore.h -- the SQLite data layer (docs/37-sqlite-storage.md).
// Plain C++ (not a runtime class): the ViewModel is the only consumer, and
// keeping the DB layer free of WinRT types makes it testable in isolation.
// Every method runs on whatever thread calls it -- the ViewModel switches to
// a background thread before calling in (32.7 discipline).
#pragma once

#include <string>
#include <vector>

struct sqlite3;

namespace MediaStore
{
    struct MediaRow
    {
        int64_t id{};
        std::wstring name;
        std::wstring category;   // Book / Music / Video
        std::wstring location;   // InCollection / Digital
    };

    class LibraryStore
    {
    public:
        LibraryStore();
        ~LibraryStore();

        LibraryStore(LibraryStore const&) = delete;
        LibraryStore& operator=(LibraryStore const&) = delete;

        // Opens (creating directories on demand) or reuses media.db.
        // Returns a human-readable status line for the UI.
        std::wstring Open(std::wstring const& directory);

        std::vector<MediaRow> List(std::wstring const& categoryFilter) const;
        int64_t Insert(std::wstring const& name, std::wstring const& category);
        void Remove(int64_t id);

        std::wstring const& Path() const { return m_path; }
        bool IsOpen() const { return m_db != nullptr; }

    private:
        void EnsureSchema();
        void SeedIfEmpty();

        sqlite3* m_db{ nullptr };
        std::wstring m_path;
    };
}
