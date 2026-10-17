// exception.cpp —— Boost.Exception：异常的"随身行李"（exception_ptr 的直系 +
//                  错误信息携带的独门设计）
// 对应文档：docs/11-error.md
#include <boost/exception/all.hpp>
#include <iostream>
#include <string>

struct parse_error : virtual std::exception, virtual boost::exception {};
typedef boost::error_info<struct tag_line, int> line_info;
typedef boost::error_info<struct tag_src, std::string> src_info;

int parse(const std::string& s) {
    if (s.empty()) {
        // 抛出的同时往异常对象里塞任意键值对——不用为每种错误定义新异常类型
        BOOST_THROW_EXCEPTION(parse_error{} << line_info(42) << src_info("config.ini"));
    }
    return std::stoi(s);
}

int main() {
    // 1) catch 处按需取出行李
    try {
        parse("");
    } catch (const boost::exception& e) {
        std::cout << "行号 = " << *boost::get_error_info<line_info>(e) << '\n';
        std::cout << "来源 = " << *boost::get_error_info<src_info>(e) << '\n';
    }

    // 2) 重新抛出 + 追加行李（跨层传递时逐层加上下文）
    try {
        try {
            parse("");
        } catch (boost::exception& e) {
            e << boost::throw_function("outer_handler");   // 追加函数名
            throw;                                          // 原对象重抛（行李保留）
        }
    } catch (const boost::exception& e) {
        std::cout << "重抛后仍能取行号 = " << *boost::get_error_info<line_info>(e) << '\n';
    }

    // 3) 预定义错误信息件：errinfo_errno 会把 errno 翻译成可读消息
    try {
        throw parse_error{} << boost::errinfo_errno(101)         // C 错误码
              << boost::errinfo_api_function("fopen")            // 出错的 API 名
              << boost::errinfo_file_name("a.txt");              // 相关文件
    } catch (const boost::exception& e) {
        // diagnostic_information：把全部行李打成一段诊断文本
        std::string diag = boost::diagnostic_information(e);
        std::cout << "诊断含 errno 译文? "
                  << (diag.find("101") != std::string::npos &&
                      diag.find("fopen") != std::string::npos)
                  << " 含文件名? "
                  << (diag.find("a.txt") != std::string::npos) << '\n';
    }

    // 4) enable_error_info：给"不是 boost::exception 子类"的老异常类
    //    现场装箱（不改动原有异常体系就能塞行李）
    struct legacy_error {};                  // 无任何基类的老异常
    try {
        throw boost::enable_error_info(legacy_error{})   // 包装出双继承的动态类型
              << boost::errinfo_errno(13);
    } catch (const boost::exception& e) {    // 用 boost::exception 才接得住行李
        std::cout << "老异常装箱后能取 errno = "
                  << *boost::get_error_info<boost::errinfo_errno>(e) << '\n';
    }

    // 5) throw_exception：统一的抛出出口（自动装箱 + 可配合 BOOST_NO_EXCEPTIONS
    //    的无异常构建），要求实参是 std::exception 子类
    try {
        boost::throw_exception(std::runtime_error("from throw_exception"));
    } catch (const std::exception& e) {
        std::cout << "throw_exception 抛出: " << (std::string(e.what()).substr(0, 12))
                  << "...\n";
    }

    // 6) std 侧对照：exception_ptr 的跨线程搬运（boost 首创语义，C++11 毕业）
    std::exception_ptr ep;
    try {
        parse("");
    } catch (...) {
        ep = std::current_exception();   // 捕获为值
    }
    int rethrown = 0;
    try {
        if (ep) std::rethrow_exception(ep);
    } catch (const parse_error&) {
        rethrown = 1;
    }
    std::cout << "exception_ptr 搬运后重抛成功? " << std::boolalpha
              << (rethrown == 1) << '\n';

    std::cout << "自检通过\n";
    return 0;
}
