# 23 坑位总清单与三书导读

## 23.1 Coq 高频坑
1. **Set Implicit Arguments 连锁**：范畴参数被隐化后显式应用要 @（05–14 章连环踩）；
   构造子/投影的模式槽数随参数隐化变化（14 章 pcat 的 2/4 槽之谜）。
2. **真宇宙多态**要 `Set Universe Polymorphism`——默认 @{u v} 只是命名全局宇宙（05 章实锤）；
   实例分隔符是空格、代数层（Set+1）在实例位置被拒。
3. 字段值要连隐式 binder 一起绑定（comp 5 个、assoc 7 个下划线）。
4. 依赖位 rewrite 弄病 motive：换 transitivity 桥接、sig_ext 只比第一分量、
   destruct eqn + f_equal 投影同行（10 章三连踩）。
5. `*` 默认解析 nat 乘法——类型位置写 prod（09 章）；[x] 记号在 refine 里要 (x :: nil)（18 章）。
6. 索引族递归定义走 revert+induction+Defined（02/14 章）；Qed 挡 delta。
7. 子弹层级嵌套：外层 `-` 里用 `+`（10 章）。
8. concat 的 A 显式——map concat 要钉实例（18 章）。

## 23.2 Agda 高频坑
1. 子句体只能引用模式绑定的变量：隐式 C/D/F/G 全部具名绑定（06/10 章连环踩）。
2. where 块不能模式绑定——搬 let；where 看不见外层子句的隐式。
3. suc 双义（Level/ℕ）→ renaming；stdlib 的 * 递归在第一参数、*-suc 右端反方向（04 章）。
4. 死 meta：FHom _ f 的下划线一律具名；显式钉 F/a 才能解锁（08 章 yoneda-round1）。
5. Mono/Epi 量化对象落在 o⊔ℓ；Σ 的谓词是 Prop 值时层级要算细（03 章）。

## 23.3 Lean 高频坑
1. `/-!` 模块文档注释内容不能以 - 开头（4.25 扫描器误判 unterminated comment）。
2. OfNat 在结构投影下推不出——(2 : Nat) 标注；具名隐式 (a := ())。
3. 方程式定义返回「第一参数」要具名（| p, .refl _ => p）——.refl _ 留 meta 卡死 iota（02 章）。
4. rw 看不见 iota 折叠子项——simp only [f] 先暴露；投影链用 show 折叠（08/13 章）。
5. Σ 不收 Prop 分量：泛性质按「Prop 性质 / structure 数据 / Σ' 混居」三分（03/09 章）；
   方程对用 ∧ 非 ×。
6. 核心库占用：Functor/Categories → FunctorC；cases+congr 1 是依赖字段 record 相等的官方通道（06 章）。

## 23.4 三书怎么读
| 书 | 定位 | 建议路线 |
|---|---|---|
| 贺伟《范畴论》 | 研究生主线 | 1–3 章逐章对读本教程 01–16；4–5 章配 19–21 |
| 《高级范畴论》 | 图与泛性质细、CS 章 | 1–2 章配 03–04；3 章配 09–11；5 章配 13–15；6 章配 16–17 |
| Simmons Solutions | 200+ 习题 | 各章习题对照 mini 库练手；4 章极限计算配 11 章 |

## 23.5 三家速查
| | Coq 8.20 | Agda 2.8+stdlib 2.3 | Lean 4.25 |
|---|---|---|---|
| 范畴 | Record@{u v}+双开关 | record Category o ℓ | structure Category.{u,v} |
| record 相等 | 分量级止步（无原始投影） | setoid（_≈NT_） | 结构 η+内核 PI 免费 |
| funext | 公理入账 | postulate 入账 | 核心定理 |
| 依赖家族递归 | revert+induction+Defined | 模式匹配自动 | 方程式+simp only |

---

上一章：[22 压轴：把书串起来](22-capstone.md) · 下一章：（完）
