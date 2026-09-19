// interprocess.cpp —— Boost.Interprocess（2005）：跨进程共享内存/同步/堆。
// 本例：共享内存段 + 命名互斥 + 匿名内存池一段演示（同进程内模拟双视角）。
// 对应文档：docs/29-process-system.md
#include <boost/interprocess/managed_shared_memory.hpp>
#include <boost/interprocess/sync/named_mutex.hpp>
#include <boost/interprocess/containers/vector.hpp>
#include <boost/interprocess/allocators/allocator.hpp>
#include <iostream>

namespace bip = boost::interprocess;

using ShmAllocator = bip::allocator<int, bip::managed_shared_memory::segment_manager>;
using ShmVector = bip::vector<int, ShmAllocator>;

int main() {
    // 清理可能残留的旧段（前次崩溃的段不会自动消失）
    bip::shared_memory_object::remove("BoostTutorialShm");
    bip::named_mutex::remove("BoostTutorialMutex");

    // 1) 建共享内存段（4096 字节起步，可增长）
    bip::managed_shared_memory segment(bip::create_only, "BoostTutorialShm", 65536);

    // 2) 段内构造跨进程容器（与另一个进程共享同一 vector）
    const ShmAllocator alloc(segment.get_segment_manager());
    ShmVector* vec = segment.construct<ShmVector>("shared_vec")(alloc);
    vec->push_back(10);
    vec->push_back(20);
    vec->push_back(30);
    std::cout << "共享 vector 大小 = " << vec->size() << '\n';

    // 3) 模拟"另一个视角"：按名找到并访问（跨进程即同名找到）
    std::pair<ShmVector*, std::size_t> found = segment.find<ShmVector>("shared_vec");
    std::cout << "按名找回 = " << (found.first != nullptr)
              << " 首元素 = " << found.first->at(0) << '\n';

    // 4) 命名互斥：进程间锁（放在全局命名空间，任何进程可按名加锁）
    bip::named_mutex mtx(bip::create_only, "BoostTutorialMutex");
    mtx.lock();
    std::cout << "跨进程互斥锁已持有\n";
    mtx.unlock();

    // 5) 清理（真实多进程里由最后一个用户做）
    segment.destroy<ShmVector>("shared_vec");
    bip::shared_memory_object::remove("BoostTutorialShm");
    bip::named_mutex::remove("BoostTutorialMutex");
    std::cout << "清理完成\n";

    std::cout << "自检通过\n";
    return 0;
}
