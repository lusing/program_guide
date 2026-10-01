# CHEATSheet：类型论速查（typetheory 版）

> 25 章正文的浓缩。四家对照以 Coq / Agda / Lean 为主；
> Coq-HoTT 线（19–23 章）用自造 paths 的 mini 语法。

## 1 判断与规则

```text
四种判断：  A type    A ≡ B    a : A    a ≡ b : A
PTS 语法：  t ::= s | x | λ(x:A).t | t u | Π(x:A).B
公理：      * : □
规则 (s₁,s₂,s₃)：A:s₁, x:A ⊢ B:s₂ ⟹ Π(x:A).B : s₃
立方体：    λ→={(*,*)}  λ2+=+(□,*)  λP+=+(*,□)  λω+=+(□,□)  λC=全
```

## 2 类型构造器 × 逻辑（Curry–Howard 全表）

| 类型 | 逻辑 | Coq | Agda | Lean | 引入/消去 |
|---|---|---|---|---|---|
| `A → B` | 蕴涵 | `->` | `→` | `→` | λ / 应用 |
| `Π(x:A).B` | ∀ | `forall` | `∀`/`(x:A)→B` | `∀` | λ / 应用 |
| `A × B` | ∧ | `*`/`prod` | `×` | `×` | 组对/投影 |
| `A + B` | ∨ | `sum` | `⊎` | `Sum`/`⊕` | 注入/分情况 |
| `Σ(x:A).B` | ∃ | `sig`/`sigT` | `Σ` | `Σ` | 见证/拆包 |
| `⊥` | 假 | `Empty_set`/`False` | `⊥` | `Empty`/`PEmpty` | —/荒谬 |
| `⊤` | 真 | `True`/`unit` | `⊤` | `True`/`Unit` | trivial/— |
| `a = b` | 相等 | `eq`(Prop) | `_≡_`(Set!) | `Eq`(Prop) | refl/J |
| `{x // P x}` | 子集 | `{x \| P}` | `Σ`+谓词 | `Subtype` | 打包/拆值+证 |

## 3 相等的三副面孔

```text
定义相等 a ≡ b : A   沿定义展开（βδιζ）判定；rfl 居住
命题相等 a = b       相等类型的居留项；J 消去
泛等     A ≃ B ⇒ A = B   ua（公理/立方内核）
```

**方向学**：Coq/Agda 加法递归在**第一**参数（`2+n` 折叠）；
Lean 在**第二**（`n+2`、`m+0` 折叠）——类型里的算术选错朝向
就 rewrite（`Nat.zero_add`/`lia`/`+-suc`）。

## 4 J 与四件套

```text
J : P a refl → (e : a = y) → P y e          （refl 归纳）
sym    : a=b → b=a            motive: x ↦ x = a
trans  : a=b → b=c → a=c      归纳第二条
cong   : (f) a=b → fa=fb      motive: x ↦ fa = fx
subst/transport : a=b → P a → P b   motive: P 本体
funext : (∀x, fx=gx) → f=g    【公理】（Lean=Quot.sound 定理）
```

## 5 HoTT 五层楼

```text
19 路径   p·q、!p、ap f、transport ——群律全 J 免费推
20 泛等   idtoequiv : (A=B)→(A≃B) 是等价；ua 反向；β 记账
21 截断   Contr(-2) IsHProp(-1) IsHSet(0)…
          Prop=压平到 -1 层；funext ⇒ Π 对命题封闭
22 HIT    构造子造路径：区间/圆/商；消去子带「路径条款」；
          计算规则公理补账（cubical 里可计算）
23 环路   iterate (m+n) = iterate m · iterate n；
          π₁(S¹)=ℤ 要 encode-decode（coq-hott 教程续）
```

## 6 四家日常写法

```coq
(* Coq *)
Definition id {A} (a:A) := a.
Theorem t : forall n, 0 + n = n. Proof. induction n; simpl; auto. Qed.
Print Assumptions t.        (* 公理记账 *)
```
```agda
-- Agda（无 tactic：模式匹配即一切）
id : ∀ {A} → A → A
id a = a
+-zero : ∀ n → 0 + n ≡ n
+-zero n = refl             -- 定义折叠直接过
```
```lean
-- Lean（tactic/项式混用）
def id {A} (a : A) := a
theorem t : ∀ n, 0 + n = n := fun _ => rfl  -- Lean 方向相反！
#print axioms t
```

## 7 元理论一页

```text
CR（合流）   局部合流+SN ⟹ CR（Newman）；或并行归约+完全发展
SN（λ→）     逻辑关系法（Tait）：按类型赋良行为语义
SN（F）      Girard 消去剪枝（candidats）
主体归约     类型沿归约保持（代换引理是地基：24 章）
一致性       范式论证 + canonical forms
可判定性     λ→/F 检查可判定；F 推断不可判定（Wells）
```

## 8 精选坑位（25 章总清单的 TOP-10）

1. Lean `def f (n) : T → U | 0, _ => ...`——冒号前参数不匹配；
2. Coq 注释嵌套：`(*,*,*)` 会开层/闭层；
3. Coq `ltac:(lia)` 项位失灵——走 `Proof. exists. lia.`；
4. Coq record 构造子 seed 位要 `@MkX A B ...` 全显式；
5. Agda `inductive` 是保留字（目录名都不行）；
6. Agda 中缀构造子必须 `infixr`；裸 if 只吃 Bool（Dec 要 ⌊⌋）；
7. Lean `rw` 看不见 iota 折叠下的子项——`simp only [f]` 先暴露；
8. Lean 无 Cumulativity（`Nat : Type 5` 报错）——ULift 升层；
9. 自造 paths 必须 `Unset Automatic Proposition Inductives`；
10. HIT 计算规则公理补账 + `Print Assumptions` 每章公示。

## 9 build.ps1 用法

```powershell
pwsh -NoProfile -Command '& ./build.ps1 -All'        # 全量 61 单元
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 08'  # 单章
pwsh -NoProfile -Command '& ./build.ps1 -Lang lean'   # 单语言
pwsh -NoProfile -Command '& ./build.ps1 -File ex22'   # 按名过滤
pwsh -NoProfile -Command '& ./build.ps1 -Clean'       # 清理产物
```
