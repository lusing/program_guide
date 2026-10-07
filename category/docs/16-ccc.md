# 16 Cartesian 闭范畴

> 对书：贺伟 3.4 /《高级范畴论》6.3 / Simmons 5.x。代码：`examples/16_ccc/`。

CCC = 终对象 + 二元积 + 指数：**λ 演算的语义家**。指数 b^a 的泛性质 = curry 双射：
Hom(c × a, b) ≅ Hom(c, b^a)。机器内容：TyCat 的指数 = 函数类型、curry/uncurry 的两个往返等式（funext）。

抽象 CCC record 的定义要把 IsProduct 数据背在指数字段上（相互依赖）——教学版直接验证 hom 层双射（即「CCC 的 hom 层定义」）。

## 坑位速记
1. uncurry_round 要两层 funext（c 再 a）——一层留给函数相等一层留给参数。
2. curry 的类型要 @ 钉住（Set Implicit Arguments 隐化）。

---

上一章：[15 伴随与极限](15-adjlimits.md) · 下一章：[17 λ 演算与演绎系统构成的范畴](17-stlc.md)
