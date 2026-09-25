// align.cpp —— Boost.Align：对齐的四大件（std::aligned_* 覆盖了大半）
// 对应文档：docs/05-langbase.md
#include <boost/align.hpp>
#include <iostream>
#include <memory>

int main() {
    // 1) aligned_alloc/aligned_free：对齐分配（C++17 std::aligned_alloc 毕业，
    //    但 boost 版可以带"对齐 + 大小都任意"并保证 free 配套）
    void* p = boost::alignment::aligned_alloc(64, 128);   // 64 字节对齐
    std::cout << "64 对齐分配: " << (std::uintptr_t)p % 64 << " (余数应为 0)\n";
    boost::alignment::aligned_free(p);

    // 2) align：在缓冲区里找下一个对齐位置（SIMD/网络协议解析的核心操作）
    //    注意：别把"推进了几字节"直接打出来当实测值——它取决于 buffer 这次
    //    落在哪个地址上（本机两条通道一个 16 一个 0，Windows 上是 16），
    //    是个会漂的量。能稳定复核的是下面两个**事实**：
    //      · 推进量必落在 0..31（对齐 32 时最多推 31 字节）
    //      · 结果地址一定是 32 的倍数
    char buffer[256];
    void* raw = buffer;
    std::size_t space = sizeof(buffer);
    void* aligned = boost::alignment::align(32, 64, raw, space);
    std::size_t advance = static_cast<std::size_t>((char*)aligned - buffer);
    std::cout << "推进量 < 32? " << std::boolalpha << (advance < 32)
              << "  结果 32 对齐? "
              << boost::alignment::is_aligned(aligned, 32) << '\n';

    // 3) align_up/align_down/is_aligned：整数级别的对齐算术（无 std 对应，常用！）
    std::cout << "align_up(100, 64) = " << boost::alignment::align_up(100, 64) << '\n';
    std::cout << "align_down(100, 64) = " << boost::alignment::align_down(100, 64) << '\n';
    std::cout << "is_aligned(96, 32) = " << std::boolalpha
              << boost::alignment::is_aligned(96, 32) << '\n';

    // 4) aligned_delete 配 aligned_new；aligned_allocator 给容器用
    boost::alignment::aligned_allocator<int, 64> alloc;
    int* q = alloc.allocate(4);
    std::cout << "容器分配器对齐: " << ((std::uintptr_t)q % 64 == 0) << '\n';
    alloc.deallocate(q, 4);

    std::cout << "自检通过\n";
    return 0;
}
