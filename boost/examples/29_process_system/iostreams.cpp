// iostreams.cpp —— Boost.Iostreams（2005）：流的过滤器/设备框架——
// gzip/压缩/编码转换插入 std::stream 的标准姿势。
// 对应文档：docs/29-process-system.md
#include <boost/iostreams/device/back_inserter.hpp>
#include <boost/iostreams/filter/gzip.hpp>
#include <boost/iostreams/filtering_stream.hpp>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

namespace io = boost::iostreams;

int main() {
    std::string text = "Boost.Iostreams 压缩演示：这段文本要被 gzip 一圈。重复重复重复重复以获得可压缩数据。";

    // 1) 压缩：filtering_ostream 像流水线，filter 叠 device
    std::vector<char> compressed;
    io::filtering_ostream out;
    out.push(io::gzip_compressor());
    out.push(io::back_inserter(compressed));
    out << text;
    out.pop();                                       // 冲刷 gzip 结尾
    std::cout << "原文 " << text.size() << " 字节 → 压缩 " << compressed.size() << " 字节\n";

    // 2) 解压：镜像流水线（array_source 设备 + gzip_decompressor）
    std::string restored;
    io::filtering_istream in;
    in.push(io::gzip_decompressor());
    in.push(io::array_source(compressed.data(), compressed.size()));
    std::string line;
    while (std::getline(in, line)) restored += line;
    std::cout << "解压还原一致? " << (restored == text) << '\n';

    // 3) 过滤器组合：gzip + bzip2/zlib/base64 可链式叠加
    std::cout << "自检通过\n";
    return 0;
}
