# 23 综合：圆周上的环路代数

> 对应读本：HoTT 书第 8 章（同伦群）；coq-hott 教程 13 章
>（完整 encode-decode）与 24 章压轴（螺旋覆叠）。
> 代码：`examples/23_capstone/ex23_capstone.v`——`iterate_add`
> 完整机器证明，依赖公理只有 S¹ 的构造子（Print Assumptions）。

## 23.1 任务：绕 m+n 圈 = 先绕 m 圈再绕 n 圈

```coq
Fixpoint iterate (n : nat) : base == base :=
  match n with 0 => idpath | S m => loop · iterate m end.

Theorem iterate_add (m n : nat)
  : iterate (m + n) == (iterate m) · (iterate n).
Proof.
  induction m as [| m IH]; simpl.
  - exact idpath.                  (* 基例：两侧都定义折叠 *)
  - refine (ap (fun X => loop · X) IH · _).
    exact (inverse (concat_assoc loop (iterate m) (iterate n))).
Defined.
```

证明的两块原料都是 19 章的路径代数：`ap`（把 IH 顶到 `loop ·_`
下）+ `concat_assoc`（括号右移，单步 J）。**这是 π₁(S¹) 加法
结构的第一块基石**——它说明「圈数」对加法保持。

## 23.2 通往 π₁(S¹) = ℤ：还差什么

完整的编码-解码（encode-decode）证明链：

```text
code : S¹ → U（每点配一个「解码空间」：base ↦ ℤ，loop ↦ +1 同构）
encode : (x == base) → code x           —— transport 的特化
decode : code x → (x == base)           —— circle_rec 按 code 走
两者互逆（在 base：ℤ ≃ Ω(S¹)）⇒ loop ≠ idpath（1 ↦ loop 不塌）
```

本迷你库做到 `iterate_add`；encode-decode 需要完整的泛等
计算规则与截断机械——**完整机器版在本仓库 coq-hott 教程
13 章**（基于官方 HoTT 库，含 `loop ≠ 1` 与螺旋覆叠压轴）。
两个教程互为表里：typetheory 讲原理的最小化，coq-hott 讲
工业级完整版。

## 23.3 诚实的「未机器化清单」

| 陈述 | 状态 | 出处 |
|---|---|---|
| `iterate_add` | ✅ 本章机器证明 | 零额外公理（除 S¹ 构造子） |
| `! iterate n == iterate (0-n)` | 正文练习（组装同 iterate_add） | 22 章坑位 |
| `loop ≠ idpath` | ❌ 需 encode-decode | coq-hott 13 章 |
| funext-from-interval | ❌ 需 eta/计算规则配合 | HoTT 书 4.9/6.3 |

公理的**用量与去向**全部 `Print Assumptions` 公示——读者可以
逐条审计「这个定理到底信了什么」。这是 mini-HoTT 的教学立场：
不求全，但求每一行都清楚来路。

## 23.4 第五部分总结：类型论的几何面

19 章起五步走：路径（J 的群律）→ 泛等（等价即相等）→
截断（层级塔）→ HIT（造空间）→ 环路代数（同伦群雏形）。
一条暗线贯穿：**「相等」从 Prop 搬到 Type，换来的是整个
高维世界**——这也是 cubical Agda / 新一代内核的进化方向。

> **坑位速记**
> ① `concat_assoc` 的 motive 引用 q 必须retype（q 做 match
> 参数）——19 章 ap_pp 同款；
> ② `iterate (S m + n)` 的 `simpl` 时机：基例靠定义折叠免证，
> 归纳步 refine 的两段组装要在 simpl 后一次拼好；
> ③ `Print Assumptions` 是公理审计的日常工具——mini 开发
> 每章收尾都跑一遍（本指南全五部分的惯例）。
