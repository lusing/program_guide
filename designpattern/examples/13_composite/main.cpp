// 13 组合。
#include <cassert>
#include <memory>
#include <print>

#include "composite.hpp"
#include "variant_composite.hpp"

int main() {
    using namespace dp;

    // ---- 树：root( file(1), file(2), sub( file(3) ) ) ----
    auto sub = std::make_unique<Folder>("sub");
    sub->add(std::make_unique<File>("c.txt", 3));

    auto root = std::make_unique<Folder>("root");
    root->add(std::make_unique<File>("a.txt", 1));
    root->add(std::make_unique<File>("b.txt", 2));
    root->add(std::move(sub));

    // 叶 1+2+子夹(3) == 6：调用方对 Folder 与 File 一视同仁
    assert(root->size() == 6);
    assert(root->count() == 3);
    std::println("组合: root.size()=1+2+sub(3)={}", root->size());

    // 子夹自身也是 FsNode：同样的接口继续递归
    assert(root->size() > 0);
    std::println("组合: 子夹透明参与递归（叶与夹同接口）");

    // ---- 现代对照：variant 版同一棵树 ----
    NodeV vroot = make_folder(
        make_file(1),
        make_file(2),
        make_folder(make_file(3)));

    assert(vsize(vroot) == 6);
    assert(vdepth(vroot) == 2);          // root -> sub -> 叶
    std::println("variant: size={} depth={}", vsize(vroot), vdepth(vroot));

    std::println("自检通过");
}
