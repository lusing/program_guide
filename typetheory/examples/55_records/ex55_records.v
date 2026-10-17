(* ============================================================
   49 依赖记录与模块 —— Coq（罗朝晖书 2.5.3 节 3 + 5.2.3）
   依赖记录类型：带标签的多元组（选择 r.l、限制 [r⁻]、
   图 2.3 规则）；栈/数组的 Σ-记录规范与**细化映射**
   ρ : Str[Array] → Str[Stack]（书图 5.4），定理 array_impl_stack
   ——书中 Admitted，此处给完整机器证明。
   注意：栈的等同标准 SEq 是书式的**弱等同**：
     s ≈ s' ⟺ ptr 相等 ∧ 指针以下的存储相等
   （若用 Leibniz 相等，pop∘push = id 是**假**的——assign
   恰在指针处改写了数组；这正是「模块规范 = 结构类型 +
   等同标准」的教学点。）
   ============================================================ *)

Require Import Lia Arith.

(* ---- 记录类型的最小面：标签、选择、限制 -------------------
   书 2.5.3：R ::= () | (R, l:A)；r ::= <> | (r, l = a:A)。
   运算：选择 r.l；限制 [r⁻]（去掉最后一个字段）。
   Coq 的 Record 即Σ-记录的语法糖——字段名 = 带标签的投影。 *)
Record LPoint := mkLPoint { px :> nat ; py : nat ; plabel : nat }.
Definition p0 := mkLPoint 3 4 42.
Compute (px p0).              (* 选择运算 r.l → 3 *)
Compute (plabel p0).          (* → 42 *)
(* 限制运算 [r⁻]：剥掉最后一个字段——Coq 无原生语法，重组 *)
Definition strip (p : LPoint) : nat * nat := (px p, py p).
Compute (strip p0).           (* → (3, 4) *)
(* 不同标签 ⟹ 不同类型：标签绑定在类型上（书：l ≠ l' 则类型不等）*)
Record TagA := mkTagA { ta : nat }.
Record TagB := mkTagB { tb : nat }.
Definition demoA (x : TagA) : nat := ta x.
Fail Definition demoB (x : TagA) : nat := tb x.   (* 标签不互通 *)

(* ============================================================
   模块化开发（书 5.2.3 例 5.1）：
   规范 = (结构类型 Str[·]（依赖记录），性质谓词 φ[·])
   细化：ρ : Str[Array] → Str[Stack]，证 φ[Array](A) ⟹ φ[Stack](ρ A)
   ============================================================ *)

(* ---- 数组的规范（书 Str[Array] + φ[Array]）---------------- *)
Record StrArray := mkStrArray
  { Array : Type;
    newarray : Array;
    assign  : nat -> Array -> nat -> Array;    (* A[i] := n *)
    access  : Array -> nat -> nat
  }.

Definition phiArray (A : StrArray) : Prop :=
  (* 新数组全零 *)
  (forall i : nat, access A (newarray A) i = 0)
  (* 赋值律：写进的位置读到新值；别的位置不变 *)
  /\ (forall i j n : nat, forall a : Array A,
      (i = j -> access A (assign A n a i) j = n)
      /\ (i <> j -> access A (assign A n a i) j = access A a j)).

(* ---- 栈的规范（书 Str[Stack] + φ[Stack]）----------------- *)
Record StrStack := mkStrStack
  { Stack : Type;
    SEq    : Stack -> Stack -> Prop;          (* 栈的等同标准 *)
    empty  : Stack;
    push   : nat -> Stack -> Stack;
    pop    : Stack -> Stack;
    top    : Stack -> nat
  }.

Definition phiStack (S : StrStack) : Prop :=
  (* top(push n s) = n *)
  (forall n : nat, forall s : Stack S, top S (push S n s) = n)
  (* pop(push n s) ≈ s *)
  /\ (forall n : nat, forall s : Stack S, SEq S (pop S (push S n s)) s)
  (* top(empty) = 0 *)
  /\ (top S (empty S) = 0)
  (* pop(empty) ≈ empty *)
  /\ (SEq S (pop S (empty S)) (empty S)).

(* ---- 细化映射 ρ（书图 5.4）-------------------------------
   每个栈 = 数组 arr + 指针 ptr 的序对：
     SEq    s s'  = ptr 相等 ∧ ∀i < ptr. 两数组 access 相等
     empty        = (newarray, 0)
     push n s     = (assign n arr ptr, ptr + 1)
     pop s        = (arr s, ptr - 1)          （nat 截断减）
     top s        = match ptr with 0 => 0 | S k => access arr k *)
Definition rho (A : StrArray) : StrStack :=
  mkStrStack (Array A * nat)
    (fun s s' => snd s = snd s'
                 /\ forall i : nat, i < snd s ->
                     access A (fst s) i = access A (fst s') i)
    (newarray A, 0)
    (fun n s => (assign A n (fst s) (snd s), S (snd s)))
    (fun s => (fst s, pred (snd s)))
    (fun s => match snd s with
              | O => 0
              | S k => access A (fst s) k
              end).

(* ---- 主定理：数组实现栈（书中 Admitted）------------------ *)
Theorem array_impl_stack :
  forall A : StrArray, phiArray A -> phiStack (rho A).
Proof.
  intros A [Hnew Hassign].
  unfold phiStack; simpl; split; [| split; [| split]].
  - (* top (push n s) = n：指针走 S 分支，读到写进的新值 *)
    intros n [arr ptr]. simpl.
    assert (Hw : access A (assign A n arr ptr) ptr = n)
      by (apply (proj1 (Hassign ptr ptr n arr)); reflexivity).
    destruct ptr as [| k]; simpl; exact Hw.
  - (* pop (push n s) ≈ s：指针 pred(S ptr) = ptr；
       指针以下 i < ptr ≠ ptr，assign 不动这些位置 *)
    intros n [arr ptr]. simpl. split.
    + f_equal. lia.
    + intros i Hi. destruct (Hassign ptr i n arr) as [_ Hne].
      apply Hne. lia.
  - (* top (empty) = 0：指针 0 走零分支 *)
    reflexivity.
  - (* pop (empty) ≈ empty：pred 0 = 0；i < 0 不可能 *)
    split.
    + reflexivity.
    + intros i Hi. simpl in Hi. lia.
Qed.

(* ---- 细化映射的运行面（书 5.2.3 的「实现侧」）-------------
   取一个具体数组实现，栈的四个操作可以**跑**起来：
   数组 = 函数 nat -> nat；newarray 全零；assign 写一点。 *)
Definition funArray : StrArray :=
  mkStrArray (nat -> nat)
    (fun _ => 0)                                    (* newarray *)
    (fun n a i => fun j => if Nat.eqb j i then n else a j)  (* assign *)
    (fun a i => a i).                               (* access  *)

Lemma funArray_phi : phiArray funArray.
Proof.
  split.
  - intros i. reflexivity.
  - intros i j n a. split.
    + intros Hij. subst j. unfold funArray. simpl.
      rewrite Nat.eqb_refl. reflexivity.
    + intros Hij. unfold funArray. simpl.
      destruct (Nat.eqb_spec j i); [congruence | reflexivity].
Qed.

(* 把细化映射实例化到 funArray 上，栈操作逐条 Compute：
   empty = 全零数组 + 指针 0；push 7 后 top = 7；pop 逐层恢复 *)
Definition theStack := rho funArray.
Definition s0 := empty theStack.
Definition s1 := push theStack 7 s0.
Definition s2 := push theStack 9 s1.
Compute (top theStack s0).    (* = 0 *)
Compute (top theStack s1).    (* = 7 *)
Compute (top theStack s2).    (* = 9 *)
Compute (top theStack (pop theStack s2)).   (* = 7：弹出恢复 *)
Compute (top theStack (pop theStack (pop theStack s2))).  (* = 0 *)
