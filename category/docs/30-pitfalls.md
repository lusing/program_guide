# 30 坑位总清单与三书导读

## 30.1 Coq 高频坑
1. **Set Implicit Arguments 连锁**：范畴参数被隐化后显式应用要 @（06–17 章连环踩）；
   构造子/投影的模式槽数随参数隐化变化（17 章 pcat 的 2/4 槽之谜）。
2. **真宇宙多态**要 `Set Universe Polymorphism`——默认 @{u v} 只是命名全局宇宙（06 章实锤）；
   实例分隔符是空格、代数层（Set+1）在实例位置被拒。
3. 字段值要连隐式 binder 一起绑定（comp 5 个、assoc 7 个下划线）。
4. 依赖位 rewrite 弄病 motive：换 transitivity 桥接、sig_ext 只比第一分量、
   destruct eqn + f_equal 投影同行（12 章三连踩）。
5. `*` 默认解析 nat 乘法——类型位置写 prod（11 章）；[x] 记号在 refine 里要 (x :: nil)（21 章）。
6. 索引族递归定义走 revert+induction+Defined（03/17 章）；Qed 挡 delta。
7. 子弹层级嵌套：外层 `-` 里用 `+`（12 章）。
8. concat 的 A 显式——map concat 要钉实例（21 章）。

## 30.2 Agda 高频坑
1. 子句体只能引用模式绑定的变量：隐式 C/D/F/G 全部具名绑定（07/12 章连环踩）。
2. where 块不能模式绑定——搬 let；where 看不见外层子句的隐式。
3. suc 双义（Level/ℕ）→ renaming；stdlib 的 * 递归在第一参数、*-suc 右端反方向（05 章）。
4. 死 meta：FHom _ f 的下划线一律具名；显式钉 F/a 才能解锁（09 章 yoneda-round1）。
5. Mono/Epi 量化对象落在 o⊔ℓ；Σ 的谓词是 Prop 值时层级要算细（04 章）。

## 30.3 Lean 高频坑
1. `/-!` 模块文档注释内容不能以 - 开头（4.25 扫描器误判 unterminated comment）。
2. OfNat 在结构投影下推不出——(2 : Nat) 标注；具名隐式 (a := ())。
3. 方程式定义返回「第一参数」要具名（| p, .refl _ => p）——.refl _ 留 meta 卡死 iota（03 章）。
4. rw 看不见 iota 折叠子项——simp only [f] 先暴露；投影链用 show 折叠（09/16 章）。
5. Σ 不收 Prop 分量：泛性质按「Prop 性质 / structure 数据 / Σ' 混居」三分（04/11 章）；
   方程对用 ∧ 非 ×。
6. 核心库占用：Functor/Categories → FunctorC；cases+congr 1 是依赖字段 record 相等的官方通道（07 章）。

（Simmons 线新增）带参数 Record 的构造子/投影参数显隐；
f_equal 的目标数错位；依赖函数字段要 funext_dep；rewrite
的最右匹配；穷尽 destruct 的「f a 与 a 分家」；Lean 的
OfNat 不穿透投影类型、=/&& 优先级、Type 值 Le 用 def；
Agda 的元组嵌推理链、where 看不见隐式、Level/Data.Nat 双
suc、闭包假设要 cbv in 后 discriminate。

## 30.4 三书怎么读
| 书 | 定位 | 建议路线 |
|---|---|---|
| 贺伟《范畴论》 | 研究生主线 | 1–3 章逐章对读本教程 01–16；4–5 章配 19–22、27 |
| 《高级范畴论》 | 图与泛性质细、CS 章 | 1–2 章配 03–04；3 章配 09–13；5 章配 15–17；6 章配 27 |
| Simmons Solutions | 200+ 习题 | 全谱对照（见下表） |

**Simmons 章节对照表**（本书扩充后的完整地图）：

| Simmons | 本教程 | 核心内容 |
|---|---|---|
| 1.1–1.2 | 01 | 结构集配方（Pno 机器件）；Pfn/Set⊥ |
| 1.3–1.5 | 01/02 | 箭头不必是函数；Galois 预告；范畴 1/2 与主截面 |
| 2.1 | 04 | 图追逐（五角星旗舰） |
| 2.2 | 03 | mono/epi 全谱（选择子、ℕ↪ℤ、平衡反例） |
| 2.4–2.7 | 10/11 | 初始终对象、积/余积、等化子/拉回 |
| 2.8 | 02 | 反范畴的用法 |
| 3.1–3.3 | 05/09 | 函子与幂集三兄弟、从积来的函子、comma |
| 3.4–3.5 | 06/08 | NT 定义与例子（eval 双对偶、追 id 一圈） |
| 4.1–4.5 | 12 | 模板/解/泛解；双塔（极限 1、余极限 D） |
| 4.6 | 12 | Set/Eqv/Set-R/CMon 的极限算法 |
| 4.7 | 13 | 合流余极限与结构搬运 |
| 5.1–5.4 | 15 | 伴随定义、Table 5.1、样板间、解耦 |
| 5.5 | 16 | 自由/余自由（List ⊣ U 机器件、一般定理） |
| 5.6 | 26 | 反变伴随（⇑⇓、Ξ/Π、curry-and-chips） |
| 6.1–6.2 | 23 | 完备预序、保 sup ⟺ 右伴随 |
| 6.3–6.6 | 24 | 截面、两完备化、∃⊣I⊣∀、长伴随串 |
| 6.7–6.11 | 25 | R-集、Σ⊣U⊣Π、三角恒等式 |

## 30.5 三家速查
| | Coq 8.20 | Agda 2.8+stdlib 2.3 | Lean 4.25 |
|---|---|---|---|
| 范畴 | Record@{u v}+双开关 | record Category o ℓ | structure Category.{u,v} |
| record 相等 | 分量级止步（无原始投影） | setoid（_≈NT_） | 结构 η+内核 PI 免费 |
| funext | 公理入账 | postulate 入账 | 核心定理 |
| 依赖家族递归 | revert+induction+Defined | 模式匹配自动 | 方程式+simp only |

---

上一章：[29 压轴：把书串起来](29-capstone.md) · 下一章：（完）
