// scope.cpp —— Boost.Scope（1.84 起）：统一的作用域守卫家族。
// scope_exit 老库（2007）并入：失败/成功/通用退出三件套 + unique_resource。
// 对应文档：docs/31-runtime-structures.md
#include <boost/scope/scope_exit.hpp>
#include <boost/scope/scope_fail.hpp>
#include <boost/scope/scope_success.hpp>
#include <boost/scope/unique_resource.hpp>
#include <iostream>
#include <cstdio>

int main() {
    // 1) scope_exit：无论成败都执行（最常用——清理）
    {
        boost::scope::scope_exit finally{[] { std::cout << "  [退出清理]\n"; }};
        std::cout << "工作 1\n";
    }   // 触发清理

    // 2) scope_fail：仅异常路径执行（回滚）
    {
        boost::scope::scope_fail rollback{[] { std::cout << "  [失败回滚]\n"; }};
        std::cout << "工作 2（不抛，不触发回滚）\n";
    }
    try {
        boost::scope::scope_fail rollback{[] { std::cout << "  [失败回滚触发了]\n"; }};
        throw std::runtime_error("boom");
    } catch (const std::exception&) {
        std::cout << "捕获后继续\n";
    }

    // 3) scope_success：仅成功路径（提交）
    {
        boost::scope::scope_success commit{[] { std::cout << "  [成功提交]\n"; }};
        std::cout << "工作 3\n";
    }

    // 4) unique_resource：RAII 资源的完全体。
    //    规范入口是工厂函数：make_unique_resource_checked 专治"fopen 失败
    //    返回 NULL"这类语义（NULL 时不会拿去调 fclose）
    //（fopen 有 MSVC 安全告警 C4996，教学场景按原样使用 POSIX 形态）
#if defined(_MSC_VER)   // MSVC 专用：clang/GCC 认不出会报 -Wunknown-pragmas
#pragma warning(push)
#pragma warning(disable : 4996)
#endif
    auto file = boost::scope::make_unique_resource_checked(
        std::fopen("build_scope_demo.txt", "w"), nullptr, &std::fclose);
#if defined(_MSC_VER)   // MSVC 专用：clang/GCC 认不出会报 -Wunknown-pragmas
#pragma warning(pop)
#endif
    if (file.get() != nullptr) {
        std::fputs("unique_resource write", file.get());
        std::cout << "文件句柄有效，离开作用域自动 fclose\n";
    }

    // 5) 主动解除（active 控制）
    {
        boost::scope::scope_exit g{[] { std::cout << "  [被解除后不执行]\n"; }};
        g.set_active(false);
    }
    std::cout << "（上一行没有触发清理——解除成功）\n";

    std::cout << "自检通过\n";
    return 0;
}
