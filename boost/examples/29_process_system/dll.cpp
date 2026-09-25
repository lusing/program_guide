// dll.cpp —— Boost.DLL（2014）：运行期加载共享库的跨平台封装。
// 加载本目录 plugin_greeter.cpp 编出的插件（plugin_greeter.dll / .so / .dylib）。
// 对应文档：docs/29-process-system.md
#include <boost/dll.hpp>
#include <boost/dll/import.hpp>
#include <iostream>
#include <string>

namespace dll = boost::dll;

int main() {
    // boost::dll::program_location() 即本 exe 路径；插件产物与 exe 同目录
    // （build.ps1 / run-all.sh 的产物布局保证这一点）。
    //
    // 文件名后缀**不能写死 ".dll"**：Windows 是 .dll，Linux 是 .so，
    // macOS 是 .dylib，写死了换平台必扑空。问 Boost.DLL 自己最稳——
    // 构建脚本（run-all.sh）也用同一个 API 定产物名，两边不会说不到一块去。
    boost::filesystem::path lib_path =
        dll::program_location().parent_path() /
        ("plugin_greeter" + dll::shared_library::suffix().string());
    // 只打文件名不打全路径：全路径里含产物目录（build/shared 与 build/static
    // 不同），会让"两通道输出逐字节一致"这条判定凭空失败——那是构建布局的
    // 差异，不是示例行为的差异。
    std::cout << "插件文件名 = " << lib_path.filename().string() << '\n';

    // 1) shared_library：加载与符号检查
    dll::shared_library lib(lib_path);
    std::cout << "DLL 已加载? " << lib.is_loaded() << '\n';
    std::cout << "有 greet? " << lib.has("greet")
              << " 有 missing? " << lib.has("missing") << '\n';

    // 2) import_symbol：导入函数的正确姿势。
    //    大坑警告：shared_library::get<T>() 会把符号当"T 类型的数据对象"
    //    返回引用——对函数用它，等于把函数机器码字节当指针解引用，
    //    调用即 AV（实测崩溃 0xC0000005 的完整现场）
    auto greet = dll::import_symbol<const char*(const char*)>(lib_path, "greet");
    auto add = dll::import_symbol<int(int, int)>(lib_path, "add");

    std::cout << "greet(boost) = " << greet("boost") << '\n';
    std::cout << "add(3,4) = " << add(3, 4) << '\n';

    // 3) 更进一步：BOOST_DLL_ALIAS 宏可以导出 C++ 符号的稳定别名
    //    （extern "C" 不够时：模板实例/重载函数），见库文档 alias 一节
    std::cout << "自检通过\n";
    return 0;
}
