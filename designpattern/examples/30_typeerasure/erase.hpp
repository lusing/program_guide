#pragma once
// 30 类型擦除：把"满足合同的具体类型"藏在构造函数里，外面只留一份接口。
// 三件套：Concept_（抽象接口）+ Model<D>（模板适配器）+ AnyDrawable（值语义外壳）。
#include <concepts>
#include <memory>
#include <string>
#include <utility>

namespace dp {

// 内部接口：只声明"能做什么"。名字带下划线——它是实现细节，不该被客户引用。
class Concept_ {
public:
    virtual ~Concept_() = default;
    virtual void do_draw(std::string& out) const = 0;
    virtual std::string do_id() const = 0;
};

// 合同：双接口 draw + id。lambda 只有 operator()，装不进来——必须包一层。
template <typename D>
concept DrawableLike = requires(const D& d, std::string& out) {
    d.draw(out);
    { d.id() } -> std::convertible_to<std::string>;
};

// 模板适配器：每个 D 实例化一份 Model，把调用转发给被藏起来的对象。
template <DrawableLike D>
class Model final : public Concept_ {
public:
    explicit Model(D d) : data_(std::move(d)) {}
    void do_draw(std::string& out) const override { data_.draw(out); }
    std::string do_id() const override { return data_.id(); }
private:
    D data_;
};

// 外壳：值语义、非模板。构造函数模板在调用点把 D 传给 Model。
class AnyDrawable {
public:
    template <DrawableLike D>
    AnyDrawable(D d) : self_(std::make_unique<Model<D>>(std::move(d))) {}

    AnyDrawable() = delete;                       // 没有对象就没有可转发的合同
    AnyDrawable(const AnyDrawable&) = delete;     // 擦除后的深拷贝需要 clone，本例从略
    AnyDrawable& operator=(const AnyDrawable&) = delete;
    AnyDrawable(AnyDrawable&&) = default;
    AnyDrawable& operator=(AnyDrawable&&) = default;

    void draw(std::string& out) const { self_->do_draw(out); }
    std::string id() const { return self_->do_id(); }

private:
    std::unique_ptr<Concept_> self_;
};

}  // namespace dp
