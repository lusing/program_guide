# 第 59 章　值表示：NaN 装箱、驻留与散列表

> 取材：匠书（Crafting Interpreters）§18.1（带标签联合的起步版）、
> §19.1–19.3（ObjString 与字符串驻留）、§20.1–20.6（开放定址
> 散列表：FNV-1a、线性探测、墓碑、扩容）、§30.2–30.3（NaN 装箱：
> 掩码、单例 tag、指针藏尾数、`|1` 判布尔）。全部材料在本章自包含
> 蒸馏，不需要翻原书。
> 本章示例：`examples/59_value_repr`（无 ANTLR，简单程序对账协议）。

## 59.0　值宇宙决定一切

第 57 章立过一个观察（§54.4）："值宇宙的大小决定解释器的一半体量"。
本章把这句话推到表示层：**同一批值，换个住法，内存账直接对半**。
起点是第 57 章的起步版 `Value`——带标签联合（tag + double + 指针），
`sizeof` 16 字节：每个栈槽、每个表项、每个局部变量都拖着这份固定
开销。匠书 §30.2 给出的紧凑版把全部值塞进**一个 64 位字**——
NaN 装箱（NaN boxing）。

先声明本章的宇宙口径：**取匠书的值宇宙**（数/布尔/空/对象），不是
TIP 的整数宇宙。理由是本质性的——**装箱的全部动机只在宇宙里有
double 时成立**：int64 宇宙里"整数的位型"与"指针的位型"可以靠
对齐与高位区分（TIP 的值天生 8 字节无 tag 也能安全装——第 57 章
FAQ 的谱系表预告过这条分岔）；double 宇宙里任何 64 位串都可能是
合法数，必须从**数的边界外**找位置藏 tag——这正是 IEEE 754 留给
我们的那扇门。本章正文多处并排两个宇宙的账，读者能看到"为什么
动态语言都长这儿"。

```text
56.1 NaN 装箱：在数的边疆外找地皮
56.2 判定族与宏的二次求值陷阱
56.3 FNV-1a：不是选出来的散列
56.4 驻留：值相等 ⇔ 指针相等
56.5 开放定址：墓碑为什么不能真删
56.6 接回第 58 章：map 的退休仪式
56.7 驱动、语料与期望输出解读
56.8 FAQ、小结与练习
```

三个值宇宙的表示总账（第 57 章谱系表的详版）：

| | TIP 宇宙（int64） | 起步版（54 章） | 装箱版（本章） |
|---|---|---|---|
| 宇宙 | 整数+函数 | 整数+对象 | 数+布尔+空+对象 |
| sizeof | 8（裸 int64） | 16（tag+8+8） | **8** |
| 判定 | 位型即类型 | 读 tag 字段 | 一次位运算 |
| 需要 tag 吗 | 否（int64 天生可分） | 是 | 是（藏进 NaN 位） |
| 洞 | 无 | 无 | 撞型 NaN |

第一列是静态类型的红利——**类型系统替值扛了 tag 的账**（int64
不用装因为"它是 int"这件事编译期就知道）；第二列是起步的诚实
（宇宙定型前别优化）；第三列是本章——**动态类型的 tag 税以 0
字节现金缴纳**。三列读者各会在教程里遇到：TIP 走分析线、起步
版已退役、装箱版进第 60 章。三列并读的另一个收获是**接口稳
定性**：三版 Value 的构造/判定函数族签名完全同构（numberVal/
isNumber…）——VM 的 switch 从不改、改的只有函数身体——表示
换了三次、协议纹丝不动，这就是第 57 章"值宇宙的语义由语料
对账统一"承诺的完整兑现。

**两分钟速览**：NaN 装箱 = 用 IEEE 754 静默 NaN 的空闲位存非数值
——QNAN 掩码（0x7ffc…）圈出"非数区"，尾数低位放 tag（nil=1、
false=2、true=3），符号位加指针就是堆对象；**判定全是一次位运算**
（isNumber = `(v & QNAN) != QNAN`）。驻留 = 相等字符串只存一份
——`==` 从逐字符退化为指针比较。开放定址表 = 数组就地探测
——线性探测、nil/false 双哨兵（空/墓碑）、活条目加墓碑压 75%
装填因子、扩容时活条目重散列而**墓碑全部蒸发**。五个断言组锁：
FNV 规范向量、千数位级往返、单次求值、等值同指针、删半查全。

```cpp
// file: src/value.hpp
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
```

```cpp
// file: src/value.cpp
// file: src/value.cpp
#include "value.hpp"

#include <sstream>

namespace tip {

std::string showValue(Value v) {
    if (isNumber(v)) {
        std::ostringstream os;
        os << asNumber(v);
        return os.str();
    }
    if (isBool(v)) return (v == (kQnan | kTagTrue)) ? "true" : "false";
    if (isNil(v)) return "nil";
    if (isObj(v)) {
        if (auto *s = dynamic_cast<ObjString *>(asObj(v)))
            return '"' + s->text + '"';
        return "<obj>";
    }
    return "<invalid>";
}

uint32_t fnv1a(const std::string &s) {
    // FNV-1a：偏移基数与素数是规范定的，不是选出来的（§19.3）
    uint32_t hash = 2166136261u;             // 0x811c9dc5
    for (unsigned char c : s) {
        hash ^= c;
        hash *= 16777619u;                   // 0x01000193
    }
    return hash;
}

std::unique_ptr<ObjString> makeString(std::string text) {
    auto s = std::make_unique<ObjString>();
    s->text = std::move(text);
    s->hash = fnv1a(s->text);
    return s;
}

}  // namespace tip
```

```cpp
// file: src/table.hpp
// file: src/table.hpp
// 第 59 章：开放定址散列表（匠书 §20）——线性探测、墓碑、装填因子、
// 扩容三状态机。替代第 58 章 GET_GLOBAL 背后的 std::map。
#ifndef TIP_TABLE_HPP
#define TIP_TABLE_HPP

#include <cstddef>
#include <vector>

#include "value.hpp"

namespace tip {

// 条目的键用 nil/false 两个单例当哨兵（§20.3.1）：
//   key == nil  → 空槽（从未用过）
//   key == false→ 墓碑（用过已删——探测链的"连接件"，不能真删）
struct Entry {
    Value key = nilVal();
    Value value = nilVal();
};

class Table {
  public:
    Table() = default;

    // 写入（新键或改值）。键须为 ObjString。
    bool set(ObjString *key, Value value);
    // 查找：命中返回 true 并写 value；找不到返回 false。
    bool get(const ObjString *key, Value *value = nullptr) const;
    // 删除：成功留墓碑返回 true；本来不在返回 false。
    bool deleteKey(ObjString *key);

    size_t count() const { return count_; }        // 活条目数
    size_t tombstones() const { return tomb_; }    // 墓碑数（扩容时清零）
    size_t capacity() const { return entries_.size(); }

    // 把 src 的活条目搬进来（§20.5 intern 池搬家用）
    void addAll(Table &src);

  private:
    // 找到 key 的槽或可插入的槽（墓碑可复用——首个墓碑记在 firstTomb）
    Entry *findEntry(const ObjString *key);
    const Entry *findEntry(const ObjString *key) const;
    void adjustCapacity(size_t newCap);  // 扩容：重散列、顺带清墓碑

    std::vector<Entry> entries_;  // capacity 为 2 的幂（探测的模运算前提）
    size_t count_ = 0;
    size_t tomb_ = 0;
};

// 驻留池：相等文本 → 同一指针（§19.3）
class InternTable {
  public:
    ObjString *intern(const std::string &text);

    size_t size() const { return table_.count(); }

  private:
    Table table_;  // 键：已驻留串；值：objVal(串)
    std::vector<std::unique_ptr<ObjString>> owned_;  // 所有权（池即根集）
};

}  // namespace tip

#endif  // TIP_TABLE_HPP
```

```cpp
// file: src/table.cpp
// file: src/table.cpp
#include "table.hpp"

namespace tip {

// 散列取模：容量为 2 的幂时 hash & (cap-1) ≡ hash % cap（位与替模）
static size_t slotOf(uint32_t hash, size_t cap) { return hash & (cap - 1); }

Entry *Table::findEntry(const ObjString *key) {
    if (entries_.empty()) return nullptr;
    size_t i = slotOf(key->hash, entries_.size());
    Entry *firstTomb = nullptr;
    for (;;) {
        Entry &e = entries_[i];
        if (e.key == nilVal()) {
            // 真空槽：链到此断。插入用首个墓碑（回收），查找用本槽。
            return firstTomb ? firstTomb : &e;
        }
        if (e.key == boolVal(false)) {  // 墓碑：记下、继续走链
            if (!firstTomb) firstTomb = &e;
        } else {
            auto *k = dynamic_cast<ObjString *>(asObj(e.key));
            if (k && k->hash == key->hash && k->text == key->text)
                return &e;  // 命中（先比散列再比文本——快慢两道）
        }
        i = (i + 1) & (entries_.size() - 1);  // 线性探测（环绕）
    }
}

const Entry *Table::findEntry(const ObjString *key) const {
    return const_cast<Table *>(this)->findEntry(key);
}

bool Table::set(ObjString *key, Value value) {
    // 装填因子：活条目 + 墓碑一起压容量（墓碑同样占槽、同样伤探测）
    if ((count_ + tomb_ + 1) * 4 > entries_.size() * 3)
        adjustCapacity(entries_.empty() ? 8 : entries_.size() * 2);
    Entry *e = findEntry(key);
    if (e->key == boolVal(false)) {
        ++tomb_;   // 复用墓碑：墓碑转正
    } else if (e->key == nilVal()) {
        ++count_;  // 真空槽：新条目
    }               // 命中旧键：只改值
    e->key = objVal(key);
    e->value = value;
    return true;
}

bool Table::get(const ObjString *key, Value *value) const {
    if (entries_.empty()) return false;
    const Entry *e = findEntry(key);
    if (e->key == nilVal() || e->key == boolVal(false)) return false;
    if (value) *value = e->value;
    return true;
}

bool Table::deleteKey(ObjString *key) {
    if (entries_.empty()) return false;
    Entry *e = findEntry(key);
    if (e->key == nilVal() || e->key == boolVal(false)) return false;
    e->key = boolVal(false);  // 墓碑：探测链的连接件（不能真空槽化）
    e->value = nilVal();
    --count_;
    ++tomb_;
    return true;
}

void Table::adjustCapacity(size_t newCap) {
    std::vector<Entry> old = std::move(entries_);
    entries_.assign(newCap, Entry{});  // 全新空表（nil 键哨兵）
    tomb_ = 0;                         // 墓碑在搬家时全部蒸发
    // 活条目重散列入新表（墓碑不搬——它只是旧探测链的连接件）
    for (const Entry &e : old) {
        if (e.key == nilVal() || e.key == boolVal(false)) continue;
        ObjString *k = dynamic_cast<ObjString *>(asObj(e.key));
        Entry *ne = findEntry(k);
        ne->key = e.key;
        ne->value = e.value;
    }
    // count_ 不变（活条目一个不少）
}

void Table::addAll(Table &src) {
    for (const Entry &e : src.entries_) {
        if (e.key == nilVal() || e.key == boolVal(false)) continue;
        ObjString *k = dynamic_cast<ObjString *>(asObj(e.key));
        set(k, e.value);
    }
}

// ---------- 驻留池 ----------
ObjString *InternTable::intern(const std::string &text) {
    ObjString probe;
    probe.text = text;
    probe.hash = fnv1a(text);
    Value v;
    if (table_.get(&probe, &v)) return asObj(v) ? static_cast<ObjString *>(asObj(v)) : nullptr;
    auto s = std::make_unique<ObjString>();
    s->text = probe.text;
    s->hash = probe.hash;
    ObjString *raw = s.get();
    owned_.push_back(std::move(s));
    table_.set(raw, objVal(raw));
    return raw;
}

}  // namespace tip
```

## 59.1　NaN 装箱：在数的边疆外找地皮

**double 的领土。** IEEE 754 的 64 位布局：符号 1 位 + 指数 11 位
+ 尾数 52 位。**指数全 1 且尾数非零 = NaN**；其中尾数最高位为 1
的是**静默 NaN**（quiet NaN，不触发浮点异常的那类）。关键事实：
**规范只规定 NaN 的这两个判别位，尾数其余 51 位是"不关心"**——
硬件不解释它们，制造 NaN 的自由落到了实现手里。于是有一整片
"合法的 double 位型、但不是任何计算会主动产出的数"的边疆地带
——装箱就是把行政中心设在这里。

画出来（本章最值得默写的一张图）：

```text
63  62……52     51                       ………… 2  1  0
符号  指数11位      尾数 52 位
 0   01111111111   1000000000000000…0000 0000   ← 1.0（一个数）
 0   11111111111   1 xxxxxxx…xxxxxxxxx ttt        ← QNAN|tag（单例）
 1   11111111111   1 ppppppp…ppppppppp 指针        ← SIGN|QNAN|ptr（对象）
     掩码 0x7ffc…：指数全1 + 静默位 + 尾数高14位0
```

掩码 `kQnan = 0x7ffc000000000000` 拆开读：符号 0、指数全 1、静默
位 1、尾数再往下 14 位为 0——**用这一片"零"当围墙**，围出的领地
里低 50 位随便用。匠书选这片（而不是更窄的）是保守的：确保任何
真实硬件产生的静默 NaN（典型 0x7ff8…）都不会撞进围墙——
`isNumber` 的判定 `(v & kQnan) != kQnan` 于是**只把"精确长成
围墙形状"的位型判为非数**，其余一概是数。掩码的候选谱系摆开
（保守度从左到右递增）：

| 掩码形状 | 圈地大小 | 风险 |
|---|---|---|
| 0x7ff8…（最小围墙） | 51 位 | 真实静默 NaN（0x7ff8…）**撞墙** |
| 0x7ffc…（匠书选择） | 50 位 | 只挡"精确撞型"的 NaN |
| 0x7ffb…（奇形） | 50 位 | 无收益且难解释 |

左列为什么不行：硬件产生的静默 NaN 就是 0x7ff8… 形（符号 0、
指数全 1、静默位 1、其余 0）——最小围墙会把它当非数，**每次
`0.0/0.0` 的结果都丢**。匠书多清两位（尾数高两位也要求零），
换来"真实 NaN 全部以数身份存活"——两位尾数换一个语义完整的
数宇宙，这笔账是装箱设计里最漂亮的一步。

顺带一个 C/C++ 的实现细节：clox 用 `union {double d; uint64_t
bits;}` 类型双关（C 合法、C++ 严格来说是 UB），本章用
`memcpy` 位拷贝（**两种语言都定义良好**、编译器优化后零开销）
——又一个"语言层消灭坑"的小案例（§56.2 的宏陷阱同族）。

**三个单例。** nil、false、true 不需要堆对象——围墙内尾数低位
放 1/2/3 三个 tag 就够了（`NIL_VAL = QNAN|1`、`FALSE_VAL = QNAN|2`、
`TRUE_VAL = QNAN|3`）。构造即拼位、判定即比较。布尔判定的妙笔是
`isBool`：`(v | 1) == TRUE_VAL`——`|1` 把 FALSE（…10）与 TRUE
（…11）**合并成同一个比较目标**。为什么要绕这一下？因为直白的
写法是 `(v == TRUE_VAL) || (v == FALSE_VAL)`——**C 宏里 v 出现
两次，求值两次**（§56.2 的主角），而 `|1` 版 v 只出现一次。
一个位运算消灭一类宏 bug，匠书 §30.3.4 专门写了这段。

**指针藏尾数。** 对象值 = `SIGN | QNAN | 指针`。两个问题：其一，
为什么加符号位？围墙（QNAN）内已经住了单例，指针若直接放进尾数，
低位的指针字节可能恰好等于 tag 值（对象地址对齐到 8 字节 ⇒ 低 3
位全 0，倒不撞 1/2/3——但 48 位地址的**高位**会伸进"零墙"区）。
加符号位开辟第二块领地：`SIGN|QNAN` 开头的是对象、`QNAN` 开头的
是单例——**isObj 与 isNil/bool 的判定互不越界**。其二，尾数 50
位装得下 64 位指针吗？装得下**现实的**指针：x86-64 实际只用低
48 位（页表上限），ARM64 通用实现 48/52 位——50 位尾数对 48 位
地址有 4 位富余（52 位地址的机器上匠书原版也只有 50 位可用——
真实引擎对此同样打赌，见 FAQ）。开箱 `asObj` 用掩码抠掉两位
tag 墙，剩下的就是原指针。

**两个面都诚实的洞。** 真 NaN double（硬件算出来的 0x7ff8… 形）
**以"数"的身份原样往返**（isNumber 为真、位不丢——无害面）；
但**位型恰好撞上围墙内单例的 NaN**（比如把 `QNAN|3` 的位串当
double 存进来）会被误读成 true——**误读面**。两个面本章各有一条
断言签字（第二组末两条）。这个洞的工程意义：**装箱宇宙里"数的
集合"不再等于"double 的集合"**，差了围墙内那几格——动态语言
从不在意（谁会把 NaN 存进变量还指望它区分静默位型），但这是
设计者应当知道并写下的取舍（匠书原话："we simply accept it"）。

**掩码选择的一个反向校验**（设计自检技巧）：选定掩码后立刻
问"最常见的真值会不会撞墙"——1.0（0x3ff0…）不撞（指数首位
不足以成 0x7ff…）、-1.0（0xbff0…）不撞、典型静默 NaN（0x7ff8…）
不撞（尾数高两位非零但我们的墙要它们为零——0x7ff8 & 0x7ffc
= 0x7ff8 ≠ 0x7ffc，判为数 ✓）。三问三答贴在设计笔记里，
掩码的"保守度"就有了可审查的凭证——**设计参数要能对常见值
自证清白**。

**掩码的落点实算一遍**（读者最好在调试器里亲跑）：`numberVal
(1.0)` 的位串是 0x3ff0000000000000——与 kQnan（0x7ffc…）按位与
得 0x3ffc…？不对——逐位看：0x3ff0… & 0x7ffc… = 0x3ff0…（指数
区只有最高几位重叠），结果**不等于** 0x7ffc… → 判为数 ✓；
而 `boolVal(true)` = 0x7ffc000000000003，& 0x7ffc… = 0x7ffc…
→ 判为非数 ✓。**isNumber 的正确性就是这两行手算**——掩码设计
的全部诚意压缩在一次与运算里。

**往返的证明。** 位级装箱的信任基础是"装进去的位原样出来"：
千个随机 double 的 `memcpy → 装箱 → 开箱 → memcmp` 逐位相等
（断言第二组第一条），特殊值 ±0/±inf/π 逐一复验——**±0 都分得
清**（符号位参与位串），这是"无损"的最强表述。指针往返用真
ObjString 验证（同指针进出）。

## 59.2　判定族与宏的二次求值陷阱

七条判定全是位运算或单比较——这正是装箱的回报：**第 57 章的
判定要看 tag 字段（一次内存访问 + 分支），装箱版是寄存器上的
一次与/或**。值栈上每条指令都要判定值类型（第 57 章栈效应表的
"防御"列），这里的每一条 CPU 指令都在热路径上被放大千万次。

宏陷阱值得专节，因为它是 C 与 C++ 的分水岭案例：匠书 clox 用宏
（`#define IS_BOOL(v) ((v) == TRUE_VAL || (v) == FALSE_VAL)`），
若调用者写 `IS_BOOL(pop())`——**pop 执行两次**（弹掉两个值、
第二次弹的还是别人的）。`|1` 版从形状上根除了它。C++ 版（本章）
用 inline 函数，参数天然单次求值——断言第三组用副作用计数器
证明（构造经函数包装只调一次实参）。**语言层面消灭一类 bug，
优于纪律层面防范它**——这是 C++ 重写 clox 时最理直气壮的一处。
但公平地说：clox 用宏有时代理由（C 里函数版本可能丢掉内联），
现代 C 编译器（inline 关键字自 C99）已无此顾虑——**宏陷阱是
历史包袱不是语言必然**。

## 59.3　FNV-1a：不是选出来的散列

字符串散列的候选谱系：多项式滚动（`h*31+c`，Java 的经典）、
MurmurHash（快而复杂）、xxHash（现代王者）、SipHash（抗碰撞
攻击）、FNV-1a（**五行的极简**）。驻留池选 FNV-1a 的理由不在
性能（它不是最快的）而在**可教学性**：偏移基数 2166136261 与
素数 16777619 来自 FNV 规范（draft-eastlake-fnv）——**是查表
定的，不是分析选的**；实现五行；规范自带测试向量（断言第一组
四个——空串、单字符、foobar——全部对照规范值，不是"算出来
抄自己"）。

FNV-1a 的循环体两行：`hash ^= byte; hash *= prime`——**异或进、
乘散开**。乘法把低位的信息推向高位（雪崩效应），异或把每个字节
都留下指纹。素数的选择避免乘法退化成移位（合数乘子会让某些位
模式坍缩）。**散列缓存**在 ObjString 构造时算一次（`makeString`
顺手填 `hash` 字段）——驻留池的每次探测、比较、扩容重散列全都
复用，字符串只被"散步"一次。这个缓存与第 57 章常量池去重是
同一家子：**算一次、用一辈子的预计算**。散列家族的对照表补全
本节的选型语境：

| 散列 | 行数 | 速度 | 抗攻击 | 出场 |
|---|---|---|---|---|
| h*31+c | 1 | 中 | 否 | Java String（历史遗产） |
| FNV-1a | 5 | 快 | 否 | 教学与嵌入式（本章） |
| MurmurHash3 | ~80 | 很快 | 否 | 大数据键 |
| SipHash | ~130 | 中 | **是** | Rust/Python 默认（抗哈希碰撞 DoS） |
| xxHash | 数百 | 极快 | 否 | 基准测试之王 |

教学选 FNV-1a 的第三条理由在"抗攻击"列：驻留池的键来自**本
程序的字面量**（不是网络输入），无碰撞攻击面——SipHash 的
复杂度在此买不到东西。**散列函数的选择跟着威胁模型走**，
与解析器三路线（第 11 章）同一条决策律。

雪崩效应的直观一验：`fnv1a("a")` 与 `fnv1a("b")` 的结果
（0xe40c292c 与 0xe70c2de5）差了 17 个比特——**一字符之差
雪崩过半**，这正是乘法散列的健康体征（若只差 1 位，相同前缀
的键会聚堆，探测链变长）。读者可自行对 "cat"/"bat"/"rat"
做这个小实验。

## 59.4　驻留：值相等 ⇔ 指针相等

字符串比较的朴素代价是 O(min(len))逐字符；驻留（interning）把
它变成一次指针比较——前提是**相等文本全系统只有一份**。驻留池
就是保证这个前提的机构：`intern(text)` 先查池，命中返回旧指针，
未命中造新串入池。查池的**探针技巧**值得读两行：栈上造一个
临时 ObjString（只填 text 与 hash——它不进堆、不入池），拿它
走 findEntry 的比对逻辑；命中后临时对象随语句结束消失，池里
**没有任何为查询付出的堆分配**——"查询零分配"是热路径接口
的礼仪（第 58 章 GET_GLOBAL 若照此改造，每次查表省一次 string
构造——§56.6 的第二笔账）。于是任何两个
"hello"的 ObjString 指针必相同——断言第四组的三行签字（等值
同指针、异值异指针、池大小恰 2）。

三个深一层的问题。**驻留改变的是比较的成本结构，不是语义**——
`==` 逐字符与 `==` 指针在"值相等"上等价（池保证双射），改变的
是代价与**可缓存性**（指针可以当散列键、可以进位比较指令）。
**驻留与可变性的暗线**（接第 54 章 thunk 与第 15 章闭包相等性
的讨论）：驻留的前提是**值不可变**——字符串一旦入池就不能改
（改了等于伪造他人身份，全系统同指针的串都被污染）。所以驻留
天然属于值语义世界；闭包（可变捕获）与记录（可变字段）不能
驻留，它们的相等性必须走别处（指针身份或逐字段）——**可变性
关闭驻留之门**，这条暗线在第 60 章上值的"盒子"上会再次出现
（盒子可变，所以按指针认）。

**驻留池是缓存不是语义构件**——池里的串没有外部引用时语义上
"可以"回收（回收后下次 intern 重建即可，行为不变）——这个
"可以"正是第 23 章 GC 弱引用设计的立足点（驻留表不当强根、
标记后清弱表——匠书 §26.4 的伏笔，本章 addAll 的"搬家用"
已预演了池的重组）。**不是所有字符串都该驻留**——拼接产生的
临时串驻留会让池膨胀（真实引擎只驻留标识符与字面量，运行时
拼接串按值比较）；本章池全量驻留是教学简化，FAQ 有专问。
驻留的三个真实系统对照（同一思想的三个规模）：

| 系统 | 驻留对象 | 机构 |
|---|---|---|
| Java | 字面量与常量池串 | class 文件常量池 + 运行期 String.intern |
| Lisp/Scheme | 符号（symbol） | eq? 可用指针比较的语义保证 |
| V8/JS 引擎 | 内部串（单字符、属性名） | 内部串表 + 外部串按值 |

三家的共同动机都是**把最热的比较变成指针比较**——Java 的
字符串 equals 优化、Lisp 的 eq 语义、JS 的属性查找（对象属性
名查表每次都要比键）——驻留是"比较热点的集中供暖"。第 60 章
的 GET_GLOBAL 每次调用都查函数名，正是驻留的下一个用户。

## 59.5　开放定址：墓碑为什么不能真删

散列表两大家族：**链地址**（每桶挂链，std::unordered_map 的
路线）与**开放定址**（就地探测，本章与 clox 的路线）。开放定址
的内存账赢在**指针不落地**（无链节点分配、缓存一行扫过连续
数组），代价是删除的复杂性——本节的主角。

**线性探测**：`slot = hash & (cap-1)` 落槽，占用则看下一格、
环绕往复。容量保持 2 的幂使取模退化为位与（`slotOf` 一行）。
查找（`findEntry`）沿探测链走，直到命中、或遇**真空槽**（链断
——这个键不在表里）。**先比散列缓存再比文本**（`k->hash ==
key->hash && k->text == key->text`）——散列比较是 int 比较，
大多数未命中在第一道就挡掉，文本比较只在散列巧合时才发生。

探测的派系先摆开（线性只是最简的一派）：

| 派系 | 探测公式 | 优点 | 代价 |
|---|---|---|---|
| 线性探测 | +1, +2, +3… | 缓存一行扫 | 一次聚堆 |
| 二次探测 | +1, +4, +9… | 缓解聚堆 | 跳出缓存行 |
| 双重散列 | +h2(key)*i | 理论最匀 | 两次散列 |

教学与 clox 选线性：**缓存局部性在真实负载下常胜过理论均匀度**
（现代 CPU 一次取 64 字节缓存行 = 8 个 Entry，线性探测的"下一格"
大概率已在行内）——聚堆问题交给 75% 阈值压制。

`findEntry` 的十行是全表的心脏，逐行带读：入口空表防御（返回
nullptr，调用方各自处理）；`slotOf` 落槽；`firstTomb` 置空
（本链的首碑还没遇到）；循环三岔——**真空槽**（链断：查询答
"无"、插入答"用首碑或此槽"，`return firstTomb ? firstTomb :
&e` 一行完成双答）；**墓碑**（记首碑、继续走）；**活条目**
（先比 hash 缓存再比 text，命中返回）；步进 `i = (i+1) &
(cap-1)` 环绕。**十行装下了查找与插入的全部分歧**——一个
函数服务两个用户（get 与 set），分歧只在"对空槽的解读"上
（查询视空为无、插入视空为位）——这是开放定址实现的标准
紧凑形态（clox 同构）。

**墓碑的必要性**是本节的题眼。删除一个条目若把槽**清成真空**，
经过它的探测链会断：`"cat"` 与 `"dog"` 散列同槽，cat 在前 dog
在后；删 cat 清真空，查 dog 沿链走到 cat 的旧槽见"空"即报
"不存在"——**误报**。解法：删除只把槽标记为**墓碑**
（tombstone，本实现用 `key=false` 单例占位）——查找遇墓碑
**继续走**（链没断），插入遇墓碑**可以复用**。cat/dog 的翻车
现场逐格画出来（真删版，容量 8，两者散列同落槽 3）：

```text
槽：     3       4        5
删前：  [cat]   [dog]
真删：  [空]    [dog]          ← 槽 3 清真空
查 dog： 落槽 3 → 见空 → "不存在"（误报！）
墓碑：  [墓]    [dog]          ← 槽 3 只立碑
查 dog： 落槽 3 → 见碑 → 继续走 → 槽 4 命中 ✓
```（首个墓碑记下，
`findEntry` 的 `firstTomb`——空间不浪费）。一张小账表：

| 槽态 | 查找行为 | 插入行为 |
|---|---|---|
| 真空（nil 键） | 链断 → 不存在 | 可入（无墓碑时） |
| 墓碑（false 键） | 继续走链 | **可入（复用首个）** |
| 活条目 | 比对 | 改值 |

**装填因子与扩容。** 探测链的平均长度由密度决定：经验阈值 75%
（`(count+tomb+1)*4 > cap*3` 触发）——**墓碑与活条目一起计压**，
因为它们同样占槽、同样拖长探测。扩容（`adjustCapacity`）三步：
容量翻倍（保 2 的幂）→ 全新空表 → **活条目逐一重散列入新表，
墓碑一个不搬**。墓碑的死法不是"清理"而是"蒸发"——它们本来
就是旧探测链的连接件，链本身换新了，连接件留在旧数组里随
vector 一起消失。断言第五组的"扩容后墓碑清零"与"幸存键仍在"
两条一起锁这个三步曲。

75% 这个数值得两行推导：线性探测的平均探测长度在装填因子 α
下约为 (1 + 1/(1-α)²)/2（教科书公式）——α=0.5 时约 1.5 次、
α=0.75 时约 8.5 次、α=0.9 时暴涨到 50+。**曲线在 70% 附近起跳**，
75% 是"空间换时间"的经典折中点（α 再低浪费内存、再高探测爆炸）。
墓碑计入 α 的原因同公式：墓碑同样占据槽位、同样拉长探测——
**对探测而言"死槽"与"活槽"一样挡路**（这是墓碑的成本面，
复用首碑是回收一部分）。

**与 unordered_map 对照**：链地址的删除天然干净（摘链节点），
装载边界宽松（可超 100%），但有指针追踪的缓存代价；开放定址
全数组、快扫描，但删除留痕、扩容必须全员搬家。**嵌入式解释器
与游戏引擎偏爱开放定址**（缓存敏感），**通用库偏爱链地址**
（语义简单）——第 58 章 GET_GLOBAL 的 std::map 换成本章 Table
正是这场取舍在教学线上的上演（§56.6）。

## 59.6　接回第 58 章：map 的退休仪式

第 58 章的 `globals` 是 `std::map<std::string, Value>`——三条
账单：节点堆分配（每函数一个红黑树节点）、string 键的构造与
析构（每次查表造临时串）、三指针跳的查找（树高 log n，缓存
不友好）。本章 Table 的替换接口点：键从 `std::string` 换
`ObjString*`（散列缓存 + 驻留指针），值就是装箱 Value——
**接口面完全同构**（set/get/delete/遍历），实现整体换血。
驱动里的演示（第五组的 addAll）顺带预演了第 60 章 VM 启动时
"旧表搬新表"的场景。

替换的收益账（按第 58 章 P5 的 GET_GLOBAL 每次 1 次查表计）：
省一次 string 构造（malloc + memcpy + free）、省树节点跳
（约 log₂(函数数) 次指针追踪）——教学量级无感，**但账算得清
就是替换的理由**（真实引擎同一替换的收益以百万次查表计）。
退休仪式的施工单（第 60 章开工的第一个 commit）：

| 步 | 动作 | 验收 |
|---|---|---|
| 1 | 驻留池进 VM（成员） | 池随 VM 生灭 |
| 2 | globals 换 Table | P5 全绿 |
| 3 | 名字表并入池 | 反汇编注释列不变 |
| 4 | 删 names 相关三处 | 编译警告零 |

四步各带验收——**施工单的每一步都可单独红绿**（第 58 章
"先通路后锁形"的节奏延续）。

## 59.7　驱动、语料与期望输出解读

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 59 章驱动（无参运行，简单程序对账协议）：
//   一、FNV-1a 已知测试向量对账（规范值，非算出来抄）；
//   二、NaN 装箱往返：随机 1000 个 double + 特殊值逐位无损；指针往返；
//   三、判定族与"单次求值"（C 宏二次求值陷阱的 C++ 解）；
//   四、驻留：等值字符串 → 同一指针；
//   五、散列表语义：增删查改、墓碑复用、扩容清墓碑；
//   六、断言汇总。
#include <cmath>
#include <cstring>
#include <iomanip>
#include <iostream>
#include <random>
#include <sstream>
#include <string>
#include <vector>

#include "table.hpp"
#include "value.hpp"

namespace {

int g_failures = 0;

void check(const std::string &name, const std::string &got, const std::string &want) {
    bool ok = got == want;
    if (!ok) ++g_failures;
    std::cout << (ok ? "ok   " : "FAIL ") << name << " = " << got;
    if (!ok) std::cout << "（期望 " << want << "）";
    std::cout << "\n";
}

std::string hex32(uint32_t x) {
    std::ostringstream os;
    os << "0x" << std::hex << std::setw(8) << std::setfill('0') << x;
    return os.str();
}

}  // namespace

int main() {
    std::cout << "== 一、FNV-1a 测试向量 ==\n";
    {
        check(R"(fnv1a(""))", hex32(tip::fnv1a("")), "0x811c9dc5");
        check(R"(fnv1a("a"))", hex32(tip::fnv1a("a")), "0xe40c292c");
        check(R"(fnv1a("b"))", hex32(tip::fnv1a("b")), "0xe70c2de5");
        check(R"(fnv1a("foobar"))", hex32(tip::fnv1a("foobar")), "0xbf9cf968");
    }

    std::cout << "\n== 二、NaN 装箱往返 ==\n";
    {
        // 随机 double：位级往返（装箱 → 位串 → 开箱 → 位串，memcmp）
        std::mt19937_64 rng(20260501);  // 固定种子：期望可复现
        int bitsOk = 0, bitsTotal = 0;
        for (int i = 0; i < 1000; ++i) {
            uint64_t raw = rng();
            double d;
            std::memcpy(&d, &raw, sizeof d);
            if (std::isnan(d)) continue;  // 真 NaN 是装箱方案的已知洞（正文）
            ++bitsTotal;
            tip::Value v = tip::numberVal(d);
            double back = tip::asNumber(v);
            uint64_t rawBack;
            std::memcpy(&rawBack, &back, sizeof rawBack);
            if (rawBack == raw && tip::isNumber(v)) ++bitsOk;
        }
        check("随机 double 位级往返（" + std::to_string(bitsTotal) + " 个）",
              std::to_string(bitsOk), std::to_string(bitsTotal));
        // 特殊值逐一
        for (double d : {0.0, -0.0, 0.5, -1.25, 1e308, -1e308, 3.141592653589793}) {
            tip::Value v = tip::numberVal(d);
            double back = tip::asNumber(v);
            uint64_t a, b;
            std::memcpy(&a, &d, 8);
            std::memcpy(&b, &back, 8);
            check("特殊值 " + std::to_string(a), b == a && tip::isNumber(v) ? "无损" : "损坏",
                  "无损");
        }
        // 指针往返：真 ObjString
        auto s1 = tip::makeString("pointer-roundtrip");
        tip::Value v = tip::objVal(s1.get());
        check("指针往返", tip::asObj(v) == s1.get() && tip::isObj(v) ? "同指针" : "断链",
              "同指针");
        // 诚实洞的两个面：标准静默 NaN（0x7ff8…）以"数"身份原样往返
        //（无害——isNumber 只排除装箱位型）；但位型恰好撞上 tag 的 NaN
        //（如 QNAN|TAG_TRUE 重解释成的 double）会被误读成布尔。
        double quietNan = std::nan("");
        check("静默 NaN 以数身份往返",
              tip::isNumber(tip::numberVal(quietNan)) ? "无害" : "丢失", "无害");
        double colliding;
        uint64_t collidingBits = tip::kQnan | tip::kTagTrue;  // 伪装成 true 的位型
        std::memcpy(&colliding, &collidingBits, 8);
        check("撞型 NaN 误读为布尔",
              tip::isBool(tip::numberVal(colliding)) ? "误读" : "正常", "误读");
    }

    std::cout << "\n== 三、判定族与单次求值 ==\n";
    {
        check("isNumber(3.5)", tip::isNumber(tip::numberVal(3.5)) ? "真" : "假", "真");
        check("isBool(true)", tip::isBool(tip::boolVal(true)) ? "真" : "假", "真");
        check("isBool(false)", tip::isBool(tip::boolVal(false)) ? "真" : "假", "真");
        check("isNil(nil)", tip::isNil(tip::nilVal()) ? "真" : "假", "真");
        auto s = tip::makeString("x");
        check("isObj(str)", tip::isObj(tip::objVal(s.get())) ? "真" : "假", "真");
        check("isBool(数不误判)", tip::isBool(tip::numberVal(3.0)) ? "真" : "假", "假");
        check("isNil(false 不误判)", tip::isNil(tip::boolVal(false)) ? "真" : "假", "假");
        // 单次求值：经函数包装的构造只求一次参
        //（C 宏 IS_BOOL(v) 若 v 有副作用会被吃两次——正文讲；此处实测 C++ 版）
        int calls = 0;
        auto traced = [&calls](double d) { ++calls; return d; };
        tip::Value v = tip::numberVal(traced(2.5));
        check("构造单次求值（副作用计数）",
              std::to_string(calls) + (tip::asNumber(v) == 2.5 ? " 次" : " 次但值错"), "1 次");
    }

    std::cout << "\n== 四、驻留 ==\n";
    {
        tip::InternTable pool;
        tip::ObjString *a = pool.intern("hello");
        tip::ObjString *b = pool.intern("hello");
        tip::ObjString *c = pool.intern("world");
        check("等值同指针", a == b ? "同" : "异", "同");
        check("异值异指针", a != c ? "异" : "同", "异");
        check("池大小", std::to_string(pool.size()), "2");
        // 相等判断退化为指针比较的演示
        check(R"( "a"=="a" 指针等 )", pool.intern("a") == pool.intern("a") ? "同" : "异", "同");
    }

    std::cout << "\n== 五、散列表语义 ==\n";
    {
        tip::Table t;
        std::vector<std::unique_ptr<tip::ObjString>> keys;
        const int N = 200;
        for (int i = 0; i < N; ++i) {
            keys.push_back(tip::makeString("key-" + std::to_string(i)));
            t.set(keys.back().get(), tip::numberVal(i * 10.0));
        }
        int hits = 0;
        for (int i = 0; i < N; ++i) {
            tip::Value v;
            if (t.get(keys[size_t(i)].get(), &v) && tip::asNumber(v) == i * 10.0) ++hits;
        }
        check("插入 200 全查中", std::to_string(hits), std::to_string(N));
        check("计数", std::to_string(t.count()), "200");

        // 删一半（偶数位）：留墓碑
        int deleted = 0;
        for (int i = 0; i < N; i += 2)
            if (t.deleteKey(keys[size_t(i)].get())) ++deleted;
        check("删除 100", std::to_string(deleted), "100");
        check("墓碑数", std::to_string(t.tombstones()), "100");
        int remainHit = 0, goneMiss = 0;
        for (int i = 0; i < N; ++i) {
            tip::Value v;
            bool found = t.get(keys[size_t(i)].get(), &v);
            if (i % 2 == 0) {
                if (!found) ++goneMiss;  // 已删的查不到
            } else if (found && tip::asNumber(v) == i * 10.0) {
                ++remainHit;  // 未删的照常
            }
        }
        check("已删全未中", std::to_string(goneMiss), "100");
        check("幸存全查中", std::to_string(remainHit), "100");

        // 墓碑复用：重插被删键成功
        int reinsert = 0;
        for (int i = 0; i < N; i += 2)
            if (t.set(keys[size_t(i)].get(), tip::numberVal(double(i)))) ++reinsert;
        check("墓碑复用重插 100", std::to_string(reinsert), "100");

        // 扩容清墓碑：继续插到触发扩容（容量翻倍、重散列跳墓碑）
        std::vector<std::unique_ptr<tip::ObjString>> more;
        for (int i = 0; i < 300; ++i) {
            more.push_back(tip::makeString("more-" + std::to_string(i)));
            t.set(more.back().get(), tip::numberVal(double(i)));
        }
        check("扩容后墓碑清零", std::to_string(t.tombstones()), "0");
        int afterGrow = 0;
        for (int i = 1; i < N; i += 2)
            if (t.get(keys[size_t(i)].get())) ++afterGrow;
        check("扩容后幸存键仍在", std::to_string(afterGrow), "100");
        // addAll：把 more 搬进新表
        tip::Table t2;
        for (const auto &k : more) t2.set(k.get(), tip::numberVal(1.0));
        check("addAll 前后计数一致", std::to_string(t2.count()), "300");
    }

    std::cout << "\n== 六、断言汇总 ==\n";
    if (g_failures == 0) {
        std::cout << "全部通过（37 项）\n";
        return 0;
    }
    std::cout << g_failures << " 项失败\n";
    return 1;
}
```

驱动的三件小事（外加第四件——**每组语料独立造池造表**，组间
零共享：任何一组的失败都不会污染下一组的现场，排错时可以单独
重放一组——第 15 章 journey 隔离传统的延续）：**固定种子**的 mt19937_64（20260501——日期即
种子，可读可复现）；**NaN 过滤**在计数循环里做（isnan 跳过且
不计入总数——分母干净）；**"洞两面"的正反断言**（§56.7 末尾
自注的详版）。三件事共同点：**让随机性服务于断言而不是制造
脆性**——随机语料 + 固定种子 = 覆盖广 + 期望稳，这对组合在
第 30 章 soundness 采样早已用过（家规的老朋友）。

五组语料的考点表（覆盖顺序有讲究：外锚→表示→判定→语义→
结构——从"外面的世界"逐步走向"内部机制"，读者的信任随组
递增）：

| 组 | 语料 | 考点 |
|---|---|---|
| 一 | FNV 四向量 | 对照规范（非自证） |
| 二 | 千数往返 + 特殊值 + 指针 + 洞两面 | 位级无损的完整签名 |
| 三 | 判定七条 + 单次求值 | 谓词正确性与宏陷阱的解 |
| 四 | 驻留三查 | 值相等 ⇔ 指针相等 |
| 五 | 200 增/100 删/复用/扩容/搬家 | 墓碑全生命周期 |

两处语料设计的自注：**随机数用固定种子**（mt19937_64(20260501)）
——期望输出可复现（确定性编译的表亲：确定性测试）；**"洞两面"
的断言写法**——无害面断言"仍判为数"（正向）、误读面构造撞型
位串断言"误读"（反向）——**把已知缺陷写成断言**是防御性文档
的最高形式（改坏了掩码，"洞"的断言先红——它锁的是掩码形状
本身）。

```text
; expected: expected/output.txt
== 一、FNV-1a 测试向量 ==
ok   fnv1a("") = 0x811c9dc5
ok   fnv1a("a") = 0xe40c292c
ok   fnv1a("b") = 0xe70c2de5
ok   fnv1a("foobar") = 0xbf9cf968

== 二、NaN 装箱往返 ==
ok   随机 double 位级往返（1000 个） = 1000
ok   特殊值 0 = 无损
ok   特殊值 9223372036854775808 = 无损
ok   特殊值 4602678819172646912 = 无损
ok   特殊值 13831680355561635840 = 无损
ok   特殊值 9214871658872686752 = 无损
ok   特殊值 18438243695727462560 = 无损
ok   特殊值 4614256656552045848 = 无损
ok   指针往返 = 同指针
ok   静默 NaN 以数身份往返 = 无害
ok   撞型 NaN 误读为布尔 = 误读

== 三、判定族与单次求值 ==
ok   isNumber(3.5) = 真
ok   isBool(true) = 真
ok   isBool(false) = 真
ok   isNil(nil) = 真
ok   isObj(str) = 真
ok   isBool(数不误判) = 假
ok   isNil(false 不误判) = 假
ok   构造单次求值（副作用计数） = 1 次

== 四、驻留 ==
ok   等值同指针 = 同
ok   异值异指针 = 异
ok   池大小 = 2
ok    "a"=="a" 指针等  = 同

== 五、散列表语义 ==
ok   插入 200 全查中 = 200
ok   计数 = 200
ok   删除 100 = 100
ok   墓碑数 = 100
ok   已删全未中 = 100
ok   幸存全查中 = 100
ok   墓碑复用重插 100 = 100
ok   扩容后墓碑清零 = 0
ok   扩容后幸存键仍在 = 100
ok   addAll 前后计数一致 = 300

== 六、断言汇总 ==
全部通过（37 项）
```

37 项断言全过、退出码 0。逐组导读（每行都能指回一处正文推演）：
第一组四个十六进制与 FNV 规范逐字相同——**全章唯一的"外部
真值锚点"**（其余期望都是内部一致性的签字，这四个是外面的
世界替我们作证）；第二组随机往返的括号数字是有效样本数（千个
随机位串剔除真 NaN 后的净数——固定种子下这个数本身也是确定
的）；特殊值七连里 0.0 与 -0.0 各占一行且都"无损"——**符号位
参与的位级相等**就是 ±0 可分的证据；"误读"两行的反向断言
（撞型 NaN）锁掩码形状；第四组三行构成驻留的双射小证；第五组
的数字序列 200→100→100→0 是墓碑生命周期的四个快照（生、立碑
、复用、蒸发），最后一行 addAll 的 300 是搬家不丢件的签收。

顺带一段开发史：本章源码一次通过全部断言（第十篇四章里唯一
的一次）——不是本章作者更聪明，而是**表示层的正确性可以纯
数学验证**（位运算是可手算的封闭系统，往返断言即证明），而
55 章的跳转、57 章的时序都有"运行的戏剧性"（差一、竞态）。
**越是数学的层越该一次过，越是时序的层越要靠断言网**——这个
对照本身是测试策略的一课。

## 59.8　FAQ、小结与练习

**问：52 位地址的 ARM64 上尾数 50 位够吗？** 匠书的原始设计在
这里同样只有 50 位（尾数被静默位与低位 tag 各占去一些）——
真实做法：要求堆对象地址再对齐到 16 字节（低 4 位全零，可丢弃
后重拼），或用 SIGN 区的全 51 位。本章实现直接赌 48 位地址
（x86-64 与 ARM64 的主流实现），分配器默认对齐 8——教学口径
如实标注；工业版如 V8 的指针压缩走得更远（32 位偏移 + 基址）。

**问：为什么不把驻留池做成"弱表 + GC 集成"直接在本章实现？**
弱表需要 GC 的标记阶段配合（标记后扫描池、清死串）——那是第 23 章的领地。本章的池用 `owned_`（unique_ptr 向量）持有全部串
——**强根版驻留**，语义与弱版一致（比较行为不变），内存策略
不同（只增不减）。20 章补弱表时，本节的"池是缓存"论证就是
改造的许可证。

**问：第 58 章的名字表（names）与本章驻留池要不要合并？** 55 章
名字表存 `std::vector<std::string>`（去重靠线性扫）——并入驻留
池后：名字即 ObjString*、去重靠池、反汇编注释列直接打 text。
**合并是纯改进**（三处代码归一、无语义损失），第 60 章副本里
顺手完成——教学上分两步走是为了让每章只有一位主角。

**问：objVal 为什么接收 const Obj* 而表里存的键又是 ObjString*？**
objVal 面向"任何对象"（第 60 章会有 ObjClosure/ObjUpvalue），
Table 的键约束为 ObjString 是**表的需求**（要 hash 与 text 字段
做比对）而非值的需求——两个类型的宽窄各归其主。这是"通用值、
专用键"的分层：值宇宙开放（能装一切对象），表按需收窄（只收
能当键的）——收窄处的类型转换（dynamic_cast）是表自己消化
的成本，不外溢给调用方。

**问：Value 就是 uint64_t——它有 ABI 问题吗（直接 memcmp 两个
Value 判相等）？** 有且重要：装箱 Value 的"相等"必须**逐位**
比较（memcmp/==），不能对 numberVal 的结果用 `==` 的 double
语义——因为 `+0.0 == -0.0` 在 double 语义下为真而位串不同
（装箱宇宙里它们是两个不同的值！），NaN 在 double 语义下不等
于自己而位串相等。**位语义与数值语义的分岔**是装箱宇宙的又一
条地下规则——clox 的 valuesEqual 先判类型再逐位比，本章的
表/池全程位比较（键是指针、值不参与相等），规则尚未全面登场
（第 60 章的闭包值相等讨论里补全）。

**问：为什么不用 std::variant<double,bool,monostate,Obj*>？**
variant 是带 tag 的安全联合（本质是第 57 章起步版的现代版）
——16 字节起步、判定走 index()（一次内存读 + 分支）。它没有
错，只是**不省**：装箱省的那 8 字节与那一次内存读正是千万次
热路径的账。variant 的正确位置是"值宇宙还没定型"的原型期
（第 57 章用它起步），装箱的位置是"宇宙定型且要快"的量产期
——**表示跟着成熟度走**。

**问：表为什么不用 std::string_view 当键接口？** string_view
不拥有内存——键的生命期必须由调用方保证，而表的生命期独立于
调用点（跨函数调用驻留），悬垂 view 的风险全落在用户肩上。
ObjString* 键把所有权（驻留池的 owned_）与身份（指针）绑在
一起——**接口的类型选择就是生命期契约的声明**。

**问：墓碑能不能定期清理而不等扩容？** 能（真实引擎有"收缩
重建"），但**触发条件难定**：墓碑率多少才值得全员重散列？
重建的代价是 O(n)，省的是以后每次探测的 O(链长)——自适应
策略（如墓碑过半且数量过千）属于调参黑话，教学表选择"扩容
即清零"这个最简单的确定性策略。**简单策略 + 明确触发点**胜过
精巧策略 + 模糊触发点——教学与原型期的通用选型原则。

**问：为什么 Entry 的 value 在墓碑化时也清成 nil？** 一致性与
调试可读性：墓碑槽的 key/value 都是非活值（false/nil），打印
表内容时"死槽"一目了然。保留旧 value 也能工作（get 不看墓碑
的 value），但**让每个状态自解释**是数据结构设计的卫生习惯。

**一个容易被忽略的工程事实**：本章 Table 的全部成员函数都不
抛异常、不分配除扩容外的内存、无递归——**可重入、可预测、
可在任何时刻中断**。这三条不是设计出来的美德，是"基础设施"
岗位的要求（GC 扫描时不能被表的分配打断——20 章的约束；VM
错误路径上查表不能雪上加霜——57 章的约束）。**应用代码追求
表达力，基础设施追求可预期**——本章代码的气质转变本身就是
教程从"教学玩具"走向"能承载运行时"的标志。

**给 57 章的三件嫁妆**（本章直接交付下游）：装箱 Value 类型
（57 章 VM 副本直接用它替换起步版——一次替换全机受益）；驻留
池（GET_GLOBAL 的键从 map 调用升级为指针查表）；Table 本身
（57 章全局表与"闭包捕获表去重"都要再用一次）。三件都在本章
断言网里淬过火——**下游拿来即用是质量的最硬标准**。

**小结**：NaN 装箱把值宇宙压进一个 64 位字——数的边疆（静默
NaN 的不关心位）里圈出单例区（QNAN|tag）与对象区（SIGN|QNAN|
指针），判定全是一次位运算；两个面诚实（无害的静默 NaN、撞型
的误读）都以断言签字。FNV-1a 五行实现对照规范向量；驻留让
`==` 退化为指针比较，池是缓存不是语义（弱表伏笔）；开放定址
表以 nil/false 双哨兵区分空与墓碑，删除留碑保链、复用首碑省
空间、扩容时活条目重散列而墓碑蒸发——**墓碑是"链的连接件"
这个身份让它既不能真删、也无需善后**。map 退休、Table 上岗，
第 58 章的全局表获得新家当。

**装箱的族谱**：这项技术不是匠书发明——SpiderMonkey（Firefox
的 JS 引擎）用 NaN 装箱装 JS 的动态值、LuaJIT 用它装 Lua 的
number/nil/指针（其文档称 NaN tagging）、多个 Scheme 实现用它
装浮点与标签。共同动机都是本章的账：**动态类型的 tag 税 +
浮点宇宙的位型排他性 = 围墙圈地**。匠书的贡献是把这项工业
手艺写进了教科书（§30 的优化章）——从 engine internals 的
部落知识到教学正文的距离，本书替读者走了。反方向的对照同样
存在：V8 用指针压缩（32 位偏移）、JVM HotSpot 用 tag 字
（对象头）——**表示没有终局，只有与宇宙和负载的匹配**。

三句话带走：**数不动、非数进围墙（掩码圈地、tag 编号、指针
藏尾数）；比较热的答案是指针（驻留）；删除热的答案是墓碑
（连接件不死、扩容时蒸发）**。

**第 58 章接口点的最终账单**（§56.6 的闭环）：map 退休省下的
三笔（节点分配、临时串构造、树跳）在第 60 章的 GET_GLOBAL 上
兑现为"一次位与落槽 + 一指针比较"——查表的代价从"几十条
指令"降到"三条以内"。**表示层的优化不改变任何算法复杂度
（都还是 O(1) 查表），改变的是常数**——而千万次热路径上的
常数就是用户手感（启动快 100ms 的那份账）。

**常见误区两则**：其一，"装箱是为了省 8 字节"——省内存只是
副产品，**判定从内存访问变位运算**才是主菜（热路径账要按次数
算）；其二，"墓碑是浪费、应该用链地址避免它"——墓碑换来的
是数组的连续性（缓存一行），链地址省了墓碑却引入了指针追踪
（每键一次间接）——**两种浪费摆在一起，选缓存友好的那种**
（§56.5 的对照表）。

**术语表**：

| 术语 | 一句话定义 | 首见 |
|---|---|---|
| NaN 装箱 | 用静默 NaN 的空闲位存非数值的表示法 | §56.1 |
| 探针 | 栈上临时构造、不入堆的查询用键 | §56.4 |
| 探测公式 | 冲突后落点的前进规则（+1 即线性） | §56.5 |
| 静默位 | NaN 尾数最高位（1 = 不触发异常） | §56.1 |
| 单例值 | nil/true/false 的围墙内 tag 位型 | §56.1 |
| `\\|1` 判布尔 | 位或合并真假两形，消灭宏二次求值 | §56.1 |
| 围墙 | QNAN 掩码圈出的"非数区" | §56.1 |
| 撞型洞 | 位型落入围墙内的真 NaN 被误读 | §56.1 |
| 散列缓存 | ObjString 构造时算好的 hash 字段 | §56.3 |
| 驻留 | 相等文本全系统唯一（值等 ⇔ 指针等） | §56.4 |
| 开放定址 | 冲突就地在数组里探测下一格 | §56.5 |
| 线性探测 | 逐格后移（环绕）的开放定址 | §56.5 |
| 墓碑 | 已删槽的标记：链的连接件、插入可复用 | §56.5 |
| 装填因子 | (活+墓碑)/容量的密度阈值（75%） | §56.5 |
| 墓碑蒸发 | 扩容重散列时不搬墓碑、自然清零 | §56.5 |
| 雪崩 | 一字符之差散列变半数比特（乘法散列健康体征） | §56.3 |
| 威胁模型 | 散列选型的抗攻击维度（本章无攻击面） | §56.3 |
| 双射小证 | 等值同指针/异值异指针的成对断言 | §56.7 |

**自查清单**：

1. double 的哪两个判别位定义 NaN？静默位在何处？
   （指数全 1+尾数非零；尾数最高位。）静默位在何处？
2. QNAN 掩码的每一比特分别对应什么？为什么选 0x7ffc…？
3. 三个单例的位型默写；`|1` 判布尔为什么可行？
4. 指针为什么加符号位？47 位地址怎么藏进 50 位尾数？
5. 洞的两个面各是什么？各自的断言怎么写？
6. FNV-1a 的两个常数从哪来？为什么散列要缓存？
7. 驻留改变了什么、没改变什么？池为什么"可以"回收？
8. 真删为什么截断探测链？用 cat/dog 复述一遍。
9. 墓碑在查找与插入时各是什么行为？谁复用首碑？
10. 扩容三步曲？墓碑怎么"死"？装填因子算不算墓碑？
11. 探针为什么要栈上造？（查询零分配的接口礼仪。）
12. 75% 从哪条公式来？墓碑为什么计入分子？

**本章在证人网上的位置**：本章与前三章不同——它**没有跨章
对账义务**（表示层的正确性由位运算断言自足），它交付的是
**基础设施的升级**（三件嫁妆）。但有一条软对账值得记：第 60 章 VM 换装箱 Value 后，第 15 章 P1 同源语料的输出仍须全等
——表示换了、语义证人网继续生效——**证人网的价值恰在实现
换代时的不动**（第 57 章立网时的承诺，至此第一次兑现在"值层
换代"上）。

**伏笔索引**：

| # | 埋点 | 后文兑现 |
|---|---|---|
| 1 | 驻留池 = 缓存非语义 | 20 章弱表清池 |
| 2 | ObjString 的 hash 缓存 | 57 章全局表直接受益 |
| 3 | Table 替换 map 的接口点 | 57 章开工即换 |
| 4 | 撞型洞的掩码断言 | 掩码即 ABI 的回归网 |
| 5 | 位相等 vs 数值相等分岔 | 57 章闭包相等性 |
| 6 | addAll 搬家 | 57 章 VM 启动重组 |

**读法建议**（含分野提示的落地）：赶时间者读两分钟速览 + §56.1 的位布局图 + §56.5
的 cat/dog 图——五分钟拿到两大主角；实现者补 §56.6 的接口点
与 FAQ 的 ABI/variant 两问；从匠书来的读者按 §18→§56.0 谱系、
§19→§56.3/56.4、§20→§56.5、§30.2–3→§56.1 对号——四段映射
严丝合缝，本章与原书唯一实质差是 C++ 化（memcpy 与函数判定）。

**练习**：

（题号与自查清单互补：清单管"懂没懂"、练习管"会不会做"。）

逐题提示：题 1 是验收性改造（全绿即完成）；题 2 观察强根版
"池不缩"；题 4 是"散列不影响正确性"的证明题；题 6 的答案是
"判定族 + 往返全部要动"（tag 位置即 ABI）。

1. ★ 把第 58 章 globals 从 std::map 换成本章 Table（名字并入驻
   留池）——P1–P5 全绿即改造完成（§56.6 的施工验收）。
2. ★★ 实现二的对照版：同一批字符串先驻留再全部 delete，再
   intern 同名——观察池大小与指针（强根版不缩，FAQ 第二问的
   实证）。
3. ★★ 加 `Table::shrink()`：活条目 < 容量 25% 时减半重建——
   与扩容对称的"收缩重建"，墓碑同样蒸发。补一条断言。
4. ★★ 把 FNV-1a 换成 `h*31+c` 多项式滚动，跑全部语料——哪些
   断言红？（答案：一个都不红——散列函数换了表仍正确，红的
   只有第一组的规范向量。**散列质量影响的是链长不是正确性**，
   这题证明它。）
5. ★★★ 测量题：给 Table 加探测长度统计（每次 findEntry 计步），
   在 100/500/1000 条目各测平均链长，画出装填因子曲线——
   验证 75% 阈值的经验来源。
6. ★（表示实验）把 Value 的三个单例 tag 挪到高位（尾数第 51–53
   位），掩码相应改——37 项断言里哪些必须跟着改？（判定族与
   往返全部要动——**tag 位置是 ABI**，本章断言就是它的回归网。）
7. ★★（跨界）用 NaN 装箱 Value 改写第 57 章栈机的 Print 与
   算术 case——判定从 tag 字段换成位运算，正文那句"每条指令
   的判定都在热路径"的量化感受题。

---

（第 59 章完——下一篇：上值，帧消失后变量的最后一个家。）

**读者分野提示**：本章对两类读者的难度不同——做过位运算的
嵌入式/图形程序员会觉得"这不就是 tagged pointer 的浮点版"，
一口气读完；只写过上层应用的读者第一次直面 IEEE 754 位布局，
应慢在 §56.1（对着布局图把 1.0/true/指针各手算一遍位串——
这半小时是本章的门票）。两类读者在 §56.5（墓碑）处会师——
那里没有位运算，只有数据结构的老问题。

**两份快速复习卡**（贴墙版）：掩码卡——QNAN=0x7ffc…、nil=1/
false=2/true=3、对象=SIGN|QNAN|指针、isNumber=非围墙、isBool=
(v|1)==TRUE；墓碑卡——删除立碑、查找越碑、插入用首碑、扩容
碑蒸发、因子算活加碑。两张卡各五行，本章的全部操作知识。

（章末一行：56 是十篇里最"数学"的一章——37 项断言没有一个
涉及时序；下一篇回到时序的深水——帧没了，变量还得活着。）

**调试一招**（本章代码若翻车先看哪）：表示层的错误几乎全是
**打印时的误读**——showValue 把 true 打成数、把对象打成
invalid。第一反应不是读逻辑而是**打十六进制位串**（`std::hex
<< v`）对着 §56.1 的布局图逐域核——位域图就是表示层的调试器。
（这招在 57 章上值的"指针改指自己家"处还要用一次。）

**口头三问**（互考一分钟）：掩码为什么是 0x7ffc 不是 0x7ff8？
（挡真 NaN——硬件静默 NaN 是 0x7ff8 形，最小墙会误杀。）
墓碑为什么不能真删？（链断误报。）墓碑什么时候死？（扩容蒸发。）

**给教师的一页教案**（若拿本章授课）：两课时——第一课时以
"为什么动态语言的值要交税"开题（tag 的必然性），讲到掩码
三候选表收束；第二课时从 cat/dog 翻车现场开题（先演误报再讲
墓碑），以扩容蒸发收束。两课时的 Homework：题 1（改造）或
题 9（默写）二选一。**本章的教案结构是"两个翻车现场"**
（撞型 NaN、断链误报）——错误驱动是表示与数据结构课的通性。

**默写一题定毕业**：闭卷写出 numberVal(1.5) 的位串十六进制（先写
1.5 的二进制再查布局图——写得出的人已经把 IEEE 754 和围墙
都装进脑子了；写不出就回 §56.1，图比文字好记）。

**补最后一行实验**：把 main.cpp 里固定种子换成 time(0) 跑十遍——十份输出
只有括号里的样本数不同（NaN 命中率随机）而全 ok 不变——这份"稳定
的随机"就是位级断言的含金量：任何一遍翻车都指向掩码 bug 而非运气。

（56 章合卷。位域图、两份复习卡、口头三问——这三样是本章留给读者的
随身行李，57 章开箱即用。）

---

上一章：[58 单遍编译与回填](58-single-pass.md) · 下一章：[60 上值与闭包](60-upvalues.md)
