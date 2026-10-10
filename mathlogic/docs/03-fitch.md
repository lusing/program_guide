# 第 3 章 费奇式自然演绎：行号、范围线与作用域纪律

> 对书：马明辉《结构证明论》2.1 节（p26-31）。
> 本章通道：C（`examples/03_fitch/ex3_fitch.v`）/ L（`examples/
> 03_fitch/ex3_fitch.lean`）/ P（`examples/03_fitch/ex3_fitch.pl`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `fitchOK`/`check1`/`levelsOK` | **费奇推导完整检查器**：级别纪律+作用域可达性+依据逐行核 | C/L/P |
| `accSame`/`accUp` | **作用域可达性**：同框引用（推理规则专用）与恰上一级引用（Reit 专用） | C/L/P |
| `exIntro`/`exId`/`exComm`/`exSyll` | 书例重演：引例三则+四级级联 Reit 十一步链 | C/L/P |
| `exDNE`/`exLem` | ¬¬α→α 与 p∨¬p 的 FK 归谬推导；**FJ 拒收同推导**（¬E 是 FK 独有） | C/L/P |
| `kforce`/`acc01` | FJ 侧 LEM 反例：两点 Kripke 链上 p∨¬p 在 0 点假、¬¬(p∨¬p) 两点真 | C/L |
| `badCross`/`goodCross` | 跨级引用抓错现场：漏 Reit 被拒，补中转行即通过 | C/L/P |

第 2 章之前的世界里，「证明」还只是一个语义概念（赋值全真的公式）。
本章起开始**写证明**。写证明的第一种记法不是树，而是竖线与行号——
费奇式自然演绎（Fitch-style natural deduction）：每一行是一个公式，
左侧编号，右侧写「这行凭什么」，假设引入时向右缩一格，子证明结束时
框线闭合、假设撤销。这是最接近人类书写习惯的证明记法，也是大多数
逻辑教学软件（Fitch/Barwise 的 *Language, Proof and Logic* 等）采用
的形式。马明辉书 2.1 节把它作为自然演绎的第一站，本书教程照此办理
——下一章（04 章）才换根岑式的树形记法，两者是同一套演算的两件外衣。

## 一、为什么需要另一种记法：证明的组织方式

比较同一个推理在三种记法下的样子。语义（第 2 章）：「α, α→β, ¬β ⊢ ⊥
有效」要说一整句话；树形 ND（04 章）：前提作叶子、规则作节点，证明
向上生长；费奇式：**证明按行推进，假设用「框」管理**——

```text
1│ α        Pre
2│ α→β      Pre
3│ ¬β       Pre
4│ β        →E: 2,1
5│ ⊥        →E: 3,4
```

每一行右侧的「依据」引用行号：第 4 行凭第 2 行的蕴涵与第 1 行的前件
（→E），第 5 行凭第 3 行的否定作用于第 4 行（¬β 就是 β→⊥）。这个五
行推导是书 p26 的开篇引例，机器上就是五条行数据（`examples/03_fitch/
ex3_fitch.v`）：

```coq
Definition exIntro : fitch :=
  [ mkfl 0 p0 Pre
  ; mkfl 0 (fimp p0 p1) Pre
  ; mkfl 0 (fneg p1) Pre
  ; mkfl 0 p1 (IEf 2 1)
  ; mkfl 0 fbot (IEf 3 4) ].

Example exIntro_ok : fitchOK 1 exIntro = true.
Proof. reflexivity. Qed.
```

`mkfl 级别 公式 依据` 是行数据的三个分量；`fitchOK 1 d` 表示「按 FK
（经典系统）检查推导 d」。它返回 `true`——检查器逐行核对了每个依据
的合法性。检查器怎么造，是本章的主线。

费奇式的表达力在「框」上：要证 α→α，先假设 α、推出 α、再出框：

```coq
Definition exId : fitch :=
  [ mkfl 1 p0 Hyp                      (* 1: 假设 α，开一级框 *)
  ; mkfl 1 p0 (Reit 1)                 (* 2: 重复第 1 行 *)
  ; mkfl 0 (fimp p0 p0) (IIf 1 2) ].   (* 3: 出框得 α→α *)
```

第 2 行的 `Reit 1` 不是废物——它是费奇式**作用域纪律**的第一次现身：
框内的推理规则只能引用**同框**的行；要用框外的公式，必须先用 Reit
（重复规则）把它搬进来。这条纪律让「假设的作用范围」成为语法的一部
分，而不是靠读者的直觉追踪。

## 二、FJ 的规则全表：结构规则与联结词规则

书定义 2.1 给出直觉主义费奇系统 **FJ**（我们按教程惯例把书中的 Greek
字母换成 p0/p1/p2）：

**结构规则**两条：

- **(Hyp) 假设规则**：任何地方可临时引入假设，开始新子证明（向右
  缩进一级）；子证明结束时假设被撤销。
- **(Reit) 重复规则**：可以重复**同一级子证明中该步骤之前**的公式，
  以及**恰上一级子证明中**的公式。

**联结词规则**七组（依据格式 `规则:引用行`）：

| 规则 | 依据 | 前提→结论 |
|---|---|---|
| ∧I | m,n | 行 m 为 α、行 n 为 β ⟹ α∧β |
| ∧E | m | 行 m 为 α∧β ⟹ α（或 β） |
| ∨I | m | 行 m 为 α ⟹ α∨β（或由 β） |
| ∨E | m, (a-b), (c-d) | 行 m 为 α∨β；框 a-b 由 Hyp α 推出 γ；框 c-d 由 Hyp β 推出 γ ⟹ γ |
| →I | a-b | 框 a-b 由 Hyp α 推出 β ⟹ α→β |
| →E | m,n | 行 m 为 α→β、行 n 为 α ⟹ β |
| ⊥E | m | 行 m 为 ⊥ ⟹ 任意公式 |

经典系统 **FK = FJ + 一条框式归谬规则 (¬E)**：框 a-b 由 Hyp ¬α 推出
⊥ ⟹ α。注意 ¬E 与 →I 的对称：→I 从「假设 α 得矛盾」造 **¬α**（这
是 FJ 就有的，因为 ¬α 就是 α→⊥）；¬E 从「假设 ¬α 得矛盾」造 **α**
（这一步跳出直觉主义，正是经典性的入口——第 5 章 04 章的 RAA 同源）。

机器检查器的核心是两个可达性判定（`ex3_fitch.v`）：

```coq
(* 同框可达：同级、之前、且中间无同级 Hyp 开新框 *)
Definition accSame (d : fitch) (m i : nat) : bool :=
  match getv d m, getv d i with
  | Some vm, Some vi =>
      andb (Nat.eqb vm vi) (andb (Nat.ltb m i)
        (negb (anyHypLv d i (S m) i vm)))
  | _, _ => false
  end.

(* 上一级可达：级别恰差一、之前、且父框未闭合 *)
Definition accUp (d : fitch) (m i : nat) : bool :=
  match getv d m, getv d i with
  | Some vm, Some vi =>
      andb (Nat.eqb vi (S vm)) (andb (Nat.ltb m i)
        (negb (anyBelow d i (S m) i vm)))
  | _, _ => false
  end.
```

`accSame` 回答「推理规则能否引用行 m」：同级（`Nat.eqb vm vi`）、在
前（`Nat.ltb m i`）、且中间没有同级的 Hyp——同级 Hyp 意味着新开了一
个并列框，旧框的行不再可用。`accUp` 回答「Reit 能否引用行 m」：级别
恰差一（Reit 只搬**恰上一级**的公式，不能隔级取物）、且父框在引用点
仍未闭合（中间没有级别降到父级以下的行——那意味着父框已出）。

配套的**级别纪律**（`levelsOK`/`stepOK`）约束行与行之间的级别跳变：
至多加深一级、加深必是 Hyp、Hyp 只能开同级并列框或加深框、前提
（Pre）恒在最外层。这三件合起来，费奇推导的合法性检查就是纯机械的
逐行核对：

```coq
Definition fitchOK (kc : nat) (d : fitch) : bool :=
  andb (levelsOK d) (checkAll d kc (S (length d)) 1).
```

参数 `kc` 是系统开关：0 查 FJ，1 查 FK（允许 ¬E）。

## 三、书例逐步重演

**例 2.1(3)：⊢FK ¬¬α→α**。这是框式归谬的标准演出：外框假设 ¬¬α，
内框假设 ¬α 推出 ⊥，¬E 出内框得 α，→I 出外框收尾：

```coq
Definition exDNE : fitch :=
  [ mkfl 1 (fneg (fneg p0)) Hyp        (* 1: ¬¬α，一级框 *)
  ; mkfl 2 (fneg p0) Hyp               (* 2: ¬α，二级框 *)
  ; mkfl 2 (fneg (fneg p0)) (Reit 1)   (* 3: 把 ¬¬α 搬进二级框 *)
  ; mkfl 2 fbot (IEf 3 2)              (* 4: ⊥ *)
  ; mkfl 1 p0 (NEf 2 4)                (* 5: ¬E 归谬得 α *)
  ; mkfl 0 (fimp (fneg (fneg p0)) p0) (IIf 1 5) ].

Example exDNE_fk : fitchOK 1 exDNE = true.   (* FK：通过 *)
Example exDNE_fj_rejects : fitchOK 0 exDNE = false.  (* FJ：拒收 *)
```

第 3 行又是 Reit：¬¬α 在一级框，二级框里要用它必须先搬进来。把第 3
行删掉、第 4 行直接写 `IEf 1 2`，`fitchOK` 立刻变 `false`——检查器
抓错的部分（第七节）专门演示这个现场。

**∨E 的双并列框**：α∨β ⊢ β∨α。析取消去要**两个并列的同级框**，分
别假设两个析取支、各推出同一结论：

```coq
Definition exComm : fitch :=
  [ mkfl 0 (forr p0 p1) Pre
  ; mkfl 1 p0 Hyp                       (* 框 1：假设 α *)
  ; mkfl 1 (forr p1 p0) (OI2 2)
  ; mkfl 1 p1 Hyp                       (* 框 2：假设 β（并列！） *)
  ; mkfl 1 (forr p1 p0) (OI1 4)
  ; mkfl 0 (forr p1 p0) (OE 1 2 3 4 5) ].
```

`OE 1 2 3 4 5` 的检查条件里有一条 `Nat.eqb (S b) c`（第 3 行的下一行
恰是第 4 行）——两个子框必须**紧挨着**，中间不许插别的行。这是书
「随后两个并列同级子证明」的机器化。

**级联 Reit**：书 p27 的四级证明 ⊢ (α→β)→((β→γ)→(α→γ))。α→β 在
一级框，要用在三级框深处，必须经二级框中转搬运——Reit 每次只上一
级：

```coq
Definition exSyll : fitch := [ (* 11 行：见 ex3_fitch.v *) ].
Example exSyll_ok : fitchOK 0 exSyll = true.
```

十一步链里第 3 行把 α→β 搬进二级框、第 5 行再搬进三级框、第 7 行把
β→γ 直接搬进三级框（它就在二级）。严格的「恰上一级」纪律让每一步
搬运都有据可查——书上的原始十步推导允许更宽的引用，我们的机器版把
纪律收紧到定义 2.1 的字面，多出的行正是**作用域纪律本身的代价与证
据**。

## 四、经典加成 ¬E：FK 与 FJ 的分隔线

FK 的招牌推导是排中律。假设 ¬(p∨¬p)：先假设 p，立即与它冲突得 ⊥，
→I 出框得 ¬p，于是 p∨¬p 又与总假设冲突——¬E 归谬收场：

```coq
Definition exLem : fitch := [ (* 9 行，见 ex3_fitch.v *) ].
Example exLem_fk : fitchOK 1 exLem = true.
Example exLem_fj_rejects : fitchOK 0 exLem = false.
```

同一推导 FK 收、FJ 拒——差别只在第 9 行的 `NEf`（¬E）。**FJ 里没有
排中律**不是猜想而是定理，机器面用 Kripke 反例坐实（两点链 0R1、
V(p)={1}，与 16 章的语义装置同构）：

```coq
Example lem_false_at_0 : kforce 0 (forr p0 (fneg p0)) = false.
Example dne_lem_both :
  forallb (fun w => kforce w (fneg (fneg (forr p0 (fneg p0))))) [0;1] = true.
```

p∨¬p 在 0 点不真（p 不真、¬p 也不真——p 在 0 点「既不真也不假」，
第 14 章 16 章的直觉主义第三值在此现形）；但它的**双重否定**两点皆
真。这正是 13 章 Glivenko 现象的费奇侧影子：经典定理的双重否定化总
是直觉主义可证的——77 章将给出这条定理的纯句法证明（嵌入定理），
此处先埋下语义侧的证据。

## 五、费奇 ↔ 根岑：同一演算的两件外衣

把本章的 FJ/FK 规则表与 04 章的 NJ/NK 并排，逐条对上：Hyp=临时假设
的引入，→I 的框=撤销标记 `[α]¹`，Reit 的级别纪律=推导树中「假设只
在其子树内可用」。差别只在书写方向：费奇式**自上而下**按行推进（贴
近人），根岑式**自下而上**按规则生长（贴近机器检查与搜索——77 章
的证明搜索程序吃的就是树形）。书 2.2 节的根岑式系统 NJ 定义推导为
「公式组成的有穷树」、撤销用上标编号管理，其检查器的全部要点本章
已经备齐：**行数据↔树节点，级别↔深度，作用域可达性↔假设的可用范
围**。

Prolog 通道把整套检查器按行号引用原样实现（`ex3_fitch.pl`）：推导
存为 `line(推导名, 行号, 级别, 公式, 依据)` 事实，`fitch_ok/2` 逐行
核对，`report/3` 输出十组对账：

```text
exIntro kc=1: ok (expected ok) PASS
exDNE kc=0: bad (expected bad) PASS     ← FJ 拒收 ¬E 推导
exLem  kc=1: ok (expected ok) PASS
badCross kc=1: bad (expected bad) PASS  ← 跨级引用被抓
END ====
```

十组全 PASS，含两个「拒收」方向——检查器不仅能验证好推导，还能**证
伪坏推导**：`badCross` 里二级框的行直接 →E 引用一级框的蕴涵（漏
Reit），三通道一致拒绝；补上中转行（`goodCross`）即通过。这是「检
查器作为规范」的完整含义：规则定义里每一句中文，都对应机器里一条
会真的拒绝坏输入的判定。

## 小结

费奇式给了自然演绎第一种可机读的书写纪律：行号让依据可查，级别让
假设的作用域成为语法对象，Reit 的「恰上一级」让跨层引用必须显式搬
运。FJ 与 FK 只隔一条 ¬E——这条线同时是直觉主义/经典逻辑的分界，
两边都有机器证据（FK 的九行 LEM 推导、FJ 侧的两点 Kripke 反例）。
下一章换树形记法重讲同一套演算，并兑现它的第一个结构定理：正规化
（15 章）。

---

上一章：[02 propsem](docs/02-propsem.md) · 下一章：[04 njp](docs/04-njp.md)
