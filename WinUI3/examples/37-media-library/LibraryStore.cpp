// LibraryStore.cpp -- SQLite via the C amalgamation vendored in thirdparty/.
// The prepared-statement pattern (prepare -> bind -> step -> column -> reset)
// is the whole story of this file; see docs/37-sqlite-storage.md 37.3.
#include "pch.h"
#include "LibraryStore.h"

#include "thirdparty/sqlite3.h"
#include <filesystem>

namespace MediaStore
{
    namespace
    {
        // RAII guard so an early return cannot leak a prepared statement.
        struct Statement
        {
            Statement(sqlite3* db, wchar_t const* sql) : m_db{ db }
            {
                // sqlite3_prepare16_v2 takes UTF-16 SQL text -- no hstring/wstring
                // conversion to UTF-8 needed on Windows.
                int rc = sqlite3_prepare16_v2(db, sql, -1, &m_stmt, nullptr);
                if (rc != SQLITE_OK)
                {
                    throw std::runtime_error("sqlite3_prepare16_v2 failed");
                }
            }
            ~Statement() { if (m_stmt) { sqlite3_finalize(m_stmt); } }

            sqlite3_stmt* Handle() { return m_stmt; }

        private:
            sqlite3* m_db;
            sqlite3_stmt* m_stmt{ nullptr };
        };

        std::wstring ColumnText(sqlite3_stmt* stmt, int col)
        {
            auto const* text = reinterpret_cast<wchar_t const*>(sqlite3_column_text16(stmt, col));
            return text ? std::wstring{ text } : std::wstring{};
        }
    }

    LibraryStore::LibraryStore() = default;

    LibraryStore::~LibraryStore()
    {
        if (m_db) { sqlite3_close(m_db); }
    }

    std::wstring LibraryStore::Open(std::wstring const& directory)
    {
        // std::filesystem::create_directories creates the whole chain
        // (%LOCALAPPDATA%\MediaLibrary) and is a no-op when it already exists.
        std::error_code ec;
        std::filesystem::create_directories(directory, ec);

        m_path = directory + L"\\media.db";

        // FULLMUTEX: sqlite3 is compiled threadsafe here, but the mutex makes
        // sharing one handle across the UI/background switch safe by default.
        int rc = sqlite3_open16(m_path.c_str(), &m_db);
        if (rc != SQLITE_OK)
        {
            m_db = nullptr;
            throw std::runtime_error("sqlite3_open16 failed");
        }

        EnsureSchema();
        SeedIfEmpty();

        int64_t rows = 0;
        {
            Statement count{ m_db, L"SELECT COUNT(*) FROM MediaItems" };
            if (sqlite3_step(count.Handle()) == SQLITE_ROW)
            {
                rows = sqlite3_column_int64(count.Handle(), 0);
            }
        }
        return L"sqlite ready: " + std::to_wstring(rows) + L" rows";
    }

    void LibraryStore::EnsureSchema()
    {
        // IF NOT EXISTS keeps this idempotent on every launch.
        wchar_t const* sql =
            L"CREATE TABLE IF NOT EXISTS MediaItems ("
            L"  Id INTEGER PRIMARY KEY AUTOINCREMENT,"
            L"  Name NVARCHAR(200) NOT NULL,"
            L"  Category NVARCHAR(20) NOT NULL,"
            L"  Location NVARCHAR(20) NOT NULL)";

        // 注意：sqlite3_exec 只有 UTF-8 版本（没有 exec16）。UTF-16 SQL 走
        // prepare16_v2 + step，与下面的增删查同一套准备语句模式。
        Statement create{ m_db, sql };
        if (sqlite3_step(create.Handle()) != SQLITE_DONE)
        {
            throw std::runtime_error("CREATE TABLE failed");
        }
    }

    void LibraryStore::SeedIfEmpty()
    {
        int64_t rows = 0;
        {
            Statement count{ m_db, L"SELECT COUNT(*) FROM MediaItems" };
            if (sqlite3_step(count.Handle()) == SQLITE_ROW)
            {
                rows = sqlite3_column_int64(count.Handle(), 0);
            }
        }
        if (rows > 0) { return; }

        // First launch: the same seed set as the book's My Media Collection.
        struct { wchar_t const* name; wchar_t const* cat; } seed[] = {
            { L"Classical Favorites", L"Music" },
            { L"Classic Fairy Tales", L"Book" },
            { L"The Mummy (Blu-ray)", L"Video" },
        };
        for (auto const& s : seed)
        {
            Statement insert{ m_db,
                L"INSERT INTO MediaItems (Name, Category, Location) VALUES (?1, ?2, 'InCollection')" };
            // Parameter indices are 1-based; SQLITE_TRANSIENT asks sqlite to copy
            // the buffer immediately so the caller's string can go out of scope.
            sqlite3_bind_text16(insert.Handle(), 1, s.name, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text16(insert.Handle(), 2, s.cat, -1, SQLITE_TRANSIENT);
            if (sqlite3_step(insert.Handle()) != SQLITE_DONE)
            {
                throw std::runtime_error("seed INSERT failed");
            }
        }
    }

    std::vector<MediaRow> LibraryStore::List(std::wstring const& categoryFilter) const
    {
        std::vector<MediaRow> result;

        // The filter is bound, never string-concatenated: that is the whole
        // point of prepared statements (SQL injection + reuse).
        Statement list{ m_db,
            L"SELECT Id, Name, Category, Location FROM MediaItems "
            L"WHERE ?1 = 'All' OR Category = ?1 ORDER BY Name" };

        sqlite3_bind_text16(list.Handle(), 1, categoryFilter.c_str(), -1, SQLITE_TRANSIENT);

        while (sqlite3_step(list.Handle()) == SQLITE_ROW)
        {
            MediaRow row;
            row.id = sqlite3_column_int64(list.Handle(), 0);
            row.name = ColumnText(list.Handle(), 1);
            row.category = ColumnText(list.Handle(), 2);
            row.location = ColumnText(list.Handle(), 3);
            result.push_back(std::move(row));
        }
        return result;
    }

    int64_t LibraryStore::Insert(std::wstring const& name, std::wstring const& category)
    {
        Statement insert{ m_db,
            L"INSERT INTO MediaItems (Name, Category, Location) VALUES (?1, ?2, 'Digital')" };
        sqlite3_bind_text16(insert.Handle(), 1, name.c_str(), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text16(insert.Handle(), 2, category.c_str(), -1, SQLITE_TRANSIENT);
        if (sqlite3_step(insert.Handle()) != SQLITE_DONE)
        {
            throw std::runtime_error("INSERT failed");
        }
        return sqlite3_last_insert_rowid(m_db);   // AUTOINCREMENT key of the row just written
    }

    void LibraryStore::Remove(int64_t id)
    {
        Statement remove{ m_db, L"DELETE FROM MediaItems WHERE Id = ?1" };
        sqlite3_bind_int64(remove.Handle(), 1, id);
        if (sqlite3_step(remove.Handle()) != SQLITE_DONE)
        {
            throw std::runtime_error("DELETE failed");
        }
    }
}
