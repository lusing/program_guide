# 18 单子

> 对书：贺伟 3.5/3.6 / Simmons 5.5。代码：`examples/18_monads/`。

单子 (T, η, μ)：**代数理论的范畴化身**。机器内容（Coq）：SetMonad record
（T + Tmap + ret + join，定律按元素给）+ List 单子完整验证（零公理）。
元素级定律 = 范畴级定律的 funext 打包（贺伟 3.5 模结构的点式内联）。

文档层：**伴随生成单子**（F ⊣ G ⟹ T := G∘F）——14 章的自由范畴伴随生成「路径单子」；
Kleisli/Eilenberg–Moore 范畴；**Beck 单子性定理**（贺伟 3.6）的精细条件需要极限完整机器化——边界记录。

## 坑位速记
1. 「对象层单子」写不下 η·Tη（T 要作用在态射上）——Set 级单子显式携带 Tmap 最省基础设施。
2. concat 的 A 是显式参数：map concat 里要 `concat (A:=A)` 钉实例——joinAssoc 的辅助引理先立再用。
3. join (ret x) = x 的单元素情形要 app_nil_r 收尾（++ nil 不定义折叠）。