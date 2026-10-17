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

    // 6) path 分解全家：一串成员函数把路径拆成零件（书 ch10.4）
    fs::path p = "C:/boost/boost/filesystem/path.hpp";
    std::cout << "分解: root_name=" << p.root_name()
              << " 有根目录? " << p.has_root_directory()
              << " parent=" << p.parent_path()
              << " stem=" << p.stem()
              << " ext=" << p.extension() << '\n';
    fs::path q = p;
    q.replace_extension(".hxx");
    std::cout << "改扩展名后文件名 = " << q.filename() << '\n';
    // path 自身可迭代：每段一个元素（根目录也占一段）
    std::cout << "路径迭代:";
    for (const auto& part : fs::path("/boost/tools/libs")) std::cout << '[' << part << ']';
    std::cout << '\n';

    // 7) 文件操作与属性：rename/copy(带选项)、空间、修改时间
    fs::path copy1 = dir / "copy.dat";
    fs::copy_file(file, copy1, fs::copy_options::overwrite_existing);
    fs::rename(copy1, dir / "renamed.dat");
    std::cout << "改名后的文件存在? " << fs::exists(dir / "renamed.dat") << '\n';
    auto t = fs::last_write_time(file);       // boost 版返回 std::time_t
    std::cout << "修改时间非零? " << (t != std::time_t{}) << '\n';
    fs::space_info si = fs::space(dir);
    std::cout << "磁盘: 容量>0? " << (si.capacity > 0)
              << " 可用>0? " << (si.available > 0) << '\n';

    // 清理
    fs::remove_all(dir);
    std::cout << "清理后存在? " << fs::exists(dir) << '\n';

    std::cout << "自检通过\n";
    return 0;
}
