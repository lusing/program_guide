# 第 34 章 图灵机：四元组与纸带

> 对书：Mendelson §5.1（图灵机与计算的定义）、§5.2（图示与书例）。本章通道：
> C（`examples/34_turing/ex34_turing.v`）/
> L（`examples/34_turing/ex34_turing.lean`）/
> P（`examples/34_turing/ex34_turing.pl`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| 四元组解释器 | act/quad/tape/cfg+findq 首匹配+step 单步+run 燃料运行+停机单调性 | C/L/P |
| Tsucc（书例 1） | 后继：q0\|Lq1, q1B\|q2——常数深度**全正确定理** | C/L/P |
| Tzero（书例 2） | 零函数：三四元组——**循环不变式归纳全正确** | C/L/P |
| Tadd | 加法：七元组（隔板改笔+连擦两笔）——5×5 网格对账 | C/L/P |
| Terase（书例 0） | 找首个非空抹除+全空输入**永不停**（书的原文行为） | C/L/P |

33 章的寄存器机把「程序」做成了数学对象；本章给出第二个、也是最著名的模型
——**图灵机**。Mendelson §5.1 的定义极简：程序是**四元组**的集合，纸带描述
是把状态符号嵌进字里的一个字。两个模型的对照（指令密度、状态显式性、停机
语义）是本章的暗线。

## 一、四元组、纸带与停机

书 §5.1 的四元组只有三型：

```
(1) q_j a_i a_k q_r    在当前格写 a_k，转入 q_r
(2) q_j a_i L q_r      左移一格，转入 q_r
(3) q_j a_i R q_r      右移一格，转入 q_r
```

纸带描述是形如 `P q_j a_i Q` 的字——状态符号恰好停在正在扫描的格子左侧。
移动规则五条（写 1 条+左移 2 条+右移 2 条），其中左/右各有一条「带端补空」
条款：到左端还要左移，就在左边接一个空格；右端同理。**停机**的定义干净
得漂亮：当前 (状态, 读符) 对不是任何四元组的开头——没有可执行的指令。

机器版把纸带拆成三段（左表、当前格、右表），带端补空就是表的空分支：

```coq
Inductive act : Type := wr (b : nat) | mL | mR.
Inductive quad : Type := qd (qs rd : nat) (a : act) (qs' : nat).
Record tape : Type := mkt { lft : list nat; cur : nat; rgt : list nat }.
Record cfg  : Type := mkc { st : nat; tp : tape }.

Fixpoint findq (p : list quad) (s a : nat) : option (act * nat) :=
  match p with
  | [] => None
  | qd qs rd ac qs' :: p' =>
      if (Nat.eqb qs s) && (Nat.eqb rd a) then Some (ac, qs')
      else findq p' s a
  end.
```

`step` 是一个模式匹配：无匹配返回 `None`（停机）；写指令原地换当前格；
左移把左表头搬进当前格（左表空则补空格 0），右移对称。`run` 与 33 章 RM
同构但停机判定不同——RM 看 pc 不动，TM 看无匹配：

```coq
Fixpoint run (p : list quad) (c : cfg) (fuel : nat) : option cfg :=
  match fuel with
  | O => None                              (* 燃料尽仍未停（不停机现场） *)
  | S f =>
      match step p c with
      | None => Some c                     (* 停机：返回停机配置 *)
      | Some c' => run p c' f
      end
  end.
```

注意语义约定与 RM 相反：`Some c` 表示**已停机**且 c 是停机配置，`None`
表示燃料耗尽——这正好把「不停机」做成可观测的返回值。配套一条**停机单调
性**引理（多给燃料不改变已停的结果），后面垫预算用：

```coq
Lemma run_mono : forall p c f k c',
  run p c f = Some c' -> run p c (f + k) = Some c'.
```

## 二、一元编码与书例机器

数论函数的计算用一元编码（书 §5.2 约定）：数 k 编成 **k+1** 个笔划
（`k̄ = |^{k+1}`——让 0 也占一格）；数组 (k₁,…,k_n) 编成 `k̄₁ B k̄₂ B … B k̄n`。
机器 `f_{T,n}(k₁,…,k_n)=m` 指：从 q0 位于编码左端出发，停机时纸带内容是
`E₁ m̄ E₂`（两端允许空格、中间不许）。四台现场机器：

```coq
Definition Terase : list quad := [qd 0 0 mR 0; qd 0 1 (wr 0) 1].
Definition Tsucc  : list quad := [qd 0 1 mL 1; qd 1 0 (wr 1) 2].
Definition Tzero  : list quad :=
  [qd 0 1 (wr 0) 1; qd 1 0 mR 0; qd 0 0 (wr 1) 2].
Definition Tadd   : list quad :=
  [qd 0 1 mR 0; qd 0 0 (wr 1) 1; qd 1 1 mR 1; qd 1 0 mL 2; qd 2 1 (wr 0) 3;
   qd 3 0 mL 4; qd 4 1 (wr 0) 5].
```

- **Tsucc**（书例 1：`q0|Lq1, q1B|q2`）：读笔左移（左端自动补空），把
  补来的空格改写成笔——k̄ 变 (k+1)̄。三步内停机，**与 n 无关的常数深度**：

```coq
Theorem tsucc_correct : forall n,
  run Tsucc (start1 n) 4 = Some (mkc 2 (mkt [] 1 (repeat 1 (S n)))).
Proof. intro n. reflexivity. Qed.
```

  整条定理是**定义方程的转换检查**——run 展开三次、findq 命中两次、纸带
  操作全部落在构造子上，reflexivity 一发收。Lean 侧同样 `rfl`（零公理）。

- **Tzero**（书例 2：`q0|Bq1, q1BRq0, q0B|q2`）：抹一笔、右移一笔交替，
  直到 q0 读到空格——把空格改写成笔停机，输出恰一笔（=0 的编码）。这是
  一台**循环机器**，全正确性要归纳：不变式 `Cz k m`（q0 位于某笔上、左侧
  k 个已抹空格、右侧还 m 笔）：

```coq
Definition Cz (k m : nat) : cfg := mkc 0 (mkt (repeat 0 k) 1 (repeat 1 m)).

Lemma tzero_loop : forall m k,
  run Tzero (Cz k m) (2 * m + 4)
  = Some (mkc 2 (mkt (repeat 0 (S (k + m))) 1 [])).
```

  归纳步烧两格燃料：抹一笔（写 0 转 q1）+ 右移（q1 空格右移转 q0），
  恰好回到不变式 `Cz (k+1) m'`；基例烧四格：抹、移到带外、补空、写笔停。
  垫上单调性即得 `tzero_correct`。Lean 侧的坑见章末——符号乘法 `2*m+4`
  在转换检查里剥不动 succ，改用构造子递归的燃料预算 `tfuel` 再桥接。

- **Tadd**（自构七元组，行为同书例 3）：越过第一块笔划，把隔板 B 改写成
  笔（并块），越过余下笔划到带尾，**连擦两笔**停机。这「连擦两笔」是
  网格对账抓出来的：首版只擦一笔——隔板改笔是净**加**一格内容，(m+1)+
  (n+1) 笔并块后是 m+n+3 笔，擦一笔剩 m+n+2，比 (m+n)̄ 多一笔；5×5 网格
  全体多 1，当场爆红。这是「机器对账抓包」的又一现场（前有 09 章 ↓
  定义抄错、55/61 章目标为假）。

```coq
Example tadd_grid :
  map (fun mn => match run Tadd (start2 (fst mn) (snd mn)) 40 with
                 | Some c => outbars c
                 | None => 999
                 end)
      (list_prod (seq 0 5) (seq 0 5))
  = map (fun mn => fst mn + snd mn + 1) (list_prod (seq 0 5) (seq 0 5)).
Proof. reflexivity. Qed.
```

  （全正确性的归纳证明与 tzero 同构——两段循环各带一个不变式——按 33 章
  RM 的 P0 同款口径，此处以网格+解释器定义方程为证词。）

- **Terase**（书例 0 的二元字母表版：`q0BRq0, q0|Bq1`）：一路右移找首个
  非空符号，抹掉停机；**全空输入永不停**——书的原文「keeps on moving
  right forever」正好是 `run` 返回 `None` 的现场：

```coq
Example terase_nohalt : run Terase (mkc 0 (mkt [] 0 [])) 50 = None.
Proof. reflexivity. Qed.
```

## 三、与寄存器机的对照

| 维度 | RM（33 章） | TM（本章） |
|---|---|---|
| 状态 | 隐式（pc=指令标号） | 显式 q₀,q₁,…（同一指令可多处复用） |
| 数据面 | 有限个寄存器存字 | 一条纸带+一个读写头 |
| 停机 | HALT 指令（pc 不动） | 无匹配四元组（缺指令即停） |
| 带端/边界 | 寄存器无界 | 带端自动补空格（§5.1 移动规则 2/5 条款） |
| 解释器形态 | step 查标号+run 燃料 | findq 首匹配+step/run 燃料——同构 |
| 一元退化 | word=nat（截断减法） | 纸带分三段表（重复算术在 repeat 上） |

两个模型的可计算函数类相同（§5.3 的等价链，接 35 章「部分递归」第三化身）。
书的路线在 §5.1 末给出 Alg_T 的定义（算法=机器+编码约定），停机问题、
通用机的文档线在此埋钩——37 章的 Church 不可判定从这台机器出发。

## 四、Prolog 搜索面

P 通道与 C/L 同构：`tstep(P, cfg(S,L,C,R), Cfg2)` 首匹配四元组
（`member`+割实现「首匹配」纪律），`apply1/6` 三型动作，`trun/4` 燃料
运行。main 输出四机对账表（Tsucc/Tzero/Terase 各 0..9、Tadd 5×5 网格）
加全空输入的不停机行——与 C/L 逐行一致。变量名无撇号（32 轮 Cfg' 教训），
输出纯 ASCII 带 `END ====` 标记。

## 坑位速记（本章实测）

- **Tadd 首版只擦一笔**：隔板改笔净加一格，5×5 网格全体多 1 被抓——
  改笔+连擦两笔才得 (m+n)̄。写机器前先算格子账：输入 (m+1)+1+(n+1) 格，
  目标 m+n+1 笔。
- **书例 2 的四元组是 q1 B R q0**（空格右移）不是 q1 | R q0——提取乱序
  时按行为反推：抹一笔后头部停在空格上，右移的触发条件必然是 B。
- **Lean 转换剥不动符号乘法**：`2*m+4` 形态的燃料在 `exact`/`rfl` 的
  转换检查里无法归约出 succ 剥层——改构造子递归 `tfuel |0=>4 |m+1=>succ succ`
  再用 `tfuel_eq`+omega 桥接（Coq 侧 simpl+replace by lia 无此问题）。
- **run_mono 的 IH 要广义化 c**：引入 c 后再做归纳，IH 只对同一配置成立；
  `revert c` 后 IH 才能吃 step 产生的新配置。
- **Coq `unfold step at 1 2` 时机**：simpl 已把 step 展开再 unfold 报
  Invalid occurrence——用 `simpl + exact`（靠转换检查）替代逐层 unfold。
- **Lean 记录字段不是列表**：`cnt1 c.tp.cur` 类型错误——cur 是 Nat，
  计数用 `if c.tp.cur == 1 then 1 else 0`；结构相等判定改 `.isNone = true`
  （Option Cfg 的 Decidable 实例合成失败，Bool 口径绕行）。
- 账本：Coq 全章零公理；Lean `tsucc_correct` 零公理、`tzero_correct`
  [propext, Quot.sound]（simp 引入）——与 09 章同款 tactic 层差异。

## 小结

图灵机用最少的活动部件（四元组×三型+一条纸带）定义了「算法」：停机不是
指令而是**缺指令**，带界不是检查而是**补空格**。四台书例机器里，后继是
定义方程的转换检查、零函数是循环不变式的归纳现场、加法是网格对账抓包后
的修正、抹除机给出永不停机的实证。下一章把这个「程序=数据」的视角转向
**语法模型**——原始递归函数与 μ-递归，第三台可计算性机器。

---

上一章：[33 寄存器机与可计算性](docs/33-regmachine.md) · 下一章：[35 递归函数与部分递归](docs/35-recfn.md)
