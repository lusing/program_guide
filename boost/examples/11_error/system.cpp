// system.cpp —— Boost.System：error_code 的老家（std::error_code 直系源头）
// 对应文档：docs/11-error.md
#include <boost/system/error_code.hpp>
#include <boost/system/system_category.hpp>
#include <boost/system/system_error.hpp>
#include <iostream>
#include <system_error>

// 自定义错误域（库作者姿势）：errc 枚举 + category 单例 + default_error_condition
namespace mylib {
enum class net_err {
    timeout = 1,
    conn_refused = 2,
};
class net_category_impl : public boost::system::error_category {
public:
    const char* name() const noexcept override { return "mylib.net"; }
    std::string message(int ev) const override {
        switch (static_cast<net_err>(ev)) {
            case net_err::timeout:       return "网络超时";
            case net_err::conn_refused:  return "连接被拒";
        }
        return "未知";
    }
};
const boost::system::error_category& net_category() {
    static net_category_impl inst;
    return inst;
}
}   // namespace mylib

int main() {
    // 1) error_code 的语义："失败描述"，可空（!ec = 没错）。
    //    从自定义枚举构造要显式给 (值, 类别)（std::errc 有特化所以能隐式）
    boost::system::error_code ec(static_cast<int>(mylib::net_err::timeout),
                                 mylib::net_category());
    std::cout << "值=" << ec.value() << " 域=" << ec.category().name()
              << " 消息=" << ec.message() << '\n';

    // 2) 比较与转换：与通用条件等价映射
    std::cout << "是 timeout? " << std::boolalpha
              << (ec.value() == static_cast<int>(mylib::net_err::timeout)) << '\n';

    boost::system::error_code ok;                       // 默认 = 无错
    std::cout << "默认构造无错? " << !ok << '\n';

    // 3) system_error 异常：error_code 的抛出形态
    try {
        throw boost::system::system_error(
            boost::system::error_code(static_cast<int>(mylib::net_err::conn_refused),
                                      mylib::net_category()),
            "connect");
    } catch (const boost::system::system_error& e) {
        std::cout << "捕获 system_error: " << e.code().message() << '\n';
    }

    // 4) std 对照：接口逐字对应（std::error_code 就是照它设计的）
    std::error_code sec = std::make_error_code(std::errc::timed_out);
    std::cout << "std 版: " << sec.message()
              << " (域 " << sec.category().name() << ")\n";

    // 5) POSIX 错误桥接：generic 类别（注意 system_category 的 message 走
    //    Windows ACP 编码，中文系统上打印到 UTF-8 终端会乱码——通用错误
    //    用 generic 类别拿 POSIX 标准消息）
    boost::system::error_code enoent = boost::system::errc::make_error_code(
        boost::system::errc::no_such_file_or_directory);
    std::cout << "ENOENT: 有错=" << std::boolalpha << static_cast<bool>(enoent)
              << " 值=" << enoent.value() << "（generic 类别）\n";

    std::cout << "自定义类别: " << mylib::net_category().name() << '\n';

    std::cout << "自检通过\n";
    return 0;
}
