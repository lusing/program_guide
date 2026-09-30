// ============================================================
// cppgui_jthread.hpp —— std::jthread 的最小兼容层（macOS/Linux 用）
//
// 背景：std::jthread 是 C++20 特性，MSVC 完整支持；Apple clang 的
// libc++ 仍缺 jthread/stop_token。本指南 15/18/19 三章对 jthread 的
// 用法只有一种：后台有限循环线程 + 析构自动 join（不使用 stop_token
// 协作取消）。据此提供等价替换：
//   * 有 __cpp_lib_jthread 的标准库（MSVC 等）：using 别名，零变化
//   * 其他（Apple libc++ 等）：std::thread 包装，析构时 join
// 用法与 std::jthread 一致：cppgui::jthread t([]{ ... }); // 作用域
// 结束自动 join；支持默认构造 + 移动赋值（赋值前先汇合旧线程）。
// ============================================================
#pragma once
#include <thread>
#include <type_traits>
#include <utility>

namespace cppgui
{
#if defined(__cpp_lib_jthread)
using jthread = std::jthread;   // 原生 jthread：行为零变化
#else
class jthread
{
public:
    jthread() = default;
    template <class F,
              class = std::enable_if_t<!std::is_same_v<std::decay_t<F>, jthread>>>
    explicit jthread(F&& f) : t_(std::forward<F>(f)) {}
    ~jthread() { if (t_.joinable()) t_.join(); }   // jthread 语义：析构即汇合
    jthread(jthread&& other) noexcept : t_(std::move(other.t_)) {}
    jthread& operator=(jthread&& other) noexcept
    {
        if (this != &other)
        {
            if (t_.joinable()) t_.join();   // 赋值前先汇合旧线程（jthread 语义）
            t_ = std::move(other.t_);
        }
        return *this;
    }
    jthread(const jthread&)            = delete;
    jthread& operator=(const jthread&) = delete;
    void join() { t_.join(); }
    bool joinable() const { return t_.joinable(); }
private:
    std::thread t_;
};
#endif
} // namespace cppgui
