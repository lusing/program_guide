#include <print>
#include <string>

// 23 继承：派生类的构造、访问与切片

// ═══ 23.1 基类与派生类：is-a 关系 ═══
class Box {
public:
    Box() { std::println("  Box()"); }
    explicit Box(double l, double w, double h) : length_{l}, width_{w}, height_{h} {
        std::println("  Box(l, w, h)");
    }
    Box(const Box& other) : length_{other.length_}, width_{other.width_}, height_{other.height_} {
        std::println("  Box(copy)");
    }
    ~Box() { std::println("  ~Box()"); }

    [[nodiscard]] double volume() const { return length_ * width_ * height_; }
    [[nodiscard]] double length() const { return length_; }

protected:                    // 派生类的成员函数可访问，类外不行（介于 public/private 之间）
    double length_ = 1.0;

private:                      // 基类私有：派生类也看不见——“继承 了”不等于“访问得到”
    double width_ = 1.0;
    double height_ = 1.0;
};

// ═══ 23.2 派生类：构造链、拷贝陷阱、析构链 ═══
class Carton : public Box {   // “Carton 是一种 Box” —— is-a 测试通过才用继承
public:
    // 不调基类构造时，基类部分由 Box() 默认构造——长宽高全是 1
    explicit Carton(std::string material) : material_{std::move(material)} {
        std::println("  Carton(material)");
    }
    // 正确姿势：初始化列表里显式转发给基类构造
    Carton(double l, double w, double h, std::string material)
        : Box{l, w, h}, material_{std::move(material)} {
        std::println("  Carton(l, w, h, material)");
    }
    // 拷贝构造最大的坑：漏写 Box{other} → 基类部分被默认构造（体积悄悄变 1）
    Carton(const Carton& other) : Box{other}, material_{other.material_} {
        std::println("  Carton(copy)");
    }
    ~Carton() { std::println("  ~Carton()"); }   // 基类析构还不是 virtual——见第 24 章

    // 同名成员/函数会“遮蔽”基类版本；Box:: 前缀可穿透遮蔽
    [[nodiscard]] double volume() const {
        return 0.9 * Box::volume();             // 纸箱壁厚打九折
    }
    [[nodiscard]] const std::string& material() const { return material_; }

private:
    std::string material_;
};

// ═══ 23.3 多重继承：语法 + 二义性消除 ═══
struct Powered {
    [[nodiscard]] const char* source() const { return "电池"; }
};
struct Networked {
    [[nodiscard]] const char* source() const { return "Wi-Fi"; }
};
class Tablet : public Powered, public Networked {
public:
    // 两个基类都有 source()：用 using 声明一次性指明用哪个，调用方免于写限定
    using Powered::source;
};

int main() {
    std::println("1) 默认构造链：基类先建，派生类后建");
    { Carton c{"纸板"}; (void)c; }

    std::println("2) 转发构造：基类用 Box(l,w,h) 初始化");
    Carton big{2.0, 3.0, 4.0, "瓦楞纸"};
    std::println("   big.volume() = {}", big.volume());

    std::println("3) 拷贝构造：正确版会先走 Box(copy)");
    Carton copy{big};
    std::println("   拷贝的体积 = {}（不是 1 说明基类部分被真拷贝了）", copy.volume());

    std::println("4) 遮蔽与穿透：{} vs Box:: 版 {}", big.volume(), big.Box::volume());

    std::println("5) 切片：按值赋给基类，派生部分被“削掉”");
    Box sliced = big;           // 只拷贝 Box 子对象：material_ 与九折规则都没了
    std::println("   sliced.volume() = {}（回到基类算法；多态的做法在第 24 章）", sliced.volume());

    std::println("6) 多重继承：using 消除 source() 二义性");
    Tablet t;
    std::println("   t.source() = {}", t.source());
    std::println("   限定版本：{} / {}", static_cast<Powered&>(t).source(),
                 static_cast<Networked&>(t).source());

    std::println("7) main 结束时析构：顺序与构造严格相反（见输出末尾：每对先 ~Carton 后 ~Box）");
    std::println("自检通过");
}
// main 结束后：copy、big 依次析构——输出里可见 ~Carton() 与 ~Box() 成对出现
