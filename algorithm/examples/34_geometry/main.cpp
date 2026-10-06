// 34 计算几何（CLRS 第 33 章）。结构：34.1 叉积与方向判断 /
// 34.2 线段相交判定（含边界情形）/ 34.3 Graham 扫描凸包 /
// 34.4 最近点对（分治 vs 暴力对账）/ 34.5 点在简单多边形内（射线奇偶法）/
// 34.6 天空轮廓（事件扫描）。全程整数坐标——零浮点，
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
#include <array>
#include <bit>
#include <cassert>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <random>
#include <set>
#include <vector>

struct Pt { long long x, y; };

// 文件级可移植取整（Lemire；各 demo 各自建 rng）
static std::uint32_t geo_rand_below(std::mt19937& rng, std::uint32_t n) {
    return static_cast<std::uint32_t>(
        (static_cast<std::uint64_t>(rng()) * n) >> 32);
}

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

// ═══ 34.5 点在简单多边形内：射线奇偶法 ═══
// 多边形顶点按顺序（顺/逆时针均可）给出，边 (v[i], v[(i+1)%n])。查询点 p。
// 从 p 向右发水平射线，数它与多边形边的交点：奇数在内、偶数在外。
enum class InPoly { Outside, Boundary, Inside };

static InPoly point_in_polygon(Pt p, const std::vector<Pt>& poly) {
    const int n = static_cast<int>(poly.size());
    bool inside = false;
    for (int i = 0; i < n; ++i) {
        Pt a = poly[i], b = poly[(i + 1) % n];
        // 边界优先：p 共线且落在边段上
        if (cross(a, b, p) == 0 && on_segment(a, b, p)) { return InPoly::Boundary; }
        // 统一让 a 为低端点，避免分母符号问题
        if (a.y > b.y) { Pt t = a; a = b; b = t; }
        // 跨射线条件：a.y ≤ p.y < b.y（恰一边取等——射线擦过顶点只计一次）
        if (!(a.y <= p.y && p.y < b.y)) { continue; }
        // 交点 x = a.x + (p.y−a.y)(b.x−a.x)/(b.y−a.y)；与 p.x 比较，
        // 分母 b.y−a.y > 0，交叉相乘无除法、无浮点：
        //   x交点 > p.x  ⟺  (a.x−p.x)(b.y−a.y) + (p.y−a.y)(b.x−a.x) > 0
        const long long lhs =
            (a.x - p.x) * (b.y - a.y) + (p.y - a.y) * (b.x - a.x);
        if (lhs > 0) { inside = !inside; }
    }
    return inside ? InPoly::Inside : InPoly::Outside;
}

// 独立口径：竖直向上射线（交换 x/y 后复用同一判据），方向完全不同。
static InPoly point_in_polygon_vertical(Pt p, const std::vector<Pt>& poly) {
    std::vector<Pt> swapped = poly;
    for (Pt& q : swapped) { const long long t = q.x; q.x = q.y; q.y = t; }
    return point_in_polygon({p.y, p.x}, swapped);
}

// 栅格真值：多边形的边沿整数格线走时（自避游走生成），把 W×H 个格子看作
// 迷宫房间——沿多边形的边砌墙，从四周边界格灌水（多边形严格位于板内，
// 边界格恒为外部），水漫不进去的房间即内部。与射线法零共享代码。
//   hwall[y][x]：格线 y（水平）、x 段上的墙，隔开房间 (x,y-1) 与 (x,y)
//   vwall[y][x]：格线 x（竖直）、y 段上的墙，隔开房间 (x-1,y) 与 (x,y)
static std::vector<std::vector<char>> raster_flood(
    const std::vector<Pt>& poly, int W, int H) {
    std::vector<std::vector<char>> hwall(H + 1, std::vector<char>(W, 0));
    std::vector<std::vector<char>> vwall(H, std::vector<char>(W + 1, 0));
    const int n = static_cast<int>(poly.size());
    for (int i = 0; i < n; ++i) {
        Pt a = poly[i], b = poly[(i + 1) % n];
        if (a.y == b.y) {                 // 水平边：y=a.y，x∈[min,max)
            const int y = static_cast<int>(a.y);
            for (int x = static_cast<int>(std::min(a.x, b.x));
                 x < static_cast<int>(std::max(a.x, b.x)); ++x) {
                hwall[y][x] = 1;
            }
        } else {                          // 竖直边：x=a.x，y∈[min,max)
            const int x = static_cast<int>(a.x);
            for (int y = static_cast<int>(std::min(a.y, b.y));
                 y < static_cast<int>(std::max(a.y, b.y)); ++y) {
                vwall[y][x] = 1;
            }
        }
    }
    std::vector<std::vector<char>> reached(H, std::vector<char>(W, 0));
    std::vector<std::pair<int, int>> queue;
    auto seed = [&](int c, int r) {
        if (c < 0 || r < 0 || c >= W || r >= H || reached[r][c]) { return; }
        reached[r][c] = 1;
        queue.push_back({c, r});
    };
    for (int c = 0; c < W; ++c) { seed(c, 0); seed(c, H - 1); }
    for (int r = 0; r < H; ++r) { seed(0, r); seed(W - 1, r); }
    for (std::size_t qi = 0; qi < queue.size(); ++qi) {
        const auto [c, r] = queue[qi];
        auto go = [&](int nc, int nr, bool blocked) {
            if (nc < 0 || nr < 0 || nc >= W || nr >= H || reached[nr][nc] ||
                blocked) { return; }
            reached[nr][nc] = 1;
            queue.push_back({nc, nr});
        };
        go(c, r - 1, hwall[r][c] != 0);       // 向上
        go(c, r + 1, hwall[r + 1][c] != 0);   // 向下
        go(c - 1, r, vwall[r][c] != 0);       // 向左
        go(c + 1, r, vwall[r][c + 1] != 0);   // 向右
    }
    std::vector<std::vector<char>> inside(H, std::vector<char>(W, 0));
    for (int r = 0; r < H; ++r) {
        for (int c = 0; c < W; ++c) { inside[r][c] = reached[r][c] ? 0 : 1; }
    }
    return inside;
}

static void polygon_demo() {
    println("=== 34.5 点在简单多边形内：水平射线奇偶法 ===");
    // 固定多边形（带凹陷的 8 顶点，10×10 格网内）
    const std::vector<Pt> poly{
        {1, 1}, {8, 1}, {8, 7}, {6, 7}, {6, 4}, {3, 4}, {3, 9}, {1, 9}};
    struct Q { Pt p; const char* name; InPoly expect; };
    const Q qs[] = {
        {{2, 2}, "内点", InPoly::Inside},
        {{7, 3}, "右下内点", InPoly::Inside},
        {{4, 6}, "凹陷区", InPoly::Outside},  // 凹陷 x∈[3,6], y∈[4,7]
        {{9, 9}, "多边形外", InPoly::Outside},
        {{8, 4}, "右边界", InPoly::Boundary},
        {{1, 1}, "顶点", InPoly::Boundary}};
    for (const Q& q : qs) {
        const InPoly r1 = point_in_polygon(q.p, poly);
        const InPoly r2 = point_in_polygon_vertical(q.p, poly);
        static const char* names[] = {"外", "边界", "内"};
        println("  {} ({},{})：水平射线 {}，竖直射线 {}（期望 {}）",
                q.name, q.p.x, q.p.y, names[static_cast<int>(r1)],
                names[static_cast<int>(r2)], names[static_cast<int>(q.expect)]);
        assert(r1 == q.expect && r2 == q.expect);
    }
    // 随机对账：在 W×H 格网上生成自避游走闭合多边形（沿格线），对所有格子
    // 中心（半整数点）比对射线法与栅格泛洪真值。
    std::mt19937 rng{5489};
    int mismatches = 0, tested_polys = 0;
    for (int t = 0; t < 200; ++t) {
        const int W = 4 + static_cast<int>(rng() % 6);
        const int H = 4 + static_cast<int>(rng() % 6);
        // 自避游走：从随机点出发，在格点上随机走，不重复访问，走够长后回起点
        const int sx = 1 + static_cast<int>(rng() % (W - 1));
        const int sy = 1 + static_cast<int>(rng() % (H - 1));
        std::vector<Pt> walk{{sx, sy}};
        std::vector<std::vector<char>> seen(H + 1, std::vector<char>(W + 1, 0));
        seen[sy][sx] = 1;
        const int target_len = W + H;
        for (int step = 0; step < 60 && static_cast<int>(walk.size()) < target_len; ) {
            Pt cur = walk.back();
            const int dirs[4][2]{{1, 0}, {-1, 0}, {0, 1}, {0, -1}};
            int order[4] = {0, 1, 2, 3};
            for (int k = 0; k < 4; ++k) {
                const int a = static_cast<int>(rng() % (4 - k)) + k;
                const int tmp = order[k]; order[k] = order[a]; order[a] = tmp;
            }
            bool moved = false;
            for (int k = 0; k < 4; ++k) {
                const int nx = static_cast<int>(cur.x) + dirs[order[k]][0];
                const int ny = static_cast<int>(cur.y) + dirs[order[k]][1];
                if (nx <= 0 || ny <= 0 || nx >= W || ny >= H || seen[ny][nx]) { continue; }
                walk.push_back({nx, ny});
                seen[ny][nx] = 1;
                moved = true;
                break;
            }
            if (!moved) { break; }
        }
        if (walk.size() < 4) { continue; }
        // 必须能直接走回起点（一步相邻），否则不是闭合多边形
        Pt last = walk.back(), first = walk.front();
        if (std::abs(last.x - first.x) + std::abs(last.y - first.y) != 1) { continue; }
        ++tested_polys;
        const auto truth = raster_flood(walk, W, H);
        for (int r = 0; r < H; ++r) {
            for (int c = 0; c < W; ++c) {
                const Pt center{2 * c + 1, 2 * r + 1};   // 半整数（放大 2 倍口径）
                // 多边形坐标也放大 2 倍以匹配中心表示
                std::vector<Pt> big = walk;
                for (Pt& q : big) { q.x *= 2; q.y *= 2; }
                const InPoly got = point_in_polygon(center, big);
                const bool expect_in = truth[r][c] != 0;
                if ((got == InPoly::Inside) != expect_in) { ++mismatches; }
            }
        }
    }
    println("  随机 {} 个格线多边形（逐格中心核对）：射线法 vs 栅格泛洪 不一致 {} 格",
            tested_polys, mismatches);
    assert(mismatches == 0);
}

// ═══ 34.6 天空轮廓：事件扫描 + 活跃高度多重集 ═══
// 给定若干矩形建筑（左边界 l、右边界 r、高 h，底边在地平线上），求它们叠
// 加后的轮廓：一列「关键点」(x, 高度)，相邻关键点之间高度恒定。
struct Building { long long l, r, h; };
struct SkyPoint { long long x, h; };
static bool operator==(const SkyPoint& a, const SkyPoint& b) {
    return a.x == b.x && a.h == b.h;
}

// 高度函数按「左闭右开」定义：H(x) = max{ h_i | l_i ≤ x < r_i }，无楼则 0。
// 每个左边界事件 +h、右边界事件 −h；同一 x 的所有事件先处理完，再看活跃
// 高度的最大值是否变化——变化才输出关键点。复杂度 O(n log n)。
static std::vector<SkyPoint> skyline_sweep(const std::vector<Building>& bs) {
    struct Event { long long x; long long h; bool add; };
    std::vector<Event> events;
    events.reserve(2 * bs.size());
    for (const Building& b : bs) {
        events.push_back({b.l, b.h, true});
        events.push_back({b.r, b.h, false});
    }
    std::sort(events.begin(), events.end(),
              [](const Event& a, const Event& b) { return a.x < b.x; });
    std::multiset<long long> active;     // 活跃楼高度（允许重复）
    std::vector<SkyPoint> points;
    long long cur = 0;
    for (std::size_t i = 0; i < events.size(); ) {
        const long long x = events[i].x;
        std::size_t j = i;
        while (j < events.size() && events[j].x == x) {
            if (events[j].add) { active.insert(events[j].h); }
            else {
                auto it = active.find(events[j].h);
                active.erase(it);
            }
            ++j;
        }
        const long long nxt = active.empty() ? 0 : *active.rbegin();
        if (nxt != cur) { points.push_back({x, nxt}); cur = nxt; }
        i = j;
    }
    return points;
}

// 独立口径：收集所有不同的 x 坐标，在每个坐标处按定义直接扫描全部楼取
// 最大值（O(n²)，与扫描线无共享逻辑），再压缩相邻同高点。
static std::vector<SkyPoint> skyline_naive(const std::vector<Building>& bs) {
    std::vector<long long> xs;
    xs.reserve(2 * bs.size());
    for (const Building& b : bs) { xs.push_back(b.l); xs.push_back(b.r); }
    std::sort(xs.begin(), xs.end());
    xs.erase(std::unique(xs.begin(), xs.end()), xs.end());
    std::vector<SkyPoint> points;
    long long last = -1;
    for (long long x : xs) {
        long long h = 0;
        for (const Building& b : bs) {
            if (b.l <= x && x < b.r) { h = std::max(h, b.h); }
        }
        if (h != last) { points.push_back({x, h}); last = h; }
    }
    return points;
}

static void skyline_demo() {
    println("=== 34.6 天空轮廓：事件扫描（活跃高度多重集）===");
    // 固定例（含重叠、遮挡、间隙）
    const std::vector<Building> bs{
        {2, 9, 10}, {3, 7, 15}, {5, 12, 12}, {15, 20, 10}, {19, 24, 8}};
    const std::vector<SkyPoint> sweep = skyline_sweep(bs);
    const std::vector<SkyPoint> naive = skyline_naive(bs);
    print("  轮廓关键点：");
    for (const SkyPoint& p : sweep) { print("({},{}) ", p.x, p.h); }
    println("");
    assert(sweep == naive);
    // 高度变化都发生在某个左/右边界上；末点高度必为 0（楼群右侧回地平线）
    assert(sweep.back().h == 0);
    const std::vector<SkyPoint> expected{
        {2, 10}, {3, 15}, {7, 12}, {12, 0}, {15, 10}, {20, 8}, {24, 0}};
    assert(sweep == expected);
    println("  与逐点取最大值的 O(n²) 口径一致；间隙处（12）回落为 0");

    // 随机 300 例（n≤30，坐标 0..30，高 1..15）：两口径全程对账
    std::mt19937 rng{5489};
    auto rand_below = [&](std::uint32_t n) {
        return static_cast<int>(
            (static_cast<std::uint64_t>(rng()) * n) >> 32);
    };
    int mismatches = 0;
    for (int t = 0; t < 300; ++t) {
        const int n = 1 + rand_below(30);
        std::vector<Building> g;
        g.reserve(n);
        for (int i = 0; i < n; ++i) {
            const int a = rand_below(28);
            const int len = 1 + rand_below(6);
            g.push_back({a, a + len, 1 + rand_below(15)});
        }
        if (skyline_sweep(g) != skyline_naive(g)) { ++mismatches; }
    }
    println("  随机 {} 例（n≤30）：扫描线 vs 逐点 O(n²) 不一致 {} 例",
            300, mismatches);
    assert(mismatches == 0);

    // 大例：20000 栋完全重合、高度递增的楼——只有最矮以外全部互相遮挡，
    // 轮廓恰为两个关键点。O(n²) 真值口径在此规模不可行，用结构性质核对。
    std::vector<Building> big;
    big.reserve(20000);
    for (int i = 0; i < 20000; ++i) { big.push_back({0, 20000, i + 1}); }
    const std::vector<SkyPoint> got = skyline_sweep(big);
    println("  大例（{} 栋等高重合楼）：关键点 {} 个：({},{})、({},{})",
            big.size(), got.size(), got[0].x, got[0].h, got[1].x, got[1].h);
    assert(got.size() == 2);
    assert(got[0].x == 0 && got[0].h == 20000);
    assert(got[1].x == 20000 && got[1].h == 0);
}

// ═══ 34.7 平面被直线分割：区域数的增量构造 ═══
// 第 i 条线与前 i−1 条线交于 i−1 个互不重合的点（一般位置：无平行、
// 无三线共点）⟹ 被切成 i 段 ⟹ 新增 i 个区域：R(i)=R(i−1)+i，
// R(0)=1 ⟹ R(n)=1+n(n+1)/2。
struct ArrLine { long long m, c; };          // y = m·x + c

// 三线共点的行列式检验（精确整数）：
// m_i(c_j−c_k)+m_j(c_k−c_i)+m_k(c_i−c_j) == 0。
static long long triple_det(const ArrLine& a, const ArrLine& b,
                            const ArrLine& c) {
    return a.m * (b.c - c.c) + b.m * (c.c - a.c) + c.m * (a.c - b.c);
}

static bool general_position(const std::vector<ArrLine>& lines) {
    const int n = static_cast<int>(lines.size());
    for (int i = 0; i < n; ++i) {
        for (int j = i + 1; j < n; ++j) {
            if (lines[i].m == lines[j].m) { return false; }   // 平行
        }
    }
    for (int i = 0; i < n; ++i) {
        for (int j = i + 1; j < n; ++j) {
            for (int k = j + 1; k < n; ++k) {
                if (triple_det(lines[i], lines[j], lines[k]) == 0) {
                    return false;
                }
            }
        }
    }
    return true;
}

static long long line_region_count(const std::vector<ArrLine>& lines) {
    long long r = 1;                       // R(0)
    for (int i = 1; i <= static_cast<int>(lines.size()); ++i) { r += i; }
    return r;
}

static void line_region_demo() {
    println("");
    println("=== 34.7 平面被 n 条直线分割：R(n) = 1 + n(n+1)/2 ===");
    // 构造：直线 i 取 y = i·x + i²。交点为 (−i−j, i·j)——sum 与 product
    // 唯一确定 {i,j}，故全部 C(n,2) 交点互不相同，天然一般位置；且
    // triple_det = −(i−j)(j−k)(k−i) ≠ 0（对构造逐三元验证）。
    print("  n:     ");
    for (int n = 0; n <= 6; ++n) { print("{:5}", n); }
    println("");
    print("  R(n):  ");
    for (int n = 0; n <= 6; ++n) {
        std::vector<ArrLine> ls;
        for (int i = 0; i < n; ++i) { ls.push_back({i, 1LL * i * i}); }
        print("{:5}", line_region_count(ls));
    }
    println("");

    // n≤12：逐三元精确行列式 + 平行检验，构造确为一般位置
    std::vector<ArrLine> small;
    for (int i = 0; i < 12; ++i) { small.push_back({i, 1LL * i * i}); }
    assert(general_position(small));

    // 随机 50 组（拒绝采样到一般位置，n≤10）：计数 == 闭式
    std::mt19937 rng{5489};
    auto rand_below = [&](std::uint32_t n) {
        return static_cast<std::uint32_t>(
            (static_cast<std::uint64_t>(rng()) * n) >> 32);
    };
    int bad = 0, accepted = 0;
    for (int t = 0; t < 50; ++t) {
        const int n = 3 + static_cast<int>(rand_below(8));
        std::vector<long long> slopes;
        for (int k = -20; k <= 20; ++k) { slopes.push_back(k); }
        std::vector<ArrLine> ls;
        for (int k = 0; k < n; ++k) {
            const long long m = slopes[rand_below(
                static_cast<std::uint32_t>(slopes.size()))];
            slopes.erase(std::ranges::find(slopes, m));
            const long long c = -100 +
                static_cast<long long>(rand_below(201));
            ls.push_back({m, c});
        }
        if (!general_position(ls)) { continue; }    // 拒绝（罕见）
        ++accepted;
        const long long formula = 1 + 1LL * n * (n + 1) / 2;
        if (line_region_count(ls) != formula) { ++bad; }
    }
    println("  随机 {} 组一般位置直线（50 次尝试）：计数与闭式不一致 {} 例",
            accepted, bad);
    assert(bad == 0);

    // 大例 n=1000：闭式 500501；一般位置用「全部 C(n,2) 交点的
    // (sum, product) 无重复」做 O(n²) 的完整认证（交点为 (−i−j, ij)）。
    const int n = 1000;
    std::set<std::pair<long long, long long>> crosses;
    for (int i = 0; i < n; ++i) {
        for (int j = i + 1; j < n; ++j) {
            const bool inserted = crosses.insert(
                {-1LL * (i + j), 1LL * i * j}).second;
            assert(inserted);
        }
    }
    const long long r = 1 + 1LL * n * (n + 1) / 2;
    println("  大例 n=1000（y = i·x+i²）：区域 {}；{} 个交点全部互异，"
            "一般位置认证通过", r, crosses.size());
    assert(r == 500501 &&
           static_cast<long long>(crosses.size()) == 1LL * n * (n - 1) / 2);
}

// ═══ 34.8 最小包围圆：Welzl 随机增量法 ═══
// 期望线性：随机打乱后逐个加点；点在当前圆内则什么都不做，否则它必在
// 新圆边界上——带着至多 3 个边界支撑点递归。
struct Circle {
    double cx = 0, cy = 0;
    double r = -1.0;                        // r<0 ⟺ 空圆
};

static bool in_circle(const Circle& d, const Pt& p, double eps = 1e-9) {
    if (d.r < 0) { return false; }
    const double dx = static_cast<double>(p.x) - d.cx;
    const double dy = static_cast<double>(p.y) - d.cy;
    return dx * dx + dy * dy <= d.r * d.r + eps;
}

static double pt_dist(const Pt& a, const Pt& b) {
    const double dx = static_cast<double>(a.x - b.x);
    const double dy = static_cast<double>(a.y - b.y);
    return std::sqrt(dx * dx + dy * dy);
}

// 1～3 个边界点定圆
static Circle trivial_circle(const Pt* s, int ns) {
    if (ns == 0) { return {}; }
    if (ns == 1) {
        return {static_cast<double>(s[0].x), static_cast<double>(s[0].y), 0.0};
    }
    if (ns == 2) {
        return {(static_cast<double>(s[0].x) + s[1].x) / 2,
                (static_cast<double>(s[0].y) + s[1].y) / 2,
                pt_dist(s[0], s[1]) / 2};
    }
    // 三点外接圆（垂直平分线交点）
    const double ax = static_cast<double>(s[0].x);
    const double ay = static_cast<double>(s[0].y);
    const double bx = static_cast<double>(s[1].x);
    const double by = static_cast<double>(s[1].y);
    const double qx = static_cast<double>(s[2].x);
    const double qy = static_cast<double>(s[2].y);
    const double d = 2.0 * (ax * (by - qy) + bx * (qy - ay) +
                            qx * (ay - by));
    if (d == 0.0) {
        // 共线退化（正常流程不会出现）：取三对直径圆中覆盖三点的最小者
        Circle best{};
        bool have = false;
        for (int i = 0; i < 3; ++i) {
            for (int j = i + 1; j < 3; ++j) {
                const Pt pair[2] = {s[i], s[j]};
                const Circle cand = trivial_circle(pair, 2);
                bool covers = true;
                for (int k = 0; k < 3; ++k) {
                    if (!in_circle(cand, s[k], 1e-7)) { covers = false; }
                }
                if (covers && (!have || cand.r < best.r)) {
                    best = cand; have = true;
                }
            }
        }
        return best;
    }
    const double a2 = ax * ax + ay * ay;
    const double b2 = bx * bx + by * by;
    const double c2 = qx * qx + qy * qy;
    const double ux = (a2 * (by - qy) + b2 * (qy - ay) +
                       c2 * (ay - by)) / d;
    const double uy = (a2 * (qx - bx) + b2 * (ax - qx) +
                       c2 * (bx - ax)) / d;
    return {ux, uy, std::sqrt((ax - ux) * (ax - ux) +
                              (ay - uy) * (ay - uy))};
}

// Welzl 主体：p 已随机打乱；处理前 n 个点，sup 为已知必在边界的支撑点。
// 外层用循环走前缀（经典写法的无条件递归尾链在 n=2 万时会撑爆 1MB 栈），
// 只有「q 跑到圆外」才带着新支撑点递归——递归深度 ≤ ns+1 ≤ 4。
static Circle welzl(const std::vector<Pt>& p, int n,
                    std::array<Pt, 3> sup, int ns) {
    Circle d = trivial_circle(sup.data(), ns);
    for (int i = 0; i < n; ++i) {
        const Pt q = p[static_cast<std::size_t>(i)];
        if (in_circle(d, q)) { continue; }
        sup[static_cast<std::size_t>(ns)] = q;
        d = welzl(p, i, sup, ns + 1);       // 前缀 [0,i)，q 在边界
    }
    return d;
}

static Circle minimum_enclosing_circle(std::vector<Pt> p) {
    // 确定性洗牌（固定种子的 Fisher-Yates；不用 std::shuffle 只是为了让
    // 随机序列在本文件里显式可见）
    std::mt19937 rng{5489};
    for (int i = static_cast<int>(p.size()) - 1; i > 0; --i) {
        const int j = static_cast<int>(
            (static_cast<std::uint64_t>(rng()) * (i + 1)) >> 32);
        std::swap(p[static_cast<std::size_t>(i)],
                  p[static_cast<std::size_t>(j)]);
    }
    return welzl(p, static_cast<int>(p.size()), {}, 0);
}

// 独立口径（小规模暴力真值）：候选圆 = 任一点（r=0）、任两点直径、
// 任三点外接圆；覆盖全部点者取最小半径。
static Circle mec_brute(const std::vector<Pt>& p) {
    const int n = static_cast<int>(p.size());
    Circle best{};
    bool have = false;
    auto consider = [&](const Circle& d) {
        for (const Pt& q : p) {
            if (!in_circle(d, q, 1e-7)) { return; }
        }
        if (!have || d.r < best.r) { best = d; have = true; }
    };
    for (int i = 0; i < n; ++i) {
        consider(trivial_circle(&p[static_cast<std::size_t>(i)], 1));
        for (int j = i + 1; j < n; ++j) {
            const Pt pair[2] = {p[static_cast<std::size_t>(i)],
                                p[static_cast<std::size_t>(j)]};
            consider(trivial_circle(pair, 2));
            for (int k = j + 1; k < n; ++k) {
                const Pt tri[3] = {p[static_cast<std::size_t>(i)],
                                   p[static_cast<std::size_t>(j)],
                                   p[static_cast<std::size_t>(k)]};
                consider(trivial_circle(tri, 3));
            }
        }
    }
    return best;
}

static void mec_demo() {
    println("");
    println("=== 34.8 最小包围圆：Welzl 随机增量（期望 O(n)）===");
    // 边界结构例
    const Circle one = minimum_enclosing_circle({{3, 7}});
    assert(one.r == 0 && one.cx == 3 && one.cy == 7);
    const Circle two = minimum_enclosing_circle({{0, 0}, {4, 3}});
    assert(std::fabs(two.r - 2.5) < 1e-9 &&
           std::fabs(two.cx - 2) < 1e-9 && std::fabs(two.cy - 1.5) < 1e-9);
    // 共线点：直径圆由两端点决定
    const Circle line = minimum_enclosing_circle(
        {{0, 0}, {2, 0}, {5, 0}, {1, 0}});
    assert(std::fabs(line.r - 2.5) < 1e-9);
    println("  结构例：单点 r=0；两点 (0,0)(4,3) 直径 r=2.5；"
            "共线 4 点 r=2.5");

    // 正方形 4 顶点：圆心 (1.5,1.5)、r=√4.5
    const Circle sq = minimum_enclosing_circle(
        {{0, 0}, {3, 0}, {3, 3}, {0, 3}});
    assert(std::fabs(sq.cx - 1.5) < 1e-9 &&
           std::fabs(sq.r - std::sqrt(4.5)) < 1e-9);
    println("  正方形 4 顶点：圆心 (1.5,1.5)，r={:.6f}", sq.r);

    // 随机 200 组（n≤9，坐标 −15..15）：Welzl vs 暴力
    std::mt19937 rng{5489};
    int bad = 0;
    for (int t = 0; t < 200; ++t) {
        const int n = 2 + static_cast<int>(geo_rand_below(rng, 8));
        std::vector<Pt> pts;
        for (int k = 0; k < n; ++k) {
            pts.push_back({
                static_cast<long long>(geo_rand_below(rng, 31)) - 15,
                static_cast<long long>(geo_rand_below(rng, 31)) - 15});
        }
        const Circle a = minimum_enclosing_circle(pts);
        const Circle b = mec_brute(pts);
        // 每个点都在 Welzl 圆内
        for (const Pt& q : pts) { assert(in_circle(a, q, 1e-7)); }
        if (std::fabs(a.r - b.r) > 1e-7) { ++bad; }
    }
    println("  随机 200 组（n≤9）：Welzl 与暴力半径不一致 {} 例", bad);
    assert(bad == 0);

    // 大例 n=20000：期望线性时间；逐点复核全部在圆内
    const int n = 20000;
    std::vector<Pt> big;
    big.reserve(n);
    for (int k = 0; k < n; ++k) {
        big.push_back({
            static_cast<long long>(geo_rand_below(rng, 200001)) - 100000,
            static_cast<long long>(geo_rand_below(rng, 200001)) - 100000});
    }
    const Circle d = minimum_enclosing_circle(big);
    int outside = 0;
    double farthest = 0;
    for (const Pt& q : big) {
        const double dx = static_cast<double>(q.x) - d.cx;
        const double dy = static_cast<double>(q.y) - d.cy;
        const double e = std::sqrt(dx * dx + dy * dy);
        farthest = std::max(farthest, e);
        if (e > d.r + 1e-6) { ++outside; }
    }
    println("  大例（2 万点，坐标 ±10 万）：圆心 ({:.2f},{:.2f})，"
            "r={:.4f}（最远点 {}，越界 {} 个）",
            d.cx, d.cy, d.r, farthest, outside);
    assert(outside == 0 && farthest <= d.r + 1e-6);
    // 半径不可能超过包围盒外接圆的一半量级
    assert(d.r < 150000);
}

// ═══ 34.9 冗余传感器：正方形覆盖的矩形并 ═══
// 每个传感器的监控范围是以自身为中心、边长 2h（h 为半边长）的轴对齐
// 正方形。邻居关系有方向：A 是 C 的邻居当且仅当 C 的中心落在 A 的
// 正方形内（|Δx|、|Δy| 均 ≤ h）。C 冗余 ⟺ C 的正方形被所有邻居
// 正方形的并完全覆盖。
struct Sensor { long long x, y; };
struct IRect { long long x0, y0, x1, y1; };   // [x0,x1)×[y0,y1)

// 取各邻居正方形与 C 正方形的交（交为空则跳过）
static std::vector<IRect> neighbor_clips(
        const std::vector<Sensor>& ss, int c, long long h) {
    std::vector<IRect> rs;
    const Sensor me = ss[static_cast<std::size_t>(c)];
    for (std::size_t k = 0; k < ss.size(); ++k) {
        if (static_cast<int>(k) == c) { continue; }
        const Sensor a = ss[k];
        if (std::llabs(a.x - me.x) > h || std::llabs(a.y - me.y) > h) {
            continue;                               // C 不在 A 正方形内
        }
        IRect r{a.x - h, a.y - h, a.x + h, a.y + h};
        r.x0 = std::max(r.x0, me.x - h);
        r.y0 = std::max(r.y0, me.y - h);
        r.x1 = std::min(r.x1, me.x + h);
        r.y1 = std::min(r.y1, me.y + h);
        if (r.x0 < r.x1 && r.y0 < r.y1) { rs.push_back(r); }
    }
    return rs;
}

// 矩形并面积：x 边切条，条内合并 y 区间。O(k² log k)，全程整数。
static long long union_area(const std::vector<IRect>& rs) {
    std::vector<long long> xs;
    for (const IRect& r : rs) { xs.push_back(r.x0); xs.push_back(r.x1); }
    std::ranges::sort(xs);
    xs.erase(std::ranges::unique(xs).begin(), xs.end());
    long long area = 0;
    for (std::size_t i = 0; i + 1 < xs.size(); ++i) {
        const long long xlo = xs[i], xhi = xs[i + 1];
        std::vector<std::pair<long long, long long>> ys;
        for (const IRect& r : rs) {
            if (r.x0 <= xlo && r.x1 >= xhi) {
                ys.push_back({r.y0, r.y1});
            }
        }
        std::ranges::sort(ys);
        long long covered_h = 0, cur = 0;
        bool started = false;
        for (auto [y0, y1] : ys) {
            if (!started) { cur = y1; covered_h = y1 - y0; started = true; }
            else if (y0 > cur) { covered_h += y1 - y0; cur = y1; }
            else if (y1 > cur) { covered_h += y1 - cur; cur = y1; }
        }
        area += (xhi - xlo) * covered_h;
    }
    return area;
}

// 独立口径：逐单位格子判定（仅小坐标场景）——与切条合并零共享
static long long covered_cells(const std::vector<IRect>& rs) {
    std::set<std::pair<long long, long long>> cells;
    for (const IRect& r : rs) {
        for (long long x = r.x0; x < r.x1; ++x) {
            for (long long y = r.y0; y < r.y1; ++y) {
                cells.insert({x, y});
            }
        }
    }
    return static_cast<long long>(cells.size());
}

static bool sensor_redundant(const std::vector<Sensor>& ss, int c, long long h) {
    return union_area(neighbor_clips(ss, c, h)) == 4 * h * h;
}

static void sensor_demo() {
    println("");
    println("=== 34.9 冗余传感器：C 正方形 ⊆ 邻居正方形之并 ===");
    const long long h = 4;
    // 植入例 1：四角各一邻居（中心偏移 ±h），四个象限正方形恰好铺满
    const std::vector<Sensor> planted{
        {0, 0}, {h, h}, {h, -h}, {-h, h}, {-h, -h}};
    const auto clips = neighbor_clips(planted, 0, h);
    assert(union_area(clips) == 4 * h * h);
    assert(covered_cells(clips) == 4 * h * h);
    println("  植入例（4 邻居铺满）：切条并面积 {}＝4h²，格子口径 {}，冗余",
            union_area(clips), covered_cells(clips));

    // 植入例 2：抽掉一个邻居，一个象限缺 16 格 → 不冗余
    const std::vector<Sensor> hole{
        {0, 0}, {h, h}, {h, -h}, {-h, h}};
    const auto hclips = neighbor_clips(hole, 0, h);
    assert(union_area(hclips) == 3 * h * h);
    assert(covered_cells(hclips) == 3 * h * h);
    println("  植入例（缺 1 邻居）：覆盖 {}/{} 格，不冗余",
            union_area(hclips), 4 * h * h);
    assert(!sensor_redundant(hole, 0, h));

    // 随机 200 个小传感器场（h=5，坐标 0..20）：每个传感器都用切条 vs
    // 单位格子两口径对账
    std::mt19937 rng{5489};
    int bad = 0, redundant = 0;
    for (int t = 0; t < 200; ++t) {
        const int n = 2 + static_cast<int>(geo_rand_below(rng, 10));
        std::vector<Sensor> ss;
        for (int k = 0; k < n; ++k) {
            ss.push_back({
                static_cast<long long>(geo_rand_below(rng, 21)),
                static_cast<long long>(geo_rand_below(rng, 21))});
        }
        for (int c = 0; c < n; ++c) {
            const auto rs = neighbor_clips(ss, c, 5);
            const long long a = union_area(rs);
            const long long b = covered_cells(rs);
            if (a != b) { ++bad; }
            if (a == 100) { ++redundant; }
        }
    }
    println("  随机 200 个小场：切条 vs 格子口径不一致 {} 例；冗余传感器共 {} 个",
            bad, redundant);
    assert(bad == 0);

    // 大例：L×L 格点阵列，间距恰为 h ⟹ 恰有内部 (L−2)² 个冗余
    const int L = 30;
    std::vector<Sensor> grid;
    grid.reserve(L * L);
    for (int i = 0; i < L; ++i) {
        for (int j = 0; j < L; ++j) {
            grid.push_back({1LL * i * h, 1LL * j * h});
        }
    }
    // 阵列里只有 4 个角不冗余（角区 [cx−h,cx)×[cy−h,cy) 无任何邻居
    // 覆盖）；边中点由两个轴向邻居覆盖、内部由四角邻居覆盖。
    int nred = 0;
    const int corner_idx[4] = {0, L - 1, L * (L - 1), L * L - 1};
    for (int c : corner_idx) { assert(!sensor_redundant(grid, c, h)); }
    for (int c = 0; c < static_cast<int>(grid.size()); ++c) {
        if (sensor_redundant(grid, c, h)) { ++nred; }
    }
    println("  大例（{}×{} 阵列，间距 h）：冗余 {} 个（四角均不冗余），"
            "期望恰为 L²−4 = {}", L, L, nred, L * L - 4);
    assert(nred == L * L - 4);
}

// ═══ 34.10 隐藏节点：单位圆盘图上的「V 形三元组」 ═══
// 设备 i,j 可通信 ⟺ 距离² ≤ R²。隐藏节点集合＝三元组 {a,b,c}：
// a,b 不可通信，但二者都与 c 通信（诱导子图恰为两条共点边）。
static std::vector<std::vector<char>>
disk_adjacency(const std::vector<Pt>& ps, long long R) {
    const int n = static_cast<int>(ps.size());
    std::vector<std::vector<char>> adj(
        static_cast<std::size_t>(n), std::vector<char>(n, 0));
    for (int i = 0; i < n; ++i) {
        for (int j = i + 1; j < n; ++j) {
            const long long dx = ps[static_cast<std::size_t>(i)].x -
                                 ps[static_cast<std::size_t>(j)].x;
            const long long dy = ps[static_cast<std::size_t>(i)].y -
                                 ps[static_cast<std::size_t>(j)].y;
            if (dx * dx + dy * dy <= R * R) {
                adj[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] = 1;
                adj[static_cast<std::size_t>(j)][static_cast<std::size_t>(i)] = 1;
            }
        }
    }
    return adj;
}

// 暴力 O(n³)：枚举三元组、统计恰有两条边
static long long hidden_triples_brute(const std::vector<std::vector<char>>& adj) {
    const int n = static_cast<int>(adj.size());
    long long cnt = 0;
    for (int i = 0; i < n; ++i) {
        for (int j = i + 1; j < n; ++j) {
            if (adj[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)]) { continue; }
            for (int k = 0; k < n; ++k) {     // 中心可在任一下标，须遍历全表
                if (k == i || k == j) { continue; }
                const int e =
                    adj[static_cast<std::size_t>(i)][static_cast<std::size_t>(k)] +
                    adj[static_cast<std::size_t>(j)][static_cast<std::size_t>(k)];
                if (e == 2) { ++cnt; }
            }
        }
    }
    return cnt;
}

// 位行口径 O(n³/64)：对每条非边 (i,j)，公共邻数＝popcount(bits[i]&bits[j])
static long long hidden_triples_bits(const std::vector<std::vector<char>>& adj) {
    const int n = static_cast<int>(adj.size());
    const int words = (n + 63) / 64;
    std::vector<std::vector<unsigned long long>> bits(
        static_cast<std::size_t>(n),
        std::vector<unsigned long long>(static_cast<std::size_t>(words), 0));
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            if (adj[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)]) {
                bits[static_cast<std::size_t>(i)][static_cast<std::size_t>(j / 64)] |=
                    1ULL << (j % 64);
            }
        }
    }
    long long cnt = 0;
    for (int i = 0; i < n; ++i) {
        for (int j = i + 1; j < n; ++j) {
            if (adj[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)]) { continue; }
            long long common = 0;
            for (int w = 0; w < words; ++w) {
                common += std::popcount(
                    bits[static_cast<std::size_t>(i)][static_cast<std::size_t>(w)] &
                    bits[static_cast<std::size_t>(j)][static_cast<std::size_t>(w)]);
            }
            cnt += common;
        }
    }
    return cnt;
}

static void hidden_terminal_demo() {
    println("");
    println("=== 34.10 隐藏节点：圆盘图「V 形三元组」（暴力 O(n³) vs 位行 O(n³/64)）===");
    const std::vector<Pt> square{{0, 0}, {0, 1}, {1, 0}, {1, 1}};
    const auto sadj = disk_adjacency(square, 1);
    const long long s1 = hidden_triples_brute(sadj);
    const long long s2 = hidden_triples_bits(sadj);
    println("  固定例（单位正方形 4 点，R=1）：隐藏集合 {} 组（两口径一致 = 1）", s1);
    assert(s1 == 4 && s2 == 4);

    // 全连通/无边圆盘：均无隐藏三元组
    std::vector<Pt> cluster{{0, 0}, {1, 0}, {0, 1}};
    assert(hidden_triples_brute(disk_adjacency(cluster, 2)) == 0);
    assert(hidden_triples_bits(disk_adjacency(cluster, 0)) == 0);

    // 随机 300 个小场（n≤12）：两口径一致
    std::mt19937 rng{5489};
    int bad = 0;
    for (int t = 0; t < 300; ++t) {
        const int n = 2 + static_cast<int>(geo_rand_below(rng, 11));
        std::vector<Pt> ps;
        ps.reserve(static_cast<std::size_t>(n));
        for (int i = 0; i < n; ++i) {
            ps.push_back({
                static_cast<long long>(geo_rand_below(rng, 12)),
                static_cast<long long>(geo_rand_below(rng, 12))});
        }
        const long long R = static_cast<long long>(geo_rand_below(rng, 8));
        const auto a = disk_adjacency(ps, R);
        if (hidden_triples_brute(a) != hidden_triples_bits(a)) { ++bad; }
    }
    println("  随机 300 个小场（n≤12）：暴力三元组 vs 位行公共邻不一致 {} 例", bad);
    assert(bad == 0);

    // 大例：60×50 网格点、间距 1、R=1（n=3000），位行法
    std::vector<Pt> grid;
    grid.reserve(3000);
    for (int y = 0; y < 50; ++y) {
        for (int x = 0; x < 60; ++x) { grid.push_back({x, y}); }
    }
    const auto gadj = disk_adjacency(grid, 1);
    const long long gc = hidden_triples_bits(gadj);
    // 每个单位网格的四个角各给出一组 V（独立的结构下界）
    println("  大例（60×50 网格 3000 点，R=1）：隐藏集合 {} 组（≥ 4×格子数 {}）",
            gc, 59 * 49 * 4);
    assert(gc >= 59LL * 49 * 4);
}

int main() {
    cross_demo();
    segments_demo();
    hull_demo();
    closest_demo();
    polygon_demo();
    skyline_demo();
    line_region_demo();
    mec_demo();
    sensor_demo();
    hidden_terminal_demo();
    println("自检通过");
    return 0;
}
