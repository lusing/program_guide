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
#include <cassert>
#include <cstdint>
#include <random>
#include <set>
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

int main() {
    cross_demo();
    segments_demo();
    hull_demo();
    closest_demo();
    polygon_demo();
    skyline_demo();
    println("自检通过");
    return 0;
}
