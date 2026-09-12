#include <memory>
#include <filesystem>

// C++23: unique_ptr 对文件句柄的支持更完善
auto file_deleter = [](FILE* f) {
    if (f) fclose(f);
};

std::unique_ptr<FILE, decltype(file_deleter)>
    file(fopen("test.txt", "r"), file_deleter);
