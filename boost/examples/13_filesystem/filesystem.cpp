// filesystem.cpp —— Boost.Filesystem（2002）：路径/文件操作（std::filesystem 直系，
// 作者 Beman Dawes 后来亲手把它送进了 C++17）
// 对应文档：docs/13-filesystem.md
#include <boost/filesystem.hpp>
#include <boost/filesystem/fstream.hpp>   // fs::ofstream 才吃 fs::path
#include <filesystem>
#include <iostream>

namespace fs = boost::filesystem;

int main() {
    fs::path dir = fs::temp_directory_path() / "boost_tutorial_demo";
    fs::create_directories(dir);

    // 1) path 的可组合语法（/ 运算符）
    fs::path file = dir / "data.txt";
    std::cout << "目录 = " << dir << '\n';
    std::cout << "文件名 = " << file.filename()
              << " 扩展名 = " << file.extension() << '\n';

    // 2) 写 + 读 + 查询
    { fs::ofstream(file) << "hello fs"; }
    std::cout << "存在? " << fs::exists(file)
              << " 大小 = " << fs::file_size(file) << '\n';

    // 3) 遍历目录（directory_iterator）
    fs::path sub = dir / "sub";
    fs::create_directory(sub);
    { fs::ofstream(sub / "a.log") << "x"; }
    { fs::ofstream(sub / "b.log") << "y"; }
    int count = 0;
    for (const auto& entry : fs::directory_iterator(dir)) {
        (void)entry;
        ++count;
    }
    std::cout << "目录下条目数 = " << count << "（data.txt + sub）\n";

    // 4) 递归遍历 + 谓词
    int logs = 0;
    for (const auto& entry : fs::recursive_directory_iterator(dir)) {
        if (entry.is_regular_file() && entry.path().extension() == ".log") ++logs;
    }
    std::cout << "递归找到 .log = " << logs << " 个\n";

    // 5) std 对照（C++17 毕业，接口几乎逐字相同）
    std::filesystem::path sfile = file.string();   // boost↔std path 不互通，经 string 转
    std::cout << "std 版文件名 = " << sfile.filename() << '\n';

    // 清理
    fs::remove_all(dir);
    std::cout << "清理后存在? " << fs::exists(dir) << '\n';

    std::cout << "自检通过\n";
    return 0;
}
