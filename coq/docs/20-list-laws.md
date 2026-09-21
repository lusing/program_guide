# 20 · 列表定律证明实战

对应示例：`../examples/20_list_laws.v`

### 20.1 本章任务

列表是函数式编程的「数组」，它的定律就是日常重构的理论基础。六条（示例 20 全部证毕）：

| # | 定律 | 日常意义 |
|---|---|---|
| 1 | `xs ++ [] = xs`（右单位元） | 拼空表不变 |
| 2 | `xs ++ ys ++ zs = (xs ++ ys) ++ zs`（结合律） | 括号随便挪 |
| 3 | `length (xs ++ ys) = length xs + length ys` | 长度可加 |
| 4 | `map g (map f xs) = map (fun x => g (f x)) xs`（融合律） | 两遍合一遍 |
| 5 | `rev (xs ++ ys) = rev ys ++ rev xs` | 反转分配且换序 |
| 6 | `rev (rev xs) = xs`（对合） | 翻两次还原 |

通用剧本（第 16 章已总结）：`induction xs as [| x tl IH]` → 基例 `reflexivity` → 步例 `simpl. rewrite IH. reflexivity.`。六条里四条是这个剧本的填空，两条有新戏——正好讲两个新课题。

### 20.2 课题一：定律互相引用（1、5、6）

**定律 1（右单位元）**是第 12 章 `my_app_nil_r` 的标准库版（用 `++` 记号）。留意与「左单位元」的对比：`[] ++ ys = ys` 是 `reflexivity` 一行（`++` 在左参数上递归，左边是 `[]` 直接化简），右边版本却要完整归纳——**定义的形状决定证明的价格**（第 12.5 节的法则再次兑现）。

**定律 5（反转分配）**开始引用前面的定律：

```coq
Theorem rev_app_distr : forall (A : Type) (xs ys : list A),
  rev (xs ++ ys) = rev ys ++ rev xs.
Proof.
  intros A xs ys. induction xs as [| x tl IH].
  - simpl. rewrite app_nil_r. reflexivity.
  - simpl. rewrite IH. rewrite <- app_assoc. reflexivity.
Qed.
```

两个新情况：**基例**化简后是 `rev ys ++ [] = rev ys`——又是那个「动不了的右单位元」，把刚证的定律 1 当引理用（`rewrite app_nil_r`）；**步例**要把 `(rev ys ++ rev tl) ++ [x]` 与 `rev ys ++ (rev tl ++ [x])` 对齐——`rewrite <- app_assoc` 反向用结合律挪括号。**定理开始互相组装成网**：定律 1 服务定律 5，定律 5 服务定律 6：

```coq
Theorem rev_involutive : forall (A : Type) (xs : list A),
  rev (rev xs) = xs.
Proof.
  intros A xs. induction xs as [| x tl IH].
  - reflexivity.
  - simpl. rewrite rev_app_distr. rewrite IH. simpl. reflexivity.
Qed.
```

「翻两次等于不翻」——口头上一秒钟，机器面前需要定律 5 + 归纳 + 化简三件套。这就是证明工程的手感：**没有孤立的定理，只有定理网**。

### 20.3 课题二：归纳假设不够用怎么办

一个值得亲手的失败（推荐在 CoqIDE 里试）：证**累加器版反转**（第 10 章 `fast_rev`）与标准 `rev` 的一致性。naive 剧本直接上：

```coq
(* 想证：rev_acc [] xs = rev xs *)
Proof.
  intros A xs. induction xs as [| x tl IH].
  - reflexivity.                  (* 两侧都空，过了 *)
  - simpl. rewrite IH.            (* 卡死！ *)
```

步例化简后是 `rev_acc (x :: []) tl = rev tl ++ [x]`——**累加器不再是 []**，而 IH 只谈 `rev_acc [] tl`，假设够不着。这正是第 15 章 two_step 的同款困境，同款解法——**一般化：把命题改成对任意累加器成立**（注意 intros 顺序的细节）：

```coq
Lemma rev_acc_correct : forall (A : Type) (xs acc : list A),
  rev_acc acc xs = rev xs ++ acc.
```

**加强后的命题反而好证**：IH 变成「对任意 acc」，步例的累加器 `x :: acc` 也是它的实例。而 `rev_acc [] xs = rev xs` 作为推论一击而得。这一招（**generalize the accumulator**）与第 15 章（strengthen with conjunction）是同一个思想的两件衣服：**归纳假设是白送的燃料，命题写得越「一般」，燃料越足**。

### 20.4 一个证明细节的工具箱

本章六条定律的证明里，三个高频动作值得点名：

1. **借定律**：基例/步例化简出的「标准形状」（`xs ++ []`、括号位置）直接 rewrite 前面证好的定律，别再手证一遍；
2. **调方向**：`rewrite <- app_assoc` 挪括号——先想清楚要消的模式在哪侧（第 13.1 节的方向学）；
3. **看形状选归纳变量**：定律 3、4 对 xs 归纳剧本即过；涉及两个列表的定律（如 `length (xs ++ ys) = ...`）也只对第一个归纳——因为 `++` 在它上面递归。

### 20.5 rev_acc_correct 完整证明（实测）

失败与成功的差别只在**一个 intros 的顺序**（失败版的报错与本节脚本都经过实测）：

```coq
Lemma rev_acc_correct : forall (A : Type) (xs acc : list A),
  rev_acc acc xs = rev xs ++ acc.
Proof.
  intros A xs.            (* 关键：只收 A 和 xs —— acc 留在目标里！
                             若先 intros acc 再 induction，IH 就被
                             锁死在固定 acc 上，步例 rewrite IH 直接
                             报 Found no subterm matching *)
  induction xs as [| x tl IH]; intros acc.
  - reflexivity.
  - simpl. rewrite IH. rewrite <- app_assoc. simpl. reflexivity.
Qed.
```

步例目标：`rev_acc (x :: acc) tl = (rev tl ++ [x]) ++ acc`。`rewrite IH`（IH : **forall acc**, rev_acc acc tl = rev tl ++ acc）把左边换成 `rev tl ++ x :: acc`；`rewrite <- app_assoc` 把右边括号外挪变成 `rev tl ++ [x] ++ acc`；`simpl` 把 `[x] ++ acc` 化成 `x :: acc`，两边相同。推论随之而来：

```coq
Theorem fast_rev_correct : forall (A : Type) (xs : list A),
  rev_acc [] xs = rev xs.
Proof.
  intros A xs. rewrite rev_acc_correct. rewrite app_nil_r. reflexivity.
Qed.
```

**没有那步「一般化」，这一切无从谈起**——本教程第二次、也是最后一次强调这个心法。

### 20.6 本章坑位清单（实测）

1. **累加器命题没一般化**：`rev_acc [] xs` 直接归纳 IH 够不着，改成 `forall acc, rev_acc acc xs = rev xs ++ acc`（20.3 的完整案例）；
2. **`rev (x :: tl) ++ acc` 化简时机**：stdlib `rev` 定义为 `rev (x::l) = rev l ++ [x]`，simpl 展开后形状才可见——步例先 simpl 再 rewrite 的顺序不能乱；
3. **rewrite 定律时同名混淆**：自己证的 `app_nil_r` 与 stdlib 的 `List.app_nil_r` 同名——自己的在后会遮蔽库版（本教程自证的版本足够用，两版陈述一致，实测无冲突）；
4. **想对 ys 归纳**：定律 3 对 `ys` 归纳会把化简引向 `length xs` 的死胡同——归纳变量跟着**递归定义的参数**走（`++` 递归在第一个参数）。

---
上一章：[19 · 表达式求值器：AST 入门](19-ast.md) ｜ 下一章：[21 · 插入排序与正确性证明](21-sorting.md) ｜ 返回：[README](../README.md)
