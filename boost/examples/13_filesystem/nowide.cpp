// nowide.cpp —— Boost.Nowide（2019）：Windows 上 UTF-8 无处不在的开关
// 对应文档：docs/13-filesystem.md
// Windows 的 main 拿到的是 ANSI 代码页参数、控制台输出走又一码页——
// 中文路径/中文输出处处乱码。Nowide 把 argv 和 cout 全切到 UTF-8。
#include <boost/nowide/args.hpp>
#include <boost/nowide/fstream.hpp>
#include <boost/nowide/iostream.hpp>
#include <boost/filesystem.hpp>
#include <iostream>

int main(int argc, char** argv) {
    // 1) args：把 argv 转成 UTF-8（Windows 上做了真转换；别的平台空操作）
    boost::nowide::args a(argc, argv);
    std::cout << "参数个数 = " << argc << '\n';

    // 2) nowide::cout：控制台 UTF-8 输出（中文直接打，不用 chcp）
    boost::nowide::cout << "nowide::cout 输出中文无乱码\n";

    // 3) nowide::fstream：文件名可以是任意 Unicode。
    //    坑一：窄字符串路径在 Windows 上按 ANSI 代码页解释（/utf-8 源码里的
    //    中文会变乱码目录名）——路径构造用 L"" 宽字面量才是精确 Unicode
    //    坑二：文件流还开着就 remove 会抛 filesystem_error，未捕获直接
    //    fail-fast 崩溃（0xC0000409）——先关流再删
    boost::filesystem::path dir =
        boost::filesystem::temp_directory_path() / L"中文名称目录";
    boost::filesystem::create_directory(dir);
    {
        boost::nowide::ofstream f(dir / L"文件名.txt");
        f << "内容也是 UTF-8";
    }
    std::string content;
    {
        boost::nowide::ifstream r(dir / L"文件名.txt");
        std::getline(r, content);
    }   // r 在这里析构，文件不再被占用
    std::cout << "读回 = " << content << "（中文路径读写成功）\n";

    boost::filesystem::remove_all(dir);
    std::cout << "自检通过\n";
    return 0;
}
