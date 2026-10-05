// file: src/value.hpp
// 第 59 章：值表示——NaN 装箱（匠书 §18 起步版 → §30.2–30.3 装箱版）。
// 本章值宇宙取匠书口径（数/布尔/空/对象），TIP 的 int64 直存宇宙
// 在正文对照说明——装箱的动机只在"值宇宙里有 double"时成立。
#ifndef TIP_VALUE_HPP
#define TIP_VALUE_HPP

#include <cstdint>
#include <memory>
#include <string>

namespace tip {

// ---------- 对象（堆侧）——本章只有 ObjString ----------
struct Obj {
    virtual ~Obj() = default;
};

struct ObjString : Obj {
    std::string text;
    uint32_t hash = 0;  // 驻留池的键：散列缓存（算一次用多次）
};

// ---------- Value 就是 64 位——NaN 装箱的全部家当 ----------
using Value = uint64_t;

constexpr uint64_t kSignBit = 0x8000000000000000ULL;  // 指针型借符号位当 tag
constexpr uint64_t kQnan     = 0x7ffc000000000000ULL;  // 静默 NaN 掩码（§30.2）
constexpr uint64_t kTagNil   = 1;  // 尾数低位的三个单例 tag（§30.3）
constexpr uint64_t kTagFalse = 2;
constexpr uint64_t kTagTrue  = 3;

// —— 构造 ——
inline Value numberVal(double d) {
    Value v;
    __builtin_memcpy(&v, &d, sizeof v);  // 位级重解释（合法且无 UB）
    return v;
}
inline Value boolVal(bool b) { return kQnan | (b ? kTagTrue : kTagFalse); }
inline Value nilVal() { return kQnan | kTagNil; }
inline Value objVal(const Obj *p) {
    // 指针藏进尾数：清掉 x86-64/ARM64 实际不用的最高字节后拼装
    return kSignBit | kQnan | (uint64_t)(uintptr_t)p;
}

// —— 判定 ——
inline bool isNumber(Value v) { return (v & kQnan) != kQnan; }        // 不是该 NaN 形即数
inline bool isBool(Value v) { return (v | 1) == (kQnan | kTagTrue); } // |1 合并真假两形
inline bool isNil(Value v) { return v == nilVal(); }
inline bool isObj(Value v) { return (v & (kQnan | kSignBit)) == (kQnan | kSignBit); }

inline double asNumber(Value v) {
    double d;
    __builtin_memcpy(&d, &v, sizeof d);
    return d;
}
inline Obj *asObj(Value v) { return (Obj *)(uintptr_t)(v & ~(kSignBit | kQnan)); }

// 反汇编/打印用
std::string showValue(Value v);

// 字符串构造（散列缓存一并算好）
std::unique_ptr<ObjString> makeString(std::string text);
uint32_t fnv1a(const std::string &s);  // FNV-1a 32 位（§19.3）

}  // namespace tip

#endif  // TIP_VALUE_HPP
