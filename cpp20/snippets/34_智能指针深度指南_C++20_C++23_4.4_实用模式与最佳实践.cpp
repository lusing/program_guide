#include <memory>
#include <cstdio>
#include <filesystem>

// 管理文件资源
struct FileCloser {
    void operator()(FILE* f) const {
        if (f) std::fclose(f);
    }
};

using FilePtr = std::unique_ptr<FILE, FileCloser>;

FilePtr open_file(const std::string& path, const std::string& mode) {
    return FilePtr(std::fopen(path.c_str(), mode.c_str()));
}

// 管理目录句柄
struct DirCloser {
    void operator()(DIR* d) const {
        if (d) closedir(d);
    }
};

using DirPtr = std::unique_ptr<DIR, DirCloser>;
