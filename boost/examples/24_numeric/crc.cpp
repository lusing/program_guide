// crc.cpp —— Boost.CRC（2001）：循环冗余校验——传输完整性检查的小钢炮。
// 对应文档：docs/24-numeric.md
#include <boost/crc.hpp>
#include <cstring>
#include <iostream>
#include <string>

int main() {
    const char* data = "Boost 教程 CRC 演示";

    // 1) crc_optimal：常用参数组合的预配置（crc32_type = CRC-32/ISO-HDLC）
    boost::crc_32_type crc32;
    crc32.process_bytes(data, std::strlen(data));
    std::cout << "CRC-32 = 0x" << std::hex << crc32.checksum() << std::dec << '\n';

    // 2) 同数据同结果（确定性）
    boost::crc_32_type again;
    again.process_bytes(data, std::strlen(data));
    std::cout << "两次一致? " << (again.checksum() == crc32.checksum()) << '\n';

    // 3) 数据变一个字节，CRC 大变（雪崩效应）
    std::string changed(data);
    changed[0] = 'C';
    boost::crc_32_type c3;
    c3.process_bytes(changed.data(), changed.size());
    std::cout << "改一字节后 0x" << std::hex << c3.checksum() << std::dec
              << "（截然不同）\n";

    // 4) 流式：分块喂数与一次喂相同
    boost::crc_32_type streamed;
    streamed.process_bytes(data, 5);
    streamed.process_bytes(data + 5, std::strlen(data) - 5);
    std::cout << "分块喂 = 一次喂? " << (streamed.checksum() == crc32.checksum()) << '\n';

    // 5) 其他位宽：crc_basic/crc_optimal<16,...> 等按协议选
    boost::crc_ccitt_type ccitt;
    ccitt.process_bytes(data, std::strlen(data));
    std::cout << "CRC-CCITT = 0x" << std::hex << ccitt.checksum() << std::dec << '\n';

    std::cout << "自检通过\n";
    return 0;
}
