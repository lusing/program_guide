#pragma once
// 里氏替换反例：正方形继承长方形。
#include <string>

namespace dp {

class RectL {
public:
    virtual ~RectL() = default;
    virtual void set_w(int w) { w_ = w; }
    virtual void set_h(int h) { h_ = h; }
    [[nodiscard]] int w() const { return w_; }
    [[nodiscard]] int h() const { return h_; }
private:
    int w_ = 0;
    int h_ = 0;
};

class SquareL final : public RectL {
public:
    // 正方形的"合理性"破坏了长方形的后置条件：改宽会连带改高。
    void set_w(int w) override { RectL::set_w(w); RectL::set_h(w); }
    void set_h(int h) override { RectL::set_w(h); RectL::set_h(h); }
};

// 调用方按长方形的合同写代码：set_w(5); set_h(4); 面积应为 20。
inline int area_after_resize(RectL& r) {
    r.set_w(5);
    r.set_h(4);
    return r.w() * r.h();
}

}  // namespace dp
