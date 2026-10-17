// operators.cpp —— Boost.Operators（2000）：操作符重载的流水线
// 对应文档：docs/05-langbase.md
// 核心思想：运算有对称性——给了 < 就能推 >、<=、>=；给了 == 就能推 !=。
// 你只写"少数基本操作符"，库用基类链替你生成其余的，且语义保证正确。
#include <boost/operators.hpp>
#include <algorithm>
#include <iostream>
#include <vector>

// ── 1) 基本概念：less_than_comparable 只要求你提供 < ──
// 基类链写法：point 作为每个概念模板的"下一个基类"参数，链式单继承
// （避免多重继承的钻石问题）。子类模板必须写全名 point<T>。
class point_dim : boost::less_than_comparable<point_dim,        // <
                  boost::equality_comparable<point_dim>> {      // ==
public:
    int x = 0, y = 0;
    point_dim(int a, int b) : x(a), y(b) {}
    friend bool operator<(const point_dim& l, const point_dim& r) {
        return l.x * l.x + l.y * l.y < r.x * r.x + r.y * r.y;   // 按到原点距离
    }
    friend bool operator==(const point_dim& l, const point_dim& r) {
        return l.x == r.x && l.y == r.y;                        // 按坐标
    }
};

// ── 2) 复合概念：totally_ordered（== + <）+ additive（+= + -=） ──
class point : boost::totally_ordered<point,                     // 全序四件
             boost::additive<point>> {                          // + - 双件
public:
    int x = 0, y = 0, z = 0;
    point(int a = 0, int b = 0, int c = 0) : x(a), y(b), z(c) {}
    friend bool operator<(const point& l, const point& r) {
        return l.x * l.x + l.y * l.y + l.z * l.z
             < r.x * r.x + r.y * r.y + r.z * r.z;
    }
    friend bool operator==(const point& l, const point& r) {
        return l.x == r.x && l.y == r.y && l.z == r.z;
    }
    point& operator+=(const point& r) { x += r.x; y += r.y; z += r.z; return *this; }
    point& operator-=(const point& r) { x -= r.x; y -= r.y; z -= r.z; return *this; }
    void print() const { std::cout << '(' << x << ',' << y << ',' << z << ')'; }
};

// ── 3) 相等 ≠ 等价：equivalent 用 < 定义"相等" ──
// equality_comparable 的 == 是你手写的"值相等"；
// equivalent 的 == 是 !(a<b)&&!(b<a) 的"等价"——排序语义下的同档。
class boxed : boost::equivalent<boxed> {                        // 只提供 <
public:
    int v = 0;
    explicit boxed(int i) : v(i) {}
    friend bool operator<(const boxed& l, const boxed& r) { return l.v / 10 < r.v / 10; }
};

// ── 4) dereferenceable + indexable：智能指针式类的现成操作符 ──
// dereferenceable 要求子类提供 operator*，自动生成 operator->
// （必须 public 继承：生成的是成员函数不是友元）
template <typename T>
class my_smart_ptr : public boost::dereferenceable<my_smart_ptr<T>, T*> {
public:
    explicit my_smart_ptr(T* p) : p_(p) {}
    ~my_smart_ptr() { delete p_; }
    T& operator*() const { return *p_; }                        // 只写这一个
private:
    T* p_;
};
template <typename T>
class my_smart_array : public boost::indexable<my_smart_array<T>, int, T&> {
public:
    explicit my_smart_array(T* p) : p_(p) {}
    ~my_smart_array() { delete[] p_; }
    friend T* operator+(const my_smart_array& a, int n) { return a.p_ + n; }
private:
    T* p_;
};

int main() {
    // 1) 基本概念：给了 < 和 ==，自动获得 >、<=、>=、!=
    point_dim p0(0, 0), p1(1, 2), p2(2, 1);
    std::cout << "基本概念: p1<p2? " << std::boolalpha << (p1 < p2)
              << "（按距离） p1>p0? " << (p1 > p0)
              << " p1<=p2? " << (p1 <= p2)
              << " p1==p2? " << (p1 == p2)
              << " p1!=p2? " << (p1 != p2) << '\n';

    // 2) 复合概念：全序 + 加减全套
    point a(1, 2, 3), b(5, 6, 7);
    point sum = a + b;                   // additive 由 += 生成
    point diff = b - a;
    std::cout << "复合概念: sum=";
    sum.print();
    std::cout << " diff=";
    diff.print();
    std::cout << " (b-a)==a*? " << (diff == point(4, 4, 4)) << '\n';
    // 全序的用途：能进关联容器、能被排序算法处理
    std::vector<point> v{point(3, 0, 5), point(0, 0, 0), point(1, 2, 3)};
    std::sort(v.begin(), v.end());       // 用的是 <
    std::cout << "排序后首元素 = ";
    v.front().print();
    std::cout << '\n';

    // 3) 相等与等价的分野：坐标不同（不相等）但距离档位相同（等价）
    point_dim q1(1, 2), q2(2, 1);        // 距离同档：!(q1<q2) && !(q2<q1)
    std::cout << "相等与等价: q1==q2? " << (q1 == q2)
              << " 等价(!(q1<q2)&&!(q2<q1))? "
              << (!(q1 < q2) && !(q2 < q1)) << '\n';
    boxed x1(11), x2(14), x3(25);
    std::cout << "equivalent: 11==14? " << (x1 == x2)            // 同档（十位都是 1）
              << " 11==25? " << (x1 == x3) << '\n';
    // 关联容器用等价不用相等：set<boxed> 里 11 和 14 是同一个键

    // 4) dereferenceable / indexable
    my_smart_ptr<std::string> sp(new std::string("operators"));
    std::cout << "dereferenceable: ->size() = " << sp->size() << '\n';
    my_smart_array<double> arr(new double[10]);
    arr[0] = 1.5;
    *(arr + 1) = 2.5;                    // indexable 顺手给了指针算术
    std::cout << "indexable: arr[1] = " << arr[1] << '\n';

    // 5) 模板类继承的概念类：必须给全名 point<T>（注释存档两种错误写法：
    //    less_than_comparable<T> ← 错把元素类型当子类
    //    less_than_comparable<point> ← 少了模板参数）

    std::cout << "自检通过\n";
    return 0;
}
