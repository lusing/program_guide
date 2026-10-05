// file: src/shape.hpp
// 第 15 章配套：代码形状——数组地址多项式、字符串表示、case 三策略（鲸书 §7.5–7.8）。
#ifndef TIP_SHAPE_HPP
#define TIP_SHAPE_HPP

#include <vector>

namespace tip {

// ---------- 数组地址多项式（行主序）----------

// 一维：@A + (i - low) * w
int vectorAddr(int i, int low, int w);

// 二维朴素多项式：@A + (i-low1)*len2*w + (j-low2)*w
int rowMajor2Naive(int i, int j, int low1, int high1, int low2, int high2, int w);

// 假零（false zero）：把下界项折进基址 @A0 = @A - (low1*len2 + low2)*w
// 访问只剩 @A0 + (i*len2 + j) * w —— 一次乘法（×w 可再换成移位）
int falseZeroBase(int low1, int high1, int low2, int high2, int w);
int rowMajor2FalseZero(int i, int j, int low1, int high1, int low2, int high2, int w);

// 枚举直查：按行主序把数组摆开，数 (i,j) 前面有几个元素——公式的"地面真值"
int rowMajor2Enumerate(int i, int j, int low1, int high1, int low2, int high2, int w);

// ---------- dope vector：运行期才知道的形状 ----------

struct DopeVector {
    int falseZero = 0;   // @A0：假零基址（调用方构造时算好）
    int stride = 0;      // len2：一行多少个元素
    int w = 4;           // 元素宽度
};

// 经 dope vector 取 A[i][j] 的地址（每次访问从描述子里现读 stride）
int dopeAddr(const DopeVector &d, int i, int j);

// 每种访问策略 emitted 的操作数（教学口径：数乘加与访存次数）
// 已知编译期形状：multI i,len2; add ; multI ,w; loadAO   → 2 乘 1 加 1 访存
int opsKnownShape();
// dope vector：loadAI stride; mult; add; mult; loadAO → 多一次 stride 的访存
int opsDopeShape();

// ---------- case 三策略（鲸书 §7.8.3）----------

enum class CaseStrategy { Linear, Binary, JumpTable };

// 按 (case 数, 标签密度) 选策略：≤3 线性；密集（密度≥0.5 且跨度≤64）跳转表；否则二分
CaseStrategy chooseStrategy(const std::vector<int> &labels);

// 命中 value 需要的比较次数：线性=位次；二分=折半步数；跳转表=1（一次范围检查）
int costLinear(const std::vector<int> &labels, int value);
int costBinary(const std::vector<int> &labels, int value);
int costJumpTable(const std::vector<int> &labels, int lo, int hi, int value);

// 均摊比较次数（对标签集合均匀取值；default 记 n 次/⌈log2⌉ 次）
double avgCost(const std::vector<int> &labels, int lo, int hi,
               int (*cost)(const std::vector<int> &, int));

// ---------- 字符串三表示 ----------

enum class StrRepr { Fixed, LengthPrefix, NulTerminated };

// length(a) 的访存次数：前缀=1（读长度字）；零终止=len+1（走到 '\0'）；定长=0（编译期常量）
int strlenTouches(StrRepr r, int len);

// length(a+b) 的访存次数：前缀=2；零终止=len(a)+len(b)+2
int concatLenTouches(StrRepr r, int lenA, int lenB);

}  // namespace tip

#endif  // TIP_SHAPE_HPP
