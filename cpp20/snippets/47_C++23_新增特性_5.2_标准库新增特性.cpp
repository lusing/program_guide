#include <system_error>

// 新增错误码
std::error_code ec = std::make_error_code(std::errc::value_too_large);
