#ifndef DS_POLYNOMIAL_HPP
#define DS_POLYNOMIAL_HPP

#include <algorithm>
#include <cmath>
#include <compare>
#include <initializer_list>
#include <string>
#include <vector>

namespace ds {

// 一元稀疏多项式：项按指数降序存放，系数为 0 的项一律不保存。
struct Term {
    double coef;
    int exp;

    bool operator==(const Term&) const = default;
};

class Polynomial {
public:
    Polynomial() = default;

    Polynomial(std::initializer_list<Term> terms) : terms_(terms) {
        normalize_();
    }

    // 加法：指数相同的项合并；合并后系数为 0 的项消失（如常数项 +1 与 -1）。
    Polynomial operator+(const Polynomial& other) const {
        Polynomial result;
        result.terms_.reserve(terms_.size() + other.terms_.size());
        std::size_t i = 0;
        std::size_t j = 0;
        while (i < terms_.size() || j < other.terms_.size()) {
            if (j == other.terms_.size() ||
                (i < terms_.size() &&
                 terms_[i].exp > other.terms_[j].exp)) {
                result.terms_.push_back(terms_[i++]);
            } else if (i == terms_.size() ||
                       terms_[i].exp < other.terms_[j].exp) {
                result.terms_.push_back(other.terms_[j++]);
            } else {
                result.terms_.push_back(
                    Term{terms_[i].coef + other.terms_[j].coef,
                         terms_[i].exp});
                ++i;
                ++j;
            }
        }
        result.normalize_();
        return result;
    }

    // 乘法：每两项相乘（系数相乘、指数相加），再按加法规则归并去零。
    Polynomial operator*(const Polynomial& other) const {
        Polynomial result;
        result.terms_.reserve(terms_.size() * other.terms_.size());
        for (const Term& a : terms_) {
            for (const Term& b : other.terms_) {
                result.terms_.push_back(Term{a.coef * b.coef,
                                             a.exp + b.exp});
            }
        }
        result.normalize_();
        return result;
    }

    bool operator==(const Polynomial&) const = default;

    [[nodiscard]] std::size_t term_count() const noexcept {
        return terms_.size();
    }

    const Term& term(std::size_t i) const { return terms_[i]; }

    // 人类可读形式，例如 "x^2 - 1"、"2x"。
    std::string to_string() const {
        if (terms_.empty()) {
            return "0";
        }
        std::string out;
        for (std::size_t i = 0; i < terms_.size(); ++i) {
            const Term& t = terms_[i];
            const bool negative = t.coef < 0;
            const double abs_coef = std::abs(t.coef);
            if (i == 0) {
                if (negative) {
                    out += "-";
                }
            } else {
                out += negative ? " - " : " + ";
            }
            const bool show_coef =
                t.exp == 0 || abs_coef != 1.0;
            if (show_coef) {
                out += format_number_(abs_coef);
            }
            if (t.exp > 0) {
                out += "x";
                if (t.exp > 1) {
                    out += "^" + std::to_string(t.exp);
                }
            }
        }
        return out;
    }

private:
    // 归并后整理：按指数降序、同指数合并、丢掉零系数项。
    void normalize_() {
        std::sort(terms_.begin(), terms_.end(),
                  [](const Term& a, const Term& b) { return a.exp > b.exp; });
        std::vector<Term> merged;
        for (const Term& t : terms_) {
            if (!merged.empty() && merged.back().exp == t.exp) {
                merged.back().coef += t.coef;
            } else {
                merged.push_back(t);
            }
        }
        terms_.clear();
        for (const Term& t : merged) {
            if (t.coef != 0.0) {
                terms_.push_back(t);
            }
        }
    }

    static std::string format_number_(double v) {
        if (v == static_cast<double>(static_cast<long long>(v))) {
            return std::to_string(static_cast<long long>(v));
        }
        return std::to_string(v);
    }

    std::vector<Term> terms_;
};

}  // namespace ds

#endif  // DS_POLYNOMIAL_HPP
