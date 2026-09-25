# 06 路径代数 —— 群胚律与移项术

> 对应示例：`examples/06_path_algebra.v`（编译验证通过）

路径构成一个**群胚**（groupoid）：`1` 是单位元，`@` 是乘法，`^` 是取逆。
但注意，结合律**不是定义上相等**，而是一条路径。这一章把这套代数用熟。

## 6.1 一维：路径构成一个群胚

```coq
Check concat_p1.          (* p @ 1 = p *)
Check concat_1p.          (* 1 @ p = p *)
Check concat_p_pp.        (* p @ (q @ r) = (p @ q) @ r *)
Check concat_pp_p.        (* (p @ q) @ r = p @ (q @ r) *)
Check concat_pV.          (* p @ p^ = 1 *)
Check concat_Vp.          (* p^ @ p = 1 *)
Check inv_pp.             (* (p @ q)^ = q^ @ p^ *)
Check inv_V.              (* (p^)^ = p *)
```

```text
concat_p_pp
     : forall (p : ?x = ?y) (q : ?y = ?z) (r : ?z = ?t),
       p @ (q @ r) = (p @ q) @ r
where
?A : [ |- Type]
?x : [ |- ?A]
?y : [ |- ?A]
?z : [ |- ?A]
?t : [ |- ?A]
concat_pV
     : forall p : ?x = ?y, p @ p^ = 1
where
?A : [ |- Type]
?x : [ |- ?A]
?y : [ |- ?A]
```

库里同时提供正反两种命名（`concat_p_pp` 与 `concat_pp_p`），
记不住方向就用 `lhs` / `rhs` 显式改写（见 6.5）。

## 6.2 二维：路径之间的路径

`concat2` 把两条 2-路径"横向"并置：

```coq
Check concat2.
```

```text
concat2
     : ?p = ?p' -> ?q = ?q' -> ?p @ ?q = ?p' @ ?q'
where
?A : [ |- Type]
?x : [ |- ?A]
?y : [ |- ?A]
?z : [ |- ?A]
?p : [ |- ?x = ?y]
?p' : [ |- ?x = ?y]
?q : [ |- ?y = ?z]
?q' : [ |- ?y = ?z]
```

`whiskerL` / `whiskerR` 在 2-路径的一侧补上一条 1-路径：

```coq
Check whiskerL.
Check whiskerR.
```

```text
whiskerL
     : forall (p : ?x = ?y) (q r : ?y = ?z), q = r -> p @ q = p @ r
where
?A : [ |- Type]
?x : [ |- ?A]
?y : [ |- ?A]
?z : [ |- ?A]
whiskerR
     : ?p = ?q -> forall r : ?y = ?z, ?p @ r = ?q @ r
where
?A : [ |- Type]
?x : [ |- ?A]
?y : [ |- ?A]
?z : [ |- ?A]
?p : [ |- ?x = ?y]
?q : [ |- ?x = ?y]
```

它们各自的运算律：

```coq
Check whiskerL_pp.
Check whiskerR_pp.
Check whiskerL_1p.
Check whiskerR_p1.
```

`ap` 也能作用在 2-路径上（它就是 `ap (ap f)`）：

```coq
Check (fun (A B : Type) (f : A -> B) (x y : A) (p q : x = y) => ap (ap f)).
```

## 6.3 Eckmann–Hilton：二阶环路必交换

```coq
Check eckmann_hilton.
```

```text
eckmann_hilton
     : forall p q : 1 = 1, p @ q = q @ p
where
?A : [ |- Type]
?x : [ |- ?A]
```

这个结论在 HoTT 里格外重要：它说明"环路空间的环路空间"永远是交换的，
所以基本群（1-维）之上才有交换的 π₂、π₃……

## 6.4 移项术：`moveR` / `moveL`

证明形状为 `p @ q = r` 的等式时，手工做 `concat` / `inverse` 的组合很痛苦。
库里提供了成套的"移项"引理：

```coq
Check moveR_Mp.   (* p = r^ @ q -> r @ p = q *)
Check moveR_pM.   (* r = q @ p^ -> r @ p = q *)
Check moveR_Vp.   (* p = r @ q  -> r^ @ p = q *)
Check moveR_pV.   (* r = q @ p  -> r @ p^ = q *)
Check moveL_Mp.   (* r^ @ q = p -> q = r @ p *)
Check moveL_pM.   (* q @ p^ = r -> q = r @ p *)
Check moveL_Vp.   (* r @ q = p -> q = r^ @ p *)
Check moveL_pV.   (* q @ p = r -> q = r @ p^ *)
Check moveL_1M.   (* p @ q^ = 1 -> p = q *)
Check moveR_1M.   (* 1 = q @ p^ -> p = q *)
```

```text
moveR_Mp
     : forall (p : ?x = ?z) (q : ?y = ?z) (r : ?y = ?x),
       p = r^ @ q -> r @ p = q
where
?A : [ |- Type]
?x : [ |- ?A]
?y : [ |- ?A]
?z : [ |- ?A]
```

**命名规则**：`M` 表示移项后带 `^`（minus），`V` 表示被移的那条原本是 `^`，
`p` / `1` 表示等式里出现的是路径还是单位元。

### 一个手工例子

证明 `p^ @ (p @ q) = q`，用路径归纳一步就好：

```coq
Definition cancel_p_left {A : Type} {x y z : A} (p : x = y) (q : y = z)
  : p^ @ (p @ q) = q.
Proof.
  destruct p; destruct q; reflexivity.
Defined.
```

```text
cancel_p_left
     : forall (p : ?x = ?y) (q : ?y = ?z), p^ @ (p @ q) = q
where
?A : [ |- Type]
?x : [ |- ?A]
?y : [ |- ?A]
?z : [ |- ?A]
```

库里对应的引理叫 `concat_V_pp`：

```coq
Check concat_V_pp.
```

```text
concat_V_pp
     : forall (p : ?x = ?y) (q : ?y = ?z), p^ @ (p @ q) = q
where
?A : [ |- Type]
?x : [ |- ?A]
?y : [ |- ?A]
?z : [ |- ?A]
```

> 注意这里不能写 `destruct p; simpl; apply concat_1p`——
> `destruct` 后目标是 `q = 1 @ q` 之类，`apply concat_1p` 会报
> `Unable to unify "q" with "1 @ q"`。要么一次 `destruct` 完，
> 要么显式给参数（`apply (concat_1p q)`）。

## 6.5 `lhs` / `rhs`：把改写锁定在等式的一侧

目标 `a = c` 时，`lhs napply e` 会把左边 `a` 改成 `e` 的左端，
把目标变成 `e 的右端 = c`。这是 HoTT 库里到处可见的写法。

```coq
Definition demo_lhs {A : Type} {x y : A} (p : x = y) : 1 @ p = p.
Proof.
  lhs napply (concat_1p p).   (* 把左边 [1 @ p] 重写成 [p]，目标变成 [p = p] *)
  reflexivity.
Defined.

Definition demo_rhs {A : Type} {x y : A} (p : x = y) : p = 1 @ p.
Proof.
  rhs napply (concat_1p p).
  reflexivity.
Defined.
```

```text
demo_lhs
     : forall p : ?x = ?y, 1 @ p = p
where
?A : [ |- Type]
?x : [ |- ?A]
?y : [ |- ?A]
demo_rhs
     : forall p : ?x = ?y, p = 1 @ p
where
?A : [ |- Type]
?x : [ |- ?A]
?y : [ |- ?A]
```

> **`lhs napply e` 里的 `e` 必须给全参数**：写 `lhs napply concat_1p`
> 会报 `Unable to unify "q" with "1 @ q"`（参数没定下来）。

## 6.6 一个完整的小证明：逆的唯一性

```coq
Definition inverse_unique {A : Type} {x y : A} (p : x = y) (q : y = x)
  (h : p @ q = 1) : q = p^.
Proof.
  destruct p; simpl in *.
  (* 此时目标 [q = 1]，而 [h : 1 @ q = 1]，
     先用 [concat_1p q : 1 @ q = q] 的逆把左边换成 [q]：*)
  exact ((concat_1p q)^ @ h).
Defined.
```

```text
inverse_unique
     : forall (p : ?x = ?y) (q : ?y = ?x), p @ q = 1 -> q = p^
where
?A : [ |- Type]
?x : [ |- ?A]
?y : [ |- ?A]
```

拆解这一步：`destruct p` 后目标是 `q = 1`，假设 `h : 1 @ q = 1`。
`concat_1p q : 1 @ q = q`，取逆得 `(concat_1p q)^ : q = 1 @ q`。
于是 `(concat_1p q)^ @ h : q = 1`——正是目标。

> 常见错误：写 `exact (h^)`。它的类型是 `1 = 1 @ q`，
> 而目标是 `q = 1`，会报类型不符。

库里现成的等价思路是 `moveL_pV` 与 `moveR_M1` 的组合：

```coq
Check moveR_M1.   (* 1 = p^ @ q -> p = q *)
Check moveL_M1.   (* q^ @ p = 1 -> p = q *)
```

## 本章坑位清单

1. **结合律不是定义上相等**：`p @ (q @ r)` 与 `(p @ q) @ r` 之间
   需要 `concat_p_pp` / `concat_pp_p` 这条路径。
2. **`@` 不是左结合的**：连写三个 `@` 会触发 `[level-tolerance]` 警告，
   而警告打在 stderr 上会让验证失败。显式加括号。
3. **`lhs napply e` 必须给全参数**：`lhs napply concat_1p` 报
   `Unable to unify`，要写 `lhs napply (concat_1p p)`。
4. **`destruct p` 后别急着 `apply`**：目标可能被化简成别的形式，
   要么一次 `destruct` 完，要么先看清楚目标。
5. **`exact (h^)` 常常方向不对**：先算清 `(concat_1p q)^ @ h` 这类组合的类型。
6. **`moveR` / `moveL` 共 8 条基本款 + 4 条含单位元款**，
   名字由 M / V / p / 1 四个部件拼成，记不住就 `Check`。
7. **`eckmann_hilton` 说的是二阶环路交换**，
   不要拿它去证一阶的东西（一阶环路一般不交换，比如圆）。
8. **`whiskerL` / `whiskerR` 的参数顺序不同**：
   `whiskerL p (r @ s)` 与 `whiskerR (r @ s) q`。
9. **`concat2` 是"横向并置"，2-路径的"纵向"复合就是普通 `@`**，
   两者别混。
10. **`simpl in *` 在 `destruct` 之后很常用**：
    它会把 `1 @ q` 之类化简，但不会动 `transport`。
11. **`cancel_p_left` 这个引理库里叫 `concat_V_pp`**，
    自己写一遍是理解路径归纳的好练习。
12. **`inv_VV` 而不是两次 `inv_pp`**：`(p^ @ q^)^ = q @ p`。

---

**上一章**：[05 Transport](docs/05-transport.md)
**下一章**：[07 等价 —— `A <~> B`](docs/07-equivalences.md)
