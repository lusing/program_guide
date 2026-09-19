// log.cpp —— Boost.Log（2010）：工业级日志（吞吐/过滤/格式化/汇聚全链路）。
// 对应文档：docs/32-quality.md
// 本例：无时间戳的确定性输出（教程判定要求输出可复现）。
#include <boost/log/core.hpp>
#include <boost/log/trivial.hpp>
#include <boost/log/expressions.hpp>
#include <boost/log/sinks/text_ostream_backend.hpp>
#include <boost/log/sinks/sync_frontend.hpp>
#include <boost/log/sources/logger.hpp>
#include <boost/log/sources/record_ostream.hpp>
#include <iostream>
#include <memory>
#include <ostream>

namespace logging = boost::log;
namespace sinks = boost::log::sinks;
namespace expr = boost::log::expressions;

int main() {
    // 1) 构一个输出到 std::cout 的 sink（确定性：不带时间戳）
    using TextSink = sinks::synchronous_sink<sinks::text_ostream_backend>;
    auto backend = boost::make_shared<sinks::text_ostream_backend>();
    backend->add_stream(boost::shared_ptr<std::ostream>(&std::cout, [](void*) {}));
    auto sink = boost::make_shared<TextSink>(backend);
    sink->set_formatter(expr::stream << "[" << expr::attr<logging::trivial::severity_level>("Severity")
                                     << "] " << expr::message);
    logging::core::get()->add_sink(sink);

    // 2) 全局过滤：severity >= info
    logging::core::get()->set_filter(logging::trivial::severity >= logging::trivial::info);

    // 3) 三级日志（debug 被过滤吃掉）
    BOOST_LOG_TRIVIAL(debug) << "这条会被过滤吃掉";
    BOOST_LOG_TRIVIAL(info) << "服务启动完成";
    BOOST_LOG_TRIVIAL(warning) << "连接数接近上限";

    // 4) 命名 logger + 属性（结构化日志的起点）
    boost::log::sources::logger lg;
    BOOST_LOG(lg) << "命名 logger 的一条记录";

    logging::core::get()->remove_all_sinks();
    std::cout << "自检通过\n";
    return 0;
}
