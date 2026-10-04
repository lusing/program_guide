#include <cassert>
#include <print>
#include <span>
#include <string_view>

#include "array_list.hpp"

// 04 顺序表：连续内存上的线性表，按下标一步到位，插入删除需要搬动后继

int main() {
    // 打印整数顺序表内容的小助手；输出只含固定数据
    auto print_seq = [](std::string_view tag, const ds::ArrayList<int>& l) {
        std::print("{}：", tag);
        for (int v : l) {
            std::print("{} ", v);
        }
        std::println();
    };

    // ═══ 构造与尾插 ═══
    ds::ArrayList<int> lst{2, 4, 6};
    assert(lst.size() == 3);
    assert(lst[0] == 2 && lst[1] == 4 && lst[2] == 6);
    lst.push_back(8);
    assert(lst.size() == 4);
    assert(lst[0] == 2 && lst[1] == 4 && lst[2] == 6 && lst[3] == 8);
    print_seq("尾插 8 后", lst);

    // ═══ 中间插入：insert(1,3)，后继整体右移 ═══
    lst.insert(1, 3);
    const ds::ArrayList<int> after_insert{2, 3, 4, 6, 8};
    assert(lst == after_insert);
    print_seq("位置 1 插入 3 后", lst);

    // ═══ 删除：erase(1)，后继整体左移，回到插入前的状态 ═══
    lst.erase(1);
    const ds::ArrayList<int> after_erase{2, 4, 6, 8};
    assert(lst == after_erase);
    print_seq("删除位置 1 后", lst);

    // ═══ 拷贝独立性：改副本不影响原件 ═══
    ds::ArrayList<int> cp = lst;
    assert(cp == lst);
    cp[0] = 20;
    assert(cp[0] == 20);
    assert(lst[0] == 2);
    std::println("拷贝后修改副本：副本首位 {}，原件首位仍为 {}，互不影响", cp[0], lst[0]);

    // ═══ 移动：资源整体转交，源对象变空 ═══
    ds::ArrayList<int> mv = std::move(cp);
    assert(cp.empty());
    assert(mv.size() == 4);
    assert(mv[0] == 20);
    std::println("移动后：源对象为空，移动得到的表首位为 {}", mv[0]);

    // ═══ 编程错误（越界）必须抛异常，两类越界各验证一次 ═══
    bool index_thrown = false;
    try {
        (void)lst[4];
    } catch (const std::out_of_range& e) {
        index_thrown = true;
        std::println("下标越界被捕获：{}", e.what());
    }
    assert(index_thrown);

    bool insert_thrown = false;
    try {
        lst.insert(5, 1);  // 当前长度 4，合法插入位置仅 0..4
    } catch (const std::out_of_range& e) {
        insert_thrown = true;
        std::println("插入位置越界被捕获：{}", e.what());
    }
    assert(insert_thrown);

    // ═══ span 视图与相等语义 ═══
    std::span<int> view = lst.as_span();
    assert(view.size() == lst.size());
    for (size_t i = 0; i < lst.size(); ++i) {
        assert(view[i] == lst[i]);
    }
    ds::ArrayList<int> same{2, 4, 6, 8};
    assert(lst == same);
    same.push_back(0);
    assert(!(lst == same));
    std::println("span 长度与表一致（{}），相等语义：相等为真、改后为假", view.size());

    std::println("自检通过");
}
