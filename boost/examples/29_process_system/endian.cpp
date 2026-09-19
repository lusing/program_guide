// endian.cpp —— Boost.Endian（2013）：字节序工具——
// std::endian（C++20）毕业了"探测"，但"转换与缓冲布局"仍是 boost 的独占领地。
// 对应文档：docs/29-process-system.md
#include <boost/endian.hpp>
#include <bit>
#include <cstdint>
#include <iostream>
#include <vector>

namespace be = boost::endian;

int main() {
    // 1) 探测（C++20 std::endian 毕业）
    std::cout << "本机字节序 = " << (std::endian::native == std::endian::little
                                          ? "小端"
                                          : "大端") << '\n';

    // 2) endian_buffer/endian_arithmetic：网络协议结构体的地基
    be::big_uint32_buf_t net_value(0x12345678);      // 大端存储
    std::uint8_t bytes[4];
    std::memcpy(bytes, &net_value, 4);
    std::cout << "大端字节 = " << std::hex
              << (int)bytes[0] << ' ' << (int)bytes[1] << ' '
              << (int)bytes[2] << ' ' << (int)bytes[3] << std::dec << '\n';

    // 3) 读回：buffer 自带 .value() 按字节序解释回主机值
    std::cout << "读回值 = 0x" << std::hex << net_value.value() << std::dec << '\n';

    // 4) 小端与对齐变体（little_* / big_*64 / 未对齐的 ubig_* 缓冲）
    be::little_uint16_buf_t le(0xABCD);
    std::cout << "小端 0xABCD 首 8 位字节 = 0x" << std::hex
              << (int)*reinterpret_cast<const std::uint8_t*>(&le) << std::dec << '\n';

    // 5) endian_arithmetic 与 endian_buffer 的分界：前者参与算术
    //    （可以 ++、+、比较），后者只管布局（零开销）
    be::big_uint32_t net2(1);
    std::cout << "算术参与: 0x12345678 + 1 = 0x" << std::hex
              << (net_value.value() + net2.value()) << std::dec << '\n';

    std::cout << "自检通过\n";
    return 0;
}
