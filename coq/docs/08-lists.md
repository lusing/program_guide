# 08 · 列表

对应示例：`../examples/08_lists.v`

### 8.1 list 的真身：和 nat 同一个设计

```coq
Print list.
(* Inductive list (A : Type) : Type :=
     nil : list A | cons : A -> list A -> list A. *)
```

`list A` 是**参数化归纳类型**：装什么由 A 决定；它恰好两个构造子——`nil`（空表）和 `cons`（头接尾）。和 nat 的 `O`/`S` 一一对应：nat 是「一维的链」，list 是「每个结点还带一个 A 值的链」。这个同构不是巧合——凡「归纳」结构（链、树）都长这样，第 12 章的归纳证明对它们一视同仁。

书写用记号（**必须** `Import ListNotations`，见坑 1）：

```coq
Check (1 :: 2 :: nil).        (* [1; 2] : list nat *)
```

`[1; 2; 3]` 是 `cons 1 (cons 2 (cons 3 nil))` 的糖。打印时 Coq 也用记号显示。

### 8.2 标准库常用操作

全部实测：

| 操作 | 例子 | 结果 |
|---|---|---|
| 长度 | `length [1;2;3]` | `3` |
| 拼接 | `[1;2] ++ [3;4]` | `[1;2;3;4]` |
| 反转 | `rev [1;2;3]` | `[3;2;1]` |
| 拍平 | `concat [[1;2];[3]]` | `[1;2;3]` |
| 区间 | `seq 0 5` | `[0;1;2;3;4]` |
| 映射 | `map (fun n => n*2) [1;2;3]` | `[2;4;6]` |
| 过滤 | `filter (fun n => Nat.eqb (n mod 2) 0) [1;2;3;4]` | `[2;4]` |
| 取第 n 个 | `nth 1 [10;20;30] 0` | `20` |
| 求和 | `fold_right Nat.add 0 [1;2;3;4]` | `10` |

`nth` 的第三个参数是**越界默认值**：

```coq
Compute (nth 5 [10; 20; 30] 0).   (* = 0 —— 越界，静默返回默认值 *)
```

不崩溃，但也不报警——和 `5 / 0 = 0` 一个家族的坑（第 5 章）。要「显式失败」的语义，用返回 option 的版本（`nth_error`，第 17 章）。

### 8.3 自己写一遍：结构递归

理解列表操作最好的方式是亲手写。长度与拼接：

```coq
Fixpoint my_length {A : Type} (xs : list A) : nat :=
  match xs with
  | [] => 0
  | _ :: tl => S (my_length tl)      (* 一层剥掉一个头，长度加一 *)
  end.

Fixpoint my_append {A : Type} (xs ys : list A) : list A :=
  match xs with
  | [] => ys                         (* 空表拼任何表 = 那个表 *)
  | h :: tl => h :: my_append tl ys  (* 头保住，尾继续拼 *)
  end.

Example my_append_ex : my_append [1; 2] [3; 4] = [1; 2; 3; 4].
Proof. reflexivity. Qed.
```

注意两个函数的共同形状：**match 第一个参数、在 `tl`（严格子项）上递归、nil 给基础情形**——这就是第 10 章讲的「结构递归」，也是第 12 章归纳证明能对它们工作的原因。`{A : Type}` 隐式参数让它们天然多态（`my_length [true]` 照样工作）。

`safe_head` 展示了「拿不到值就明说」的建模：

```coq
Definition safe_head {A : Type} (xs : list A) : option A :=
  match xs with
  | [] => None
  | h :: _ => Some h
  end.
```

为什么不用 `nth xs 0 默认值`？因为**默认值会撒谎**（空表和「头恰好是默认值」无法区分）。option 是第 17 章的主题。

### 8.4 fold：方向与参数顺序（两个大坑，实测）

折叠（fold/reduce）是列表操作的「归一化」：一切「遍历列表攒一个结果」都能写成 fold。标准库给了两个方向：

```coq
(* fold_right f 初值 列表：从右往左叠 *)
Compute (fold_right Nat.add 0 [1; 2; 3; 4]).   (* = 10 *)
(* 展开形状：f 1 (f 2 (f 3 (f 4 初值))) *)

(* fold_left f 列表 初值：从左往右叠 —— 注意列表在前！ *)
Compute (fold_left Nat.add [1; 2; 3; 4] 0).    (* = 10 *)
(* 展开形状：f (f (f (f 初值 1) 2) 3) 4 *)
```

**坑一（参数顺序）**：`fold_right f a0 l` 是「f、初值、列表」，`fold_left f l a0` 是「f、**列表**、初值」——两个 fold 参数顺序不同！把初值放错位置不会报类型错误（fold_left 会把你的初值当列表折叠、把列表当初值返回），只会得到悄悄错误的结果（实测：`fold_left (fun acc x => x :: acc) [] [1;2;3]` 返回 `[1;2;3]`——它折叠的是空表）。

**坑二（方向差异）**：叠法不可交换时，两个 fold 结果不同。用一个「把元素 cons 到结果前」的叠法显形：

```coq
Compute (fold_right (fun x acc => x :: acc) [] [1; 2; 3]).
                                      (* = [1;2;3] *)
Compute (fold_left (fun acc x => x :: acc) [1; 2; 3] []).
                                      (* = [3;2;1] —— 恰好是 rev！ *)
```

注意两个 lambda 的参数顺序也不同（fold_right 是 `元素 续果`，fold_left 是 `积累 元素`）——方向、参数序两套差异要一起记。加法这种交换叠法无所谓；cons、减法、字符串拼接都必须选对方向。

### 8.5 证明预告

列表是第一个「值得证明」的结构。三个经典定律，第 20 章全部证一遍：

```coq
(* app_nil_r  : forall xs, xs ++ [] = xs          （看似显然，需归纳） *)
(* app_assoc  : forall xs ys zs, xs ++ ys ++ zs = (xs ++ ys) ++ zs *)
(* length_app : forall xs ys, length (xs ++ ys) = length xs + length ys *)
```

「显然」在 Coq 里必须变成归纳——而这正是训练的起点。

### 8.6 本章坑位清单（实测）

1. **`[1; 2]` 记号默认不存在**：必须 `From Coq Require Import List.` + `Import ListNotations.`，否则 `[` 直接语法错误。新手第一大坑；
2. **fold_left/fold_right 参数顺序不同**：`fold_left f l a0` vs `fold_right f a0 l`——初值位置互换，放错**不报错**只给错结果；
3. **`nth` 越界静默返回默认值**：默认值会掩盖「列表太短」的事实；要显式失败用 `nth_error`（option 版）；
4. **`++` 是右结合**：`[1] ++ [2] ++ [3]` = `[1] ++ ([2] ++ [3])`——对拼接无感（结合律成立），但换成别的右结合运算时要意识到求值形状；
5. **`::` 只能头插单个元素**：拼整表用 `++`；`x :: [1;2]` 合法而 `xs :: [1;2]`（xs 是表）类型错误。

---
上一章：[07 · 模式匹配](07-patterns.md) ｜ 下一章：[09 · 归纳类型：自定义数据](09-inductive.md) ｜ 返回：[README](../README.md)
