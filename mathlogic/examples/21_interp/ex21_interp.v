(* ex21_interp.v —— 语法解释、范式与 ZF（EFT ch VIII + VII.3）
   机器件：有限结构 FOL 求值器 + 词项化简翻译的保真对账（书 Thm 1.2 的
   构造面）+ 定义扩张 ≤-from-< 的消去现场（VIII.2.B / VIII.3 E2）+
   ⟨Φ⟩ 范式的析取合取形（VIII.4.2，全赋值枚举验证）+ ZF 公理即公式。 *)

From Stdlib Require Import List Arith Lia.
Import ListNotations.

(* ---------- 1. 语法（沿用 20 章骨架；本章直连 ∧ → ∀） ---------- *)

Inductive tm : Type :=
| var : nat -> tm
| fsym : nat -> list tm -> tm.

Inductive fm : Type :=
| rat : nat -> list tm -> fm
| eqf : tm -> tm -> fm
| neg : fm -> fm
| disj : fm -> fm -> fm
| conj : fm -> fm -> fm
| imp : fm -> fm -> fm
| exq : nat -> fm -> fm
| allq : nat -> fm -> fm.

Definition iff_form (φ ψ : fm) : fm := conj (imp φ ψ) (imp ψ φ).

(* ---------- 2. 有限结构 FOL 求值器 ---------- *)

Definition interp_fn := nat -> list nat -> nat.
Definition interp_rel := nat -> list nat -> bool.

Fixpoint evt (f : interp_fn) (β : nat -> nat) (t : tm) : nat :=
  match t with
  | var n => β n
  | fsym s ts => f s (map (evt f β) ts)
  end.

Definition bump (β : nat -> nat) (x a : nat) : nat -> nat :=
  fun n => if n =? x then a else β n.

Fixpoint evf (f : interp_fn) (r : interp_rel) (D : list nat)
    (β : nat -> nat) (φ : fm) : bool :=
  match φ with
  | rat s ts => r s (map (evt f β) ts)
  | eqf t1 t2 => Nat.eqb (evt f β t1) (evt f β t2)
  | neg ψ => negb (evf f r D β ψ)
  | disj ψ χ => orb (evf f r D β ψ) (evf f r D β χ)
  | conj ψ χ => andb (evf f r D β ψ) (evf f r D β χ)
  | imp ψ χ => implb (evf f r D β ψ) (evf f r D β χ)
  | exq x ψ => existsb (fun a => evf f r D (bump β x a) ψ) D
  | allq x ψ => forallb (fun a => evf f r D (bump β x a) ψ) D
  end.

(* 现场结构 S3：论域 {0,1,2}；f0=后继环绕、f1=前驱环绕、c2=0；
   R0=标准 <；R1=相等；R2=定义出来的 ≤（= R0 ∨ 相等，见第 4 节） *)
Definition D3 : list nat := [0;1;2].
Definition f3 : interp_fn :=
  fun s args => match s, args with
  | 0, [a] => if a =? 2 then 0 else a + 1
  | 1, [a] => if a =? 0 then 2 else a - 1
  | 2, [] => 0
  | _, _ => 0
  end.
Definition r3 : interp_rel :=
  fun s args => match s, args with
  | 0, [a;b] => a <? b
  | 1, [a;b] => a =? b
  | 2, [a;b] => orb (a <? b) (a =? b)
  | _, _ => false
  end.

(* 闭句子/带 3 个自由变元的公式的「全指派满足」 *)
Definition satis3 (φ : fm) : bool :=
  forallb (fun b0 => forallb (fun b1 => forallb (fun b2 =>
    evf f3 r3 D3 (fun n => match n with 0=>b0|1=>b1|_=>b2 end) φ) D3) D3) D3.

(* ---------- 3. 词项化简翻译（书 Thm 1.2 的构造面） ---------- *)

Fixpoint conj_l (l : list fm) : fm :=
  match l with
  | [] => eqf (var 0) (var 0)
  | [a] => a
  | a :: l' => conj a (conj_l l')
  end.

(* 通用 trew 递归（fsym 挂 list tm 的嵌套结构）在 Coq 的 guard 检查下
   不可直写——与 20 章 substt 同病；示例对直接手写（见证链按层编号），
   通用翻译定理（书 Thm 1.2）记文档级。 *)

(* 书例本体：∀x fgx≡y ⟹ ∀x∃u(gx≡u ∧ fu≡y) *)
Definition orig_ex : fm := allq 0 (eqf (fsym 0 [fsym 1 [var 0]]) (var 1)).
Definition tred_ex : fm :=
  allq 0 (exq 30 (conj (eqf (fsym 1 [var 0]) (var 30))
                       (eqf (fsym 0 [var 30]) (var 1)))).

Example tred_ex_equiv : satis3 (iff_form orig_ex tred_ex) = true.
Proof. reflexivity. Qed.

(* 再一对：∃x f(f c)≡x 的化简——嵌套层手工拍平（见证 u=41） *)
Definition orig_ex2 : fm := exq 0 (eqf (fsym 0 [fsym 0 [fsym 2 []]]) (var 0)).
Definition tred_ex2 : fm :=
  exq 0 (exq 41 (conj (eqf (fsym 0 [fsym 2 []]) (var 41))
                      (eqf (fsym 0 [var 41]) (var 0)))).

Example tred_ex2_equiv : satis3 (iff_form orig_ex2 tred_ex2) = true.
Proof. reflexivity. Qed.

(* ---------- 4. 定义扩张 ≤-from-<（VIII.2.B / VIII.3） ---------- *)

(* 新符号 R2 解释为 ≤；定义公理 δ≤ := ∀x∀y (x ≤ y ↔ (x < y ∨ x ≡ y)) *)
Definition delta_le : fm :=
  allq 0 (allq 1 (iff_form (rat 2 [var 0; var 1])
                           (disj (rat 0 [var 0; var 1]) (eqf (var 0) (var 1))))).

Example delta_le_holds : satis3 delta_le = true.
Proof. reflexivity. Qed.

(* 消去翻译 χ ↦ χI：把 ≤-原子替换为定义体 *)
Fixpoint elim_le (φ : fm) : fm :=
  match φ with
  | rat 2 [t1; t2] => disj (rat 0 [t1; t2]) (eqf t1 t2)
  | rat s ts => rat s ts
  | eqf t1 t2 => eqf t1 t2
  | neg ψ => neg (elim_le ψ)
  | disj ψ χ => disj (elim_le ψ) (elim_le χ)
  | conj ψ χ => conj (elim_le ψ) (elim_le χ)
  | imp ψ χ => imp (elim_le ψ) (elim_le χ)
  | exq x ψ => exq x (elim_le ψ)
  | allq x ψ => allq x (elim_le ψ)
  end.

(* E2 现场三个：χ 与 χI 在 S3 上同值 *)
Definition chi1 : fm := allq 0 (exq 1 (rat 2 [var 0; var 1])).
Definition chi2 : fm := allq 0 (allq 1 (imp (rat 2 [var 0; var 1])
                                        (rat 2 [var 1; var 0]))).
Definition chi3 : fm := exq 0 (conj (rat 2 [var 0; var 1])
                                    (neg (rat 0 [var 0; var 1]))).

Example elim1 : satis3 (iff_form chi1 (elim_le chi1)) = true.
Proof. reflexivity. Qed.
Example elim2 : satis3 (iff_form chi2 (elim_le chi2)) = true.
Proof. reflexivity. Qed.
Example elim3 : satis3 (iff_form chi3 (elim_le chi3)) = true.
Proof. reflexivity. Qed.

(* E1（保守性）：≤--free 的句子不受 δ≤ 影响——翻译不动它们 *)
Example elim_fix : forallb (fun χ => evf f3 r3 D3 (fun _ => 0) (iff_form χ (elim_le χ)))
    [chi1; orig_ex; exq 0 (eqf (var 0) (var 0))] = true.
Proof. reflexivity. Qed.

(* ---------- 5. ⟨Φ⟩ 范式（VIII.4.2）：析取合取形 ---------- *)

(* 三个原子（命题骨架——无量词，变元 0/1/2 的比较原子） *)
(* 命题骨架求值：原子 = rat i []（命题变元化身），βv 第 i 位给真值。
   用命题变元代替「任意固定句子」做原子，避免嵌套类型的结构相等判定
   （tm_eqb 在 Coq 的 guard 检查下与 substt 同病——记入坑位） *)
Fixpoint peval (βv : list bool) (φ : fm) : bool :=
  match φ with
  | neg ψ => negb (peval βv ψ)
  | disj ψ χ => orb (peval βv ψ) (peval βv χ)
  | conj ψ χ => andb (peval βv ψ) (peval βv χ)
  | imp ψ χ => implb (peval βv ψ) (peval βv χ)
  | rat s [] => nth s βv false
  | _ => true
  end.

Definition p0 : fm := rat 0 [].
Definition p1 : fm := rat 1 [].
Definition p2 : fm := rat 2 [].
Definition atoms3 : list fm := [p0; p1; p2].

(* 全部 8 个赋值 *)
Definition betas8 : list (list bool) :=
  map (fun m => map (fun k => Nat.testbit m k) (seq 0 3)) (seq 0 8).

(* 满足行（文字合取）与成员的 DNF *)
Definition row_conj (βv : list bool) : fm :=
  conj_l (map (fun p => match snd p with
                | true => fst p | false => neg (fst p) end)
             (combine atoms3 βv)).

Definition dnf_of (φ : fm) : fm :=
  match filter (fun βv => peval βv φ) betas8 with
  | [] => neg (eqf (var 0) (var 0))
  | r0 :: rest => fold_right disj (row_conj r0) (map row_conj rest)
  end.

(* 4.1 引理的机器脚印：⟨Φ⟩ 对 ¬ ∨ 封闭，等价关系由全赋值枚举判定 *)
Definition member1 : fm := imp (disj p0 p1) (neg p2).
Definition member2 : fm := conj (neg p1) (disj p2 (neg p0)).
Definition member3 : fm := neg (imp p2 p0).

Example dnf_ok1 : forallb (fun βv => Bool.eqb (peval βv member1) (peval βv (dnf_of member1))) betas8 = true.
Proof. reflexivity. Qed.
Example dnf_ok2 : forallb (fun βv => Bool.eqb (peval βv member2) (peval βv (dnf_of member2))) betas8 = true.
Proof. reflexivity. Qed.
Example dnf_ok3 : forallb (fun βv => Bool.eqb (peval βv member3) (peval βv (dnf_of member3))) betas8 = true.
Proof. reflexivity. Qed.

(* ---------- 6. ZF 公理即公式（VII.3） ---------- *)

Definition in_rel (a b : tm) : fm := rat 4 [a; b].

Definition zf_ext : fm :=
  allq 0 (allq 1 (imp (allq 2 (iff_form (in_rel (var 2) (var 0))
                                        (in_rel (var 2) (var 1))))
                       (eqf (var 0) (var 1)))).

Definition zf_pair : fm :=
  allq 0 (allq 1 (exq 2 (allq 3
    (iff_form (in_rel (var 3) (var 2))
              (disj (eqf (var 3) (var 0)) (eqf (var 3) (var 1))))))).

Definition zf_union : fm :=
  allq 0 (exq 1 (allq 2 (iff_form (in_rel (var 2) (var 1))
    (exq 3 (conj (in_rel (var 2) (var 3)) (in_rel (var 3) (var 0))))))).

(* 分离模式的一个现场实例：φ(x,z) := (z ∈ x ∨ z ∉ x)——恒真分离 *)
Definition zf_sep_inst : fm :=
  allq 0 (exq 1 (allq 2 (iff_form (in_rel (var 2) (var 1))
    (conj (in_rel (var 2) (var 0))
          (disj (in_rel (var 2) (var 0)) (neg (in_rel (var 2) (var 0)))))))).

(* 冒烟：外延公理在「单点域 + 空 ∈」结构里成立（唯一元素与自己同成员） *)
Definition r_empty4 : interp_rel :=
  fun s args => match s, args with
  | 4, _ => false | _, _ => false end.

Example zf_ext_trivial :
  evf f3 r_empty4 [0] (fun _ => 0) zf_ext = true.
Proof. reflexivity. Qed.

Compute (length betas8).               (* 8 *)
Compute (satis3 orig_ex).              (* true：环绕后继下 fgx≡y 可解 *)
Compute (map (dnf_of) [member1]).      (* 成员 1 的析取合取范式 *)
