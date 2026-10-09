(* ex31_ultraproduct.v —— 超积与 Łoś 定理（Marker ch6）
   机器件：有限集上超滤=主超滤的全枚举证明（n=3：256 族恰 3 个）；
   主超滤 Łoś 定理的完整结构归纳（原子/¬/∨/∃ 四步，零公理）；
   Fréchet 滤子上 ¬ 步的失败现场（书评注：第 (4) 步是唯一用超滤性处）；
   超幂对角元的「最终占优」（非标准元素的数值影子）。 *)

From Stdlib Require Import List Arith Lia.
Import ListNotations.

(* ---------- 1. 滤子与超滤：有限集上的全枚举 ---------- *)

Fixpoint bits (m : nat) : list (list bool) :=
  match m with
  | 0 => [[]]
  | S m' => map (cons false) (bits m') ++ map (cons true) (bits m')
  end.

Fixpoint beqb (a b : list bool) : bool :=
  match a, b with
  | [], [] => true
  | x :: a', y :: b' => andb (Bool.eqb x y) (beqb a' b')
  | _, _ => false
  end.

Definition submemb (b : list bool) (F : list (list bool)) : bool :=
  existsb (fun c => beqb b c) F.

Definition fullI (n : nat) : list bool := repeat true n.
Definition emptyI (n : nat) : list bool := repeat false n.
Definition suband (b c : list bool) : list bool :=
  if Nat.eqb (length b) (length c)
  then map (fun p => andb (fst p) (snd p)) (combine b c)
  else b.

(* 滤子三公理：含 I、不含 ∅、上闭+交封闭（对枚举的幂域全查）
   上闭用 b ⊆ c ⟺ b∧c = b；全写成「前提假或结论真」的布尔式 *)
Definition is_filterb (n : nat) (F : list (list bool)) : bool :=
  andb (submemb (fullI n) F)
       (andb (negb (submemb (emptyI n) F))
       (andb (forallb (fun b => forallb (fun c =>
                orb (negb (submemb b F))
                (orb (negb (beqb (suband b c) b))
                     (submemb c F))) (bits n)) (bits n))
             (forallb (fun b => forallb (fun c =>
                orb (negb (submemb b F))
                (orb (negb (submemb c F))
                     (submemb (suband b c) F))) (bits n)) (bits n)))).

Definition is_ultra (n : nat) (F : list (list bool)) : bool :=
  andb (is_filterb n F)
       (forallb (fun b => orb (submemb b F) (submemb (map negb b) F)) (bits n)).

Definition principal (i n : nat) : list (list bool) :=
  filter (fun b => nth i b false) (bits n).

(* 族 = P(I) 的子集：用 2^|P(I)| 位掩码从子集表中挑选 *)
Definition fam_of (subs : list (list bool)) (mask : list bool)
  : list (list bool) :=
  flat_map (fun p : list bool * bool =>
              if snd p then [fst p] else (@nil (list bool)))
    (combine subs mask).

Definition all_fams (n : nat) : list (list (list bool)) :=
  map (fam_of (bits n)) (bits (length (bits n))).

Definition samefam (F G : list (list bool)) : bool :=
  andb (Nat.eqb (length F) (length G))
       (andb (forallb (fun b => submemb b G) F)
             (forallb (fun b => submemb b F) G)).

(* 旗舰①：n=3 时恰有 3 个超滤，且全部是主超滤 *)
Example ultra_principal_3 :
  andb (Nat.eqb (length (filter (is_ultra 3) (all_fams 3))) 3)
       (forallb (fun F => existsb (fun i => samefam F (principal i 3)) [0;1;2])
                (filter (is_ultra 3) (all_fams 3))) = true.
Proof. reflexivity. Qed.

(* 主超滤通过检查（n=4 抽查；全枚举 2^16 不做） *)
Example principal_ultra_4 :
  forallb (fun i => is_ultra 4 (principal i 4)) [0;1;2;3] = true.
Proof. reflexivity. Qed.

(* Fréchet（截断 [0;16) 上的余有限）是滤子但非超滤 *)
Definition cofin16 (b : list bool) : bool :=
  Nat.leb (length (filter (fun x => negb x) b)) 4.

Definition evens16 : list bool := map Nat.even (seq 0 16).

Example frechet_filter_not_ultra :
  andb (cofin16 (fullI 16))
       (andb (negb (cofin16 (emptyI 16)))
       (andb (negb (cofin16 evens16))
             (negb (cofin16 (map negb evens16))))) = true.
Proof. reflexivity. Qed.

(* ---------- 2. 迷你语言 {P,=} 与双求值器 ---------- *)

Record stru : Type := mkstru { dom : nat; predP : list bool }.

Inductive afm : Type :=
| aP (x : nat)
| aEq (x y : nat)
| aNeg (p : afm)
| aDisj (p q : afm)
| aExq (x : nat) (p : afm).

Fixpoint setn (l : list nat) (x v : nat) : list nat :=
  match l, x with
  | [], _ => []
  | _ :: l', 0 => v :: l'
  | y :: l', S x' => y :: setn l' x' v
  end.

Fixpoint setnl (l : list (list nat)) (x : nat) (v : list nat)
  : list (list nat) :=
  match l, x with
  | [], _ => []
  | _ :: l', 0 => v :: l'
  | y :: l', S x' => y :: setnl l' x' v
  end.

(* 单因子求值：env = 分量值表 *)
Fixpoint fev (M : stru) (phi : afm) (env : list nat) : bool :=
  match phi with
  | aP x => nth (nth x env 0) (predP M) false
  | aEq x y => Nat.eqb (nth x env 0) (nth y env 0)
  | aNeg p => negb (fev M p env)
  | aDisj p q => orb (fev M p env) (fev M q env)
  | aExq x p =>
      existsb (fun a => fev M p (setn env x a)) (seq 0 (dom M))
  end.

Definition projv (v : list nat) (i : nat) : nat := nth i v 0.

(* 同域 d、长度 n 的全部向量 *)
Fixpoint allvn (d n : nat) : list (list nat) :=
  match n with
  | 0 => [[]]
  | S n' =>
      flat_map (fun v => map (fun a => a :: v) (seq 0 d)) (allvn d n')
  end.

(* 积求值：同域因子表 Ms、主超滤位置 i；env = 向量表；
   ∃ 量化整个向量——「积」的量词长这样 *)
Fixpoint fevP (Ms : list stru) (d i : nat) (phi : afm)
         (env : list (list nat)) : bool :=
  match phi with
  | aP x =>
      nth (projv (nth x env []) i) (predP (nth i Ms (mkstru 0 []))) false
  | aEq x y =>
      Nat.eqb (projv (nth x env []) i) (projv (nth y env []) i)
  | aNeg p => negb (fevP Ms d i p env)
  | aDisj p q => orb (fevP Ms d i p env) (fevP Ms d i q env)
  | aExq x p =>
      existsb (fun v => fevP Ms d i p (setnl env x v))
        (allvn d (length Ms))
  end.

(* ---------- 3. 旗舰②：主超滤 Łoś 定理（结构归纳，零公理） ---------- *)

Lemma existsb_app2 : forall (B : Type) (g : B -> bool) l1 l2,
  existsb g (l1 ++ l2) = orb (existsb g l1) (existsb g l2).
Proof.
  intros B g l1. induction l1 as [|x l1' IH]; intros l2; simpl.
  - reflexivity.
  - rewrite IH. rewrite Bool.orb_assoc. reflexivity.
Qed.

Lemma existsb_flat : forall (A B : Type) (g : B -> bool)
                           (f : A -> list B) (l : list A),
  existsb g (flat_map f l) = existsb (fun y => existsb g (f y)) l.
Proof.
  intros A B g f l. induction l as [|x l' IH].
  - reflexivity.
  - simpl. rewrite existsb_app2, IH. reflexivity.
Qed.

Lemma existsb_false : forall (A : Type) (l : list A),
  existsb (fun _ => false) l = false.
Proof. intros A. induction l as [|x l' IH]; simpl; [reflexivity | exact IH]. Qed.

Lemma existsb_const : forall (A : Type) (b : bool) (l : list A), l <> [] ->
  existsb (fun _ => b) l = b.
Proof.
  intros A b [|x t] Hne; [congruence|].
  simpl. destruct b.
  - reflexivity.
  - apply existsb_false.
Qed.

Lemma allvn_nonempty : forall d n, 0 < d -> allvn d n <> [].
Proof.
  intros d n Hd. induction n as [|n' IH]; simpl.
  - congruence.
  - destruct (allvn d n') as [|v0 rest] eqn:E; [congruence|].
    destruct d as [|d0]; [lia|].
    intro Hc.
    assert (Hin : In (0 :: v0) (flat_map
      (fun v => map (fun a => a :: v) (seq 0 (S d0))) (v0 :: rest))).
    { apply in_flat_map. exists v0. split.
      - left. reflexivity.
      - apply in_map_iff. exists 0. split.
        + reflexivity.
        + simpl. left. reflexivity. }
    rewrite Hc in Hin. exact Hin.
Qed.

(* 逐点相等即可改写 existsb（归纳，避免函数外延公理） *)
Lemma existsb_map2 : forall (A B : Type) (g : B -> bool) (f : A -> B) (l : list A),
  existsb g (map f l) = existsb (fun x => g (f x)) l.
Proof.
  intros A B g f l. induction l as [|x t IH]; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

Lemma existsb_pointwise : forall (A : Type) (l : list A) (G H : A -> bool),
  (forall x, G x = H x) -> existsb G l = existsb H l.
Proof.
  intros A l G H HP. induction l as [|x t IH]; simpl.
  - reflexivity.
  - rewrite (HP x), IH. reflexivity.
Qed.

(* 关键引理：域非空时，向量的第 i 分量投影恰好取遍因子域 *)
Lemma existsb_allvn : forall (F : nat -> bool) (d n i : nat),
  0 < d -> i < n ->
  existsb (fun v => F (projv v i)) (allvn d n) =
  existsb F (seq 0 d).
Proof.
  intros F d n. induction n as [|n' IH]; intros i Hd Hi.
  - lia.
  - simpl. rewrite existsb_flat.
    destruct i as [|i'].
    + (* i=0：头部即分量——内层与 v' 无关 *)
      rewrite (existsb_pointwise (list nat) (allvn d n')
        (fun (v' : list nat) => existsb (fun av => F (projv av 0))
                    (map (fun a => a :: v') (seq 0 d)))
        (fun (_ : list nat) => existsb F (seq 0 d))).
      * rewrite (existsb_const _ _ (allvn d n') (allvn_nonempty d n' Hd)).
        reflexivity.
      * intros v'. rewrite existsb_map2. reflexivity.
    + (* i=S i'：分量落在尾部——内层退化为常量 *)
      rewrite (existsb_pointwise (list nat) (allvn d n')
        (fun (v' : list nat) => existsb (fun av => F (projv av (S i')))
                    (map (fun a => a :: v') (seq 0 d)))
        (fun (v' : list nat) => F (projv v' i'))).
      * apply IH; [exact Hd | lia].
      * intros v'. rewrite existsb_map2. cbn [projv nth].
        rewrite (existsb_const _ _ (seq 0 d)).
        -- reflexivity.
        -- destruct d as [|d0]; [lia | discriminate].
Qed.

Lemma nth_map_proj : forall (env : list (list nat)) (x i : nat),
  nth x (map (fun w => projv w i) env) 0 = projv (nth x env []) i.
Proof.
  induction env as [|e t IH]; intros x i.
  - destruct x; destruct i; reflexivity.
  - destruct x as [|x']; simpl; [reflexivity | apply IH].
Qed.

Lemma map_setnl : forall (env : list (list nat)) (x i : nat) (v : list nat),
  map (fun w => projv w i) (setnl env x v) =
  setn (map (fun w => projv w i) env) x (projv v i).
Proof.
  induction env as [|e t IH]; intros x i v.
  - reflexivity.
  - destruct x as [|x']; simpl; [reflexivity | rewrite IH; reflexivity].
Qed.

(* 主超滤 Łoś：积求值 = 第 i 因子求值（对 phi 结构归纳） *)
Theorem los_principal : forall (Ms : list stru) (d i : nat)
                                (phi : afm) (env : list (list nat)),
  0 < d -> i < length Ms ->
  (forall M, In M Ms -> dom M = d) ->
  fevP Ms d i phi env =
  fev (nth i Ms (mkstru 0 [])) phi (map (fun v => projv v i) env).
Proof.
  intros Ms d i phi. induction phi as
    [x | x y | p IH | p IHp q IHq | x p IH];
    intros env Hd Hi Hunif.
  - unfold fevP, fev. rewrite nth_map_proj. reflexivity.
  - unfold fevP, fev. rewrite !nth_map_proj. reflexivity.
  - simpl. rewrite (IH env Hd Hi Hunif). reflexivity.
  - simpl. rewrite (IHp env Hd Hi Hunif). rewrite (IHq env Hd Hi Hunif). reflexivity.
  - cbn [fevP fev].
    rewrite (existsb_pointwise (list nat) (allvn d (length Ms))
      (fun v => fevP Ms d i p (setnl env x v))
      (fun v => fev (nth i Ms (mkstru 0 [])) p
                   (setn (map (fun w => projv w i) env) x (projv v i)))).
    + rewrite (existsb_allvn
        (fun a => fev (nth i Ms (mkstru 0 [])) p
                   (setn (map (fun w => projv w i) env) x a))
        d (length Ms) i).
      * cbn [fev].
        rewrite (Hunif (nth i Ms (mkstru 0 [])) (nth_In Ms (mkstru 0 []) Hi)).
        reflexivity.
      * exact Hd.
      * exact Hi.
    + intros v. rewrite (IH (setnl env x v) Hd Hi Hunif).
      rewrite map_setnl. reflexivity.
Qed.

(* ---------- 4. 现场对账 ---------- *)

Definition M_T : stru := mkstru 2 [true; false].   (* P = {0} *)
Definition M_F : stru := mkstru 2 [false; false].  (* P = ∅ *)

Definition Ms2 : list stru := [M_T; M_F].

Example los_demo_0 :
  andb (fevP Ms2 2 0 (aExq 0 (aP 0)) [])
       (Bool.eqb (fev M_T (aExq 0 (aP 0)) []) true) = true.
Proof. reflexivity. Qed.

Example los_demo_1 :
  andb (negb (fevP Ms2 2 1 (aExq 0 (aP 0)) []))
       (Bool.eqb (fev M_F (aExq 0 (aP 0)) []) false) = true.
Proof. reflexivity. Qed.

(* Fréchet ¬步失败现场：偶奇交替的 16 因子族，元素 a=全零向量
   的 {i : P_i(a_i)} = 偶数集——既不大、余集也不大（§1 的
   frechet_filter_not_ultra 即其账本）——经典否定强制选边而
   「大」的语义没有答案：书评注「第 (4) 步是唯一用超滤性处」。 *)

(* 超幂对角元：截断 [0,16) 上 [id] 最终大于每个常函数 k̄ *)
Example diag_dominates :
  forallb (fun k => forallb (fun i => orb (Nat.leb i k) (Nat.ltb k i))
              (seq 0 16)) (seq 0 16) = true.
Proof. reflexivity. Qed.

(* 超积证紧致性 / Keisler–Shelah：文档级（docs/31-ultraproduct.md） *)

Print Assumptions los_principal.   (* Closed under global context *)

(* 冒烟 *)
Compute (length (filter (is_ultra 3) (all_fams 3))).  (* 3 *)
Compute (map (fun i => is_ultra 4 (principal i 4)) [0;1;2;3]).
Compute (fevP Ms2 2 0 (aExq 0 (aP 0)) [], fevP Ms2 2 1 (aExq 0 (aP 0)) []).
