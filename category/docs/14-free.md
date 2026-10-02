# 14 自由与遗忘

> 对书：Simmons 5.5 / 贺伟 3.1 / 高级 5.2。代码：`examples/14_free/`。

自由构造的样板：**freeCat ⊣ 遗忘函子 U : Cat → Graph**。机器内容（Coq）：
GraphMap（顶点映射 + 每边一态射——端点方程按类型免费）+ 单位（边 ↦ 单边路）+ 延拓 extendPath（对 Path 归纳）+ 延拓保复合 extend_comp（零公理）。

「自由」的机器含义：任何 GraphMap 唯一延拓成函子 freeCat G → C——泛性质的组装版。
04 章的 freeCat 基础设施在此全部复用。

## 坑位速记
1. 目标是图时保端点方程是命题（04 章 GraphHom）；目标是范畴时依赖类型让运输消失（GraphMap）——同一定义的两种宇宙待遇。
2. 索引族递归定义走 induction 式 + Defined；as-模式第四个名字是「函数应用的递归假设」。