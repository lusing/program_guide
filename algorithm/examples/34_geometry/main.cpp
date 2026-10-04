// 34 计算几何（CLRS 第 33 章）。结构：34.1 叉积与方向判断 /
// 34.2 线段相交判定（含边界情形）/ 34.3 Graham 扫描凸包 /
// 34.4 最近点对（分治 vs 暴力对账）。全程整数坐标——零浮点，
// 三通道对账天然精确（计划注记）。
#ifdef ALGO_NO_PRINT
#include <cstdio>
#include <format>
template <class... A> void print(std::format_string<A...> f, A&&... a) {
    std::printf("%s", std::format(f, std::forward<A>(a)...).c_str()); }
template <class... A> void println(std::format_string<A...> f, A&&... a) {
    std::printf("%s\n", std::format(f, std::forward<A>(a)...).c_str()); }
#else
#include <print>
using std::print;
using std::println;
#endif

#include <algorithm>
#include <cassert>
#include <cstdint>
#include <vector>

struct Pt { long long x, y; };

// 叉积 (p2−p1) × (p3−p1)：>0 左转（逆时针）、<0 右转、=0 共线
static long long cross(Pt p1, Pt p2, Pt p3) {
    return (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x);
}

static void cross_demo() {
    const Pt o{0, 0}, a{4, 4}, b{8, 0}, c{2, 2};
    println("叉积与方向（o 为原点）：");
    println("  cross(o, a(4,4), b(8,0)) = {}（<0：右转/顺时针）", cross(o, a, b));
    println("  cross(o, b(8,0), a(4,4)) = {}（>0：左转/逆时针）", cross(o, b, a));
    println("  cross(o, a(4,4), c(2,2)) = {}（=0：共线）", cross(o, a, c));
    assert(cross(o, a, b) < 0 && cross(o, b, a) > 0 && cross(o, a, c) == 0);
}

// ═══ 34.2 线段相交（CLRS SEGMENTS-INTERSECT）═══
// 判定 p1p2 与 p3p4 是否相交：每段是否「跨越」另一段（方向符号相反），
// 特判共线时的在线检查。
static bool on_segment(Pt pi, Pt pj, Pt pk) {   // 共线前提下 pk 是否在 pi-pj 上
    return std::min(pi.x, pj.x) <= pk.x && pk.x <= std::max(pi.x, pj.x) &&
           std::min(pi.y, pj.y) <= pk.y && pk.y <= std::max(pi.y, pj.y);
}

static bool segments_intersect(Pt p1, Pt p2, Pt p3, Pt p4) {
    const long long d1 = cross(p3, p4, p1);
    const long long d2 = cross(p3, p4, p2);
    const long long d3 = cross(p1, p2, p3);
    const long long d4 = cross(p1, p2, p4);
    if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
        return true;                       // 规范相交：互跨
    }
    if (d1 == 0 && on_segment(p3, p4, p1)) { return true; }
    if (d2 == 0 && on_segment(p3, p4, p2)) { return true; }
    if (d3 == 0 && on_segment(p1, p2, p3)) { return true; }
    if (d4 == 0 && on_segment(p1, p2, p4)) { return true; }
    return false;
}

static void segments_demo() {
    println("线段相交判定（CLRS 图 33.3/33.4 的四种情形）：");
    // (a) 交于内点
    println("  (0,0)-(8,4) 与 (1,4)-(7,0)：相交 = {}（规范相交）",
            segments_intersect({0, 0}, {8, 4}, {1, 4}, {7, 0}) ? 1 : 0);
    assert(segments_intersect({0, 0}, {8, 4}, {1, 4}, {7, 0}));
    // (b) 共线不相接
    println("  (0,0)-(3,3) 与 (4,4)-(7,7)：相交 = {}（共线但不相接）",
            segments_intersect({0, 0}, {3, 3}, {4, 4}, {7, 7}) ? 1 : 0);
    assert(!segments_intersect({0, 0}, {3, 3}, {4, 4}, {7, 7}));
    // (c) 共线且端点在另一段上
    println("  (0,0)-(5,5) 与 (3,3)-(7,7)：相交 = {}（共线且重叠）",
            segments_intersect({0, 0}, {5, 5}, {3, 3}, {7, 7}) ? 1 : 0);
    assert(segments_intersect({0, 0}, {5, 5}, {3, 3}, {7, 7}));
    // (d) 平行不相交
    println("  (0,0)-(4,0) 与 (0,2)-(4,2)：相交 = {}（平行）",
            segments_intersect({0, 0}, {4, 0}, {0, 2}, {4, 2}) ? 1 : 0);
    assert(!segments_intersect({0, 0}, {4, 0}, {0, 2}, {4, 2}));
}

// ═══ 34.3 Graham 扫描凸包 ═══
// 极角排序 + 栈扫描：每步检查栈顶两点的转向，右转即弹出。
static long long dist2(Pt a, Pt b) {
    return (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y);
}

static std::vector<Pt> graham_hull(std::vector<Pt> pts) {
    // 1. 找最下最左点做锚点
    std::size_t anchor = 0;
    for (std::size_t i = 1; i < pts.size(); ++i) {
        if (pts[i].y < pts[anchor].y ||
            (pts[i].y == pts[anchor].y && pts[i].x < pts[anchor].x)) { anchor = i; }
    }
    std::swap(pts[0], pts[anchor]);
    const Pt p0 = pts[0];
    // 2. 按极角排序（叉积比较；共线远的在后）
    std::sort(pts.begin() + 1, pts.end(), [&](Pt a, Pt b) {
        const long long c = cross(p0, a, b);
        if (c != 0) { return c > 0; }                    // 逆时针序
        return dist2(p0, a) < dist2(p0, b);              // 共线近的先
    });
    // 3. 栈扫描
    std::vector<Pt> hull;
    for (Pt p : pts) {
        while (hull.size() >= 2 &&
               cross(hull[hull.size() - 2], hull[hull.size() - 1], p) <= 0) {
            hull.pop_back();                              // 右转/共线 → 弹出
        }
        hull.push_back(p);
    }
    return hull;
}

static bool point_in_hull(Pt p, const std::vector<Pt>& hull) {
    // 凸多边形内点：对所有边都是左转（含边界）
    for (std::size_t i = 0; i < hull.size(); ++i) {
        if (cross(hull[i], hull[(i + 1) % hull.size()], p) < 0) { return false; }
    }
    return true;
}

static void hull_demo() {
    // 7 点：4 角 + 3 内点——凸包应为 4 角（矩形）
    std::vector<Pt> pts{{0, 0}, {4, 0}, {4, 3}, {0, 3}, {2, 1}, {1, 2}, {3, 2}};
    const auto hull = graham_hull(pts);
    print("Graham 凸包（7 点 = 4 角 + 3 内点）：顶点序 ");
    for (auto p : hull) { print("({},{}) ", p.x, p.y); }
    println("");
    assert(hull.size() == 4);
    // 三个内点不在顶点序里，但都在凸包内
    bool insideAll = true;
    for (Pt p : {Pt{2, 1}, Pt{1, 2}, Pt{3, 2}}) {
        if (!point_in_hull(p, hull)) { insideAll = false; }
    }
    println("  内点 (2,1)(1,2)(3,2) 都在凸包内（左转检验）= {}，角点数 = 4", insideAll ? 1 : 0);
    assert(insideAll);
    // 凸包顶点序应是逆时针（对所有相邻三元组左转）
    bool ccw = true;
    for (std::size_t i = 0; i < hull.size(); ++i) {
        if (cross(hull[i], hull[(i + 1) % hull.size()], hull[(i + 2) % hull.size()]) <= 0) { ccw = false; }
    }
    assert(ccw);
}

// ═══ 34.4 最近点对（分治 vs 暴力）═══
static long long closest_brute(const std::vector<Pt>& pts, Pt& a, Pt& b) {
    long long best = INT64_MAX;
    for (std::size_t i = 0; i < pts.size(); ++i) {
        for (std::size_t j = i + 1; j < pts.size(); ++j) {
            const long long d = dist2(pts[i], pts[j]);
            if (d < best) { best = d; a = pts[i]; b = pts[j]; }
        }
    }
    return best;
}

static long long closest_rec(std::vector<Pt>& px, std::vector<Pt>& py, Pt& a, Pt& b) {
    // px 按 x 排序、py 按 y 排序（同一点集）
    const std::size_t n = px.size();
    if (n <= 3) {
        long long best = INT64_MAX;
        for (std::size_t i = 0; i < n; ++i) {
            for (std::size_t j = i + 1; j < n; ++j) {
                const long long d = dist2(px[i], px[j]);
                if (d < best) { best = d; a = px[i]; b = px[j]; }
            }
        }
        return best;
    }
    const std::size_t mid = n / 2;
    const long long midX = px[mid].x;
    std::vector<Pt> lx(px.begin(), px.begin() + static_cast<std::ptrdiff_t>(mid));
    std::vector<Pt> rx(px.begin() + static_cast<std::ptrdiff_t>(mid), px.end());
    std::vector<Pt> ly, ry;
    for (Pt p : py) {
        if (p.x < midX || (p.x == midX && ly.size() < lx.size())) { ly.push_back(p); }
        else { ry.push_back(p); }
    }
    Pt a1{0, 0}, b1{0, 0}, a2{0, 0}, b2{0, 0};
    const long long d1 = closest_rec(lx, ly, a1, b1);
    const long long d2 = closest_rec(rx, ry, a2, b2);
    long long best;
    if (d1 <= d2) { best = d1; a = a1; b = b1; } else { best = d2; a = a2; b = b2; }
    // 跨中线带宽检查：|x − midX| ≤ √best 的点按 y 序线性扫
    std::vector<Pt> strip;
    for (Pt p : py) {
        const long long dx = p.x - midX;
        if (dx * dx <= best) { strip.push_back(p); }
    }
    for (std::size_t i = 0; i < strip.size(); ++i) {
        for (std::size_t j = i + 1; j < strip.size() && j <= i + 7; ++j) {
            const long long d = dist2(strip[i], strip[j]);
            if (d < best) { best = d; a = strip[i]; b = strip[j]; }
        }
    }
    return best;
}

static void closest_demo() {
    const std::vector<Pt> pts{{2, 3}, {12, 30}, {40, 50}, {5, 1}, {12, 10},
                              {3, 4}, {30, 25}, {7, 8}, {9, 9}, {13, 14}};
    Pt a1{0, 0}, b1{0, 0}, a2{0, 0}, b2{0, 0};
    const long long d1 = closest_brute(pts, a1, b1);
    auto px = pts;
    std::vector<Pt> py = pts;
    std::ranges::sort(px, {}, &Pt::x);
    std::ranges::sort(py, {}, &Pt::y);
    const long long d2 = closest_rec(px, py, a2, b2);
    println("最近点对（10 点）：暴力 = 分治 = 距离² {}（点对 ({},{})-({},{}))",
            d1, a2.x, a2.y, b2.x, b2.y);
    assert(d1 == d2);
    assert(d1 == dist2(a1, b1));
    // 该点集的已知最近对：(2,3)-(3,4)，距离² = 2
    assert(d1 == 2);
}

int main() {
    cross_demo();
    segments_demo();
    hull_demo();
    closest_demo();
    println("自检通过");
    return 0;
}
