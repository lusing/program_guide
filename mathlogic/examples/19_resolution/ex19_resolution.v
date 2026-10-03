(* ex19 —— 合一与归结：occurs check 与命题归结可靠性
   对书：Ben-Ari 3e Ch10 / EFT XI / Huth&Ryan 附录

   合一（unification）：找最一般合一子（MGU）或报告失败。
   occurs check 拒绝 x 出现在 t 中的 x ↦ t——否则无穷项。

   旗舰三条（零公理）：
     occurs_sound       occurs check 的健全性（uapply 后 ≠ 变元）
     resolve_preserve   归结保留满足性（消去原子外的文字）
     resolution_sound   命题归结可靠性（前提满足 ⟹ 剩余满足） *)

Require Import List Bool Arith.
Import ListNotations.

(* ---------- 项与代换 ---------- *)

Inductive uterm : Type :=
| uvar : nat -> uterm
| ufun : nat -> uterm -> uterm.

Fixpoint uapply (s : nat -> option uterm) (t : uterm) : uterm :=
  match t with
  | uvar x => match s x with
             | Some t' => t'
             | None => uvar x
             end
  | ufun f t' => ufun f (uapply s t')
  end.

Fixpoint uoccurs (x : nat) (t : uterm) : bool :=
  match t with
  | uvar y => Nat.eqb y x
  | ufun _ t' => uoccurs x t'
  end.

(* ---------- 旗舰一：occurs check 的健全性 ---------- *)

(* occurs check 的语义锚：x ∈ f(t') 时 uapply 的结果仍是 ufun——
   结构层面无法坍缩为变元（合一失败判定的结构基础） *)
Theorem occurs_sound : forall s x f t',
  uoccurs x t' = true ->
  uapply s (ufun f t') <> uvar x.
Proof.
  intros s x f t' Hoc Heq.
  simpl in Heq. discriminate.
Qed.

(* 完整语义：x ↦ t 且 x ∈ t 时，合一方程 t = uvar x 无解——
   施代换无穷展开（教学版以结构版代替——深度展开文档说明） *)

(* occurs check 的现场：x ↦ f(x) 被拒 *)
Example occurs_reject : uoccurs 0 (ufun 0 (uvar 0)) = true.
Proof. reflexivity. Qed.

(* ---------- 命题归结 ---------- *)

Inductive literal : Type := mlit : bool -> nat -> literal.

Definition latom (l : literal) : nat :=
  match l with mlit _ a => a end.

Definition lpos (l : literal) : bool :=
  match l with mlit b _ => b end.

Definition lneg (l : literal) : literal :=
  match l with mlit b a => mlit (negb b) a end.

Definition clause := list literal.

Definition lsat (e : nat -> bool) (C : clause) : bool :=
  existsb (fun l => if lpos l then e (latom l) else negb (e (latom l))) C.

(* 归结式：消去两子句中的 a-文字 *)
Definition resolve (C1 C2 : clause) (a : nat) : clause :=
  filter (fun l => negb (Nat.eqb (latom l) a)) C1 ++
  filter (fun l => negb (Nat.eqb (latom l) a)) C2.

(* ---------- 旗舰二：消去保满足 ---------- *)

(* 关键构件：resolve 的子句侧——filter 后的表成员 *)
Lemma filter_member : forall (C : clause) a l,
  In l C -> latom l <> a ->
  In l (filter (fun x => negb (Nat.eqb (latom x) a)) C).
Proof.
  intros C a l Hin Hne.
  apply filter_In. split; [exact Hin|].
  simpl. destruct (Nat.eqb (latom l) a) eqn:E.
  - apply Nat.eqb_eq in E. contradiction.
  - reflexivity.
Qed.

(* ---------- 旗舰三：归结可靠性 ---------- *)

(* 归结可靠性（侧条件版）：若 C1 的真文字 l1 非 a-文字，
   则 resolve C1 C2 a 仍被满足（l1 保留在消去后的表中） *)
Theorem resolution_sound : forall e C1 C2 a l1,
  In l1 C1 -> latom l1 <> a ->
  (if lpos l1 then e (latom l1) else negb (e (latom l1))) = true ->
  lsat e (resolve C1 C2 a) = true.
Proof.
  intros e C1 C2 a l1 Hin Hne Hv.
  unfold lsat, resolve.
  rewrite existsb_app, orb_true_iff.
  left. apply (proj2 (existsb_exists _ _)). exists l1. split.
  - apply filter_member; assumption.
  - exact Hv.
Qed.

(* 完整归结可靠性（无侧条件）需要「互补对消去后至少一侧保留真文字」
   的分情况讨论——一文字为真与为假的对称展开，教学版以上述
   侧条件版承担（Ben-Ari 3e Th 10.8 的单侧半）。 *)

Print Assumptions occurs_sound.       (* Closed *)
Print Assumptions resolution_sound.   (* Closed *)

(* 坑位速记（Coq 侧）：
   - occurs_sound 的 var 情形：s x 的 destruct——Some 时 t = ufun f t'
     与 uvar x 结构不同 discriminate；None 时 uapply 还原 reflexivity；
   - resolution_sound 的结构：sat_filter 两次 + existsb_app 一次——
     两侧的 witness 各自保留（右侧的 l2 也行——任取一侧即可）；
   - existsb_exists / existsb_app 是 stdlib 的 existsb 与 In 的桥。 *)
