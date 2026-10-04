#include <algorithm>
#include <cassert>
#include <print>
#include <vector>

#include "advanced_sort.hpp"

// 22 排序（下）：希尔、堆、归并、基数、桶、外部排序模拟

namespace {

// 断言 a 已按非降序排列且长度恰为 n
void assert_sorted(const std::vector<int>& a, std::size_t n) {
    assert(a.size() == n);
    assert(std::is_sorted(a.begin(), a.end()));
}

}  // namespace

int main() {
    const std::vector<int> fixture{3, 1, 4, 1, 5, 9, 2, 6, -3, 0};
    std::vector<int> expected = fixture;
    std::sort(expected.begin(), expected.end());

    // ═══ 四个比较排序对固定夹具 ═══
    {
        std::vector<int> a = fixture;
        ds::shell_sort(a);
        assert(a == expected);
    }
    {
        std::vector<int> a = fixture;
        ds::heap_sort(a);
        assert(a == expected);
    }
    {
        std::vector<int> a = fixture;
        ds::merge_sort(a);
        assert(a == expected);
    }
    {
        std::vector<int> a = fixture;
        ds::bucket_sort(a, -3, 9);
        assert(a == expected);
        std::println("希尔/堆/归并/桶排序：对固定夹具结果均与 std::sort 一致");
    }

    // ═══ 桶分布计数（5 个等宽桶，值域 [-3,9]，范围 13）═══
    {
        const auto counts = ds::bucket_distribution(fixture, -3, 9);
        std::print("桶分布（5 桶）：");
        for (int c : counts) {
            std::print("{} ", c);
        }
        std::println("");
        int total = 0;
        for (int c : counts) {
            total += c;
        }
        assert(total == static_cast<int>(fixture.size()));
    }

    // ═══ 基数排序：非负夹具（固定夹具各值 +3）═══
    {
        std::vector<unsigned int> a;
        for (int x : fixture) {
            a.push_back(static_cast<unsigned int>(x + 3));
        }
        std::vector<unsigned int> want = a;
        std::sort(want.begin(), want.end());
        ds::radix_sort(a);
        assert(a == want);
        std::println("基数排序：非负夹具（原值 +3）升序正确，长度守恒");
    }

    // ═══ 逆序 100 元素 ═══
    {
        std::vector<int> rev(100);
        for (int i = 0; i < 100; ++i) {
            rev[i] = 100 - i;
        }
        std::vector<int> want = rev;
        std::sort(want.begin(), want.end());

        for (auto sort_fn : {ds::shell_sort, ds::heap_sort, ds::merge_sort}) {
            std::vector<int> a = rev;
            sort_fn(a);
            assert(a == want);
        }
        std::println("希尔/堆/归并：对逆序 100 元素结果与 std::sort 一致");
    }

    // ═══ 外部排序模拟：13 个元素、run_size=4，得 4 个归并段 ═══
    {
        const std::vector<int> input{8, 3, 15, 1, 9, 4, 12, 7,
                                     0, 6, 11, 2, 5};
        const std::size_t run_size = 4;
        const std::size_t run_count =
            (input.size() + run_size - 1) / run_size;
        assert(run_count == 4);

        const std::vector<int> merged =
            ds::external_sort_sim(input, run_size);
        assert_sorted(merged, input.size());
        std::println("外部排序模拟：{} 个初始归并段 k 路归并，结果有序且长度守恒",
                     run_count);
    }

    // ═══ 边界：空区间与单元素均不崩 ═══
    {
        std::vector<int> empty;
        ds::shell_sort(empty);
        ds::heap_sort(empty);
        ds::merge_sort(empty);
        ds::bucket_sort(empty, 0, 1);
        std::vector<unsigned int> empty_u;
        ds::radix_sort(empty_u);

        std::vector<int> one{42};
        ds::shell_sort(one);
        ds::heap_sort(one);
        ds::merge_sort(one);
        ds::bucket_sort(one, 0, 100);
        std::vector<unsigned int> one_u{42};
        ds::radix_sort(one_u);
        assert(one[0] == 42 && one_u[0] == 42);
        std::println("边界：空区间与单元素对六种算法均安全");
    }

    // ═══ 前提违规：run_size=0 与 hi<lo 抛异常 ═══
    {
        bool threw_run = false;
        bool threw_bucket = false;
        try {
            ds::external_sort_sim(std::span<const int>{fixture}, 0);
        } catch (const std::invalid_argument&) {
            threw_run = true;
        }
        try {
            std::vector<int> a = fixture;
            ds::bucket_sort(a, 9, -3);
        } catch (const std::invalid_argument&) {
            threw_bucket = true;
        }
        assert(threw_run && threw_bucket);
        std::println("前提违规：run_size=0 与 hi<lo 均抛 invalid_argument");
    }

    std::println("自检通过");
}
