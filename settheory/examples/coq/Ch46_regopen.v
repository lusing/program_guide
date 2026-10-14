(** 第 46 章：有限拓扑上 ⊥ 运算的决定性验证（计算式证明）

    论域固定 3 点 {0,1,2}；集合用升序列表表示。
    拓扑 τ = {∅, {0}, {0,1}, {0,2}, Ω}。
    证明架构：tau_cases / subsets_cases 把 In 假设换成
    "变量 = 常量"等式（-> 模式消掉变量），布尔反射 in_tau 做最终判定。 *)

Require Import List Arith Lia.
Import ListNotations.

Definition Omega : list nat := [0; 1; 2].
Definition tau : list (list nat) := [ nil; [0]; [0;1]; [0;2]; Omega ].
Definition subsets : list (list nat) :=
  [ nil; [0]; [1]; [2]; [0;1]; [0;2]; [1;2]; Omega ].

(* ---- 朴素集合工具 ---- *)
Fixpoint mem (x : nat) (l : list nat) : bool :=
  match l with
  | nil => false
  | y :: t => if Nat.eq_dec x y then true else mem x t
  end.

(* 规范形：去重 + 升序排序——所有集合值函数的输出统一过 norm，
   保证"同一个集合"只有唯一的列表表示 *)
Fixpoint dedupl (l : list nat) : list nat :=
  match l with
  | nil => nil
  | x :: t => if mem x t then dedupl t else x :: dedupl t
  end.

Fixpoint insertl (x : nat) (l : list nat) : list nat :=
  match l with
  | nil => [x]
  | y :: t => if Nat.leb x y then x :: y :: t else y :: insertl x t
  end.

Fixpoint isortl (l : list nat) : list nat :=
  match l with
  | nil => nil
  | y :: t => insertl y (isortl t)
  end.

Definition norm (l : list nat) : list nat := isortl (dedupl l).

Definition subsetl (A B : list nat) : bool :=
  forallb (fun x => mem x B) A.

Definition interl (A B : list nat) : list nat :=
  norm (filter (fun x => mem x A) B).

Definition unionl (A B : list nat) : list nat :=
  norm (filter (fun x => negb (mem x A)) B ++ A).

Definition compl (U : list nat) : list nat :=
  norm (filter (fun x => negb (mem x U)) Omega).

(* ---- In 的两种"清点"引理 ---- *)

Lemma tau_cases : forall l, In l tau ->
  l = nil \/ l = [0] \/ l = [0;1] \/ l = [0;2] \/ l = Omega.
Proof.
  intros l H. simpl in H.
  destruct H as [H|[H|[H|[H|[H|[]]]]]]; subst;
    repeat (first [ left; reflexivity | right ]); try reflexivity.
Qed.

Lemma subsets_cases : forall l, In l subsets ->
  l = nil \/ l = [0] \/ l = [1] \/ l = [2] \/ l = [0;1] \/
  l = [0;2] \/ l = [1;2] \/ l = Omega.
Proof.
  intros l H. simpl in H.
  destruct H as [H|[H|[H|[H|[H|[H|[H|[H|[]]]]]]]]]; subst;
    repeat (first [ left; reflexivity | right ]); try reflexivity.
Qed.

(* ---- 布尔反射：In l tau ⟺ in_tau l = true ---- *)
Definition eql (A B : list nat) : bool :=
  if list_eq_dec Nat.eq_dec A B then true else false.

Lemma eql_true : forall A B, eql A B = true -> A = B.
Proof.
  intros A B H. unfold eql in H.
  destruct (list_eq_dec Nat.eq_dec A B); [ assumption | discriminate ].
Qed.

Definition in_tau (l : list nat) : bool :=
  existsb (fun t => eql l t) tau.

Lemma in_tau_In : forall l, in_tau l = true -> In l tau.
Proof.
  intros l H. unfold in_tau, existsb in H.
  apply existsb_exists in H. destruct H as [t [Ht He]].
  apply eql_true in He. subst. exact Ht.
Qed.

(* ---- 闭包 / 内部 / 正则化 / ⊥ ---- *)
Definition closed_sets : list (list nat) := map compl tau.

Definition big_inter (L : list (list nat)) : list nat :=
  fold_right interl Omega L.

Definition cl (U : list nat) : list nat :=
  big_inter (filter (fun C => subsetl U C) closed_sets).

Definition big_union (L : list (list nat)) : list nat :=
  fold_right unionl nil L.

Definition int_ (U : list nat) : list nat :=
  big_union (filter (fun O => subsetl O U) tau).

Definition reg (U : list nat) : list nat := int_ (cl U).
Definition perp (U : list nat) : list nat := compl (cl U).

(* ---- 拓扑自检：有限并与交封闭 ---- *)
Lemma tau_ok : forall A B,
  In A tau -> In B tau ->
  In (unionl A B) tau /\ In (interl A B) tau.
Proof.
  intros A B HA HB.
  apply tau_cases in HA. apply tau_cases in HB.
  destruct HA as [HA|[HA|[HA|[HA|HA]]]]; subst A;
  destruct HB as [HB|[HB|[HB|[HB|HB]]]]; subst B;
  split; apply in_tau_In; vm_compute; reflexivity.
Qed.

(* ---- ⊥ 五律 ---- *)

(* (2) De Morgan 并律：perp (U∪V) = perp U ∩ perp V（全部 64 组合） *)
Lemma law2 : forall U V,
  In U subsets -> In V subsets ->
  perp (unionl U V) = interl (perp U) (perp V).
Proof.
  intros U V HU HV.
  apply subsets_cases in HU. apply subsets_cases in HV.
destruct HU as [HU|[HU|[HU|[HU|[HU|[HU|[HU|HU]]]]]]]; subst U;
destruct HV as [HV|[HV|[HV|[HV|[HV|[HV|[HV|HV]]]]]]]; subst V;
  vm_compute; reflexivity.
Qed.

(* (3) 双 ⊥ 就是正则化：reg V = V⊥⊥（全部 8 点，任意 V） *)
Lemma law3 : forall V,
  In V subsets -> reg V = perp (perp V).
Proof.
  intros V HV. apply subsets_cases in HV.
destruct HV as [HV|[HV|[HV|[HV|[HV|[HV|[HV|HV]]]]]]]; subst V;
  vm_compute; reflexivity.
Qed.

(* (4) 开集上 U⊥⊥ = Reg(U)，且一次 ⊥ 已正则：U⊥⊥⊥ = U⊥ *)
Lemma law4 : forall U,
  In U tau -> perp (perp U) = reg U.
Proof.
  intros U HU. apply tau_cases in HU.
destruct HU as [HU|[HU|[HU|[HU|HU]]]]; subst U;
  vm_compute; reflexivity.
Qed.

Lemma law4' : forall U,
  In U tau -> perp (perp (perp U)) = perp U.
Proof.
  intros U HU. apply tau_cases in HU.
destruct HU as [HU|[HU|[HU|[HU|HU]]]]; subst U;
  vm_compute; reflexivity.
Qed.

(* (5) 开集交律：(U∩V)⊥⊥ = U⊥⊥ ∩ V⊥⊥ *)
Lemma law5 : forall U V,
  In U tau -> In V tau ->
  perp (perp (interl U V)) = interl (perp (perp U)) (perp (perp V)).
Proof.
  intros U V HU HV.
  apply tau_cases in HU. apply tau_cases in HV.
destruct HU as [HU|[HU|[HU|[HU|HU]]]]; subst U;
destruct HV as [HV|[HV|[HV|[HV|HV]]]]; subst V;
  vm_compute; reflexivity.
Qed.

(* (1) 反单调抽样：∅ ⊆ U ⟹ perp U ⊆ perp ∅ *)
Lemma law1_sample : forall U,
  In U subsets -> subsetl (perp U) (perp nil) = true.
Proof.
  intros U HU. apply subsets_cases in HU.
destruct HU as [HU|[HU|[HU|[HU|[HU|[HU|[HU|HU]]]]]]]; subst U;
  vm_compute; reflexivity.
Qed.

(* 抽样一：{0,1} 在本拓扑中稠密（含 0 的闭集只有 Ω），故 Reg = Ω *)
Lemma sample_dense : reg [0;1] = [0;1;2].
Proof. vm_compute. reflexivity. Qed.

(* 抽样二：非开集 {1}：Cl = {1} 但 Int({1}) = ∅，Reg({1}) = ∅ *)
Lemma sample_crack : reg [1] = nil.
Proof. vm_compute. reflexivity. Qed.
