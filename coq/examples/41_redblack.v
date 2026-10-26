(* 41 红黑树 —— 插入、平衡不变量与正确性 *)

From Stdlib Require Import Arith Bool Lia List Permutation.
Import ListNotations.

Module Ex41Redblack.

(* ---------- 41.1 表示：颜色、树与 lookup ---------- *)

(* 键取 nat（原书用 Extract 章公理化的 int 并按 Abs 比较，这里换成 nat
   直接用 <?，验证主线完全不变）。 *)
Definition key := nat.

Inductive color := Red | Black.

Inductive tree (V : Type) : Type :=
| E : tree V
| T : color -> tree V -> key -> V -> tree V -> tree V.

Arguments E {V}.
Arguments T {V}.

Definition empty_tree (V : Type) : tree V :=
  E.

(* lookup 与第 28 章 BST 完全同构，只是 T 结点多带一个被忽略的 color。 *)
Fixpoint lookup {V : Type} (d : V) (x : key) (t : tree V) : V :=
  match t with
  | E => d
  | T _ tl k v tr =>
    if x <? k then lookup d x tl
    else if k <? x then lookup d x tr
    else v
  end.

(* ---------- 41.2 插入：balance 的五种情形与 ins ---------- *)

(* ins 沿搜索路径下行（与 BST 插入几乎相同），balance 在回程重平衡。
   balance 的 match 一共覆盖五种情形：c = Red 时原样返回（情形 0）；
   c = Black 时看 t1/t2 里有没有「红结点带红孩子」——左左、左右、
   右左、右右四种旋转（情形 1-4），都没有则染黑原样返回。 *)
Definition balance
           {V : Type} (c : color) (t1 : tree V) (k : key) (vk : V)
           (t2 : tree V) : tree V :=
  match c with
  | Red => T Red t1 k vk t2
  | _ => match t1 with
        | T Red (T Red a x vx b) y vy c =>
            T Red (T Black a x vx b) y vy (T Black c k vk t2)
        | T Red a x vx (T Red b y vy c) =>
            T Red (T Black a x vx b) y vy (T Black c k vk t2)
        | _ => match t2 with
              | T Red (T Red b y vy c) z vz d =>
                  T Red (T Black t1 k vk b) y vy (T Black c z vz d)
              | T Red b y vy (T Red c z vz d) =>
                  T Red (T Black t1 k vk b) y vy (T Black c z vz d)
              | _ => T Black t1 k vk t2
              end
        end
  end.

Fixpoint ins {V : Type} (x : key) (vx : V) (t : tree V) : tree V :=
  match t with
  | E => T Red E x vx E
  | T c a y vy b =>
    if x <? y then balance c (ins x vx a) y vy b
    else if y <? x then balance c a y vy (ins x vx b)
    else T c a x vx b
  end.

(* ins 可能把根染红；根的红父亲不存在，但为了局部不变量统一把根染黑。 *)
Definition make_black {V : Type} (t : tree V) : tree V :=
  match t with
  | E => E
  | T _ a x vx b => T Black a x vx b
  end.

Definition insert {V : Type} (x : key) (vx : V) (t : tree V) :=
  make_black (ins x vx t).

Fixpoint elements_aux {V : Type} (t : tree V) (acc : list (key * V))
  : list (key * V) :=
  match t with
  | E => acc
  | T _ l k v r => elements_aux l ((k, v) :: elements_aux r acc)
  end.

Definition elements {V : Type} (t : tree V) : list (key * V) :=
  elements_aux t [].

Example elements_example :
  elements (insert 3 30 (insert 1 10 (insert 2 20
            (insert 5 50 (insert 4 40 (empty_tree nat))))))
  = [(1, 10); (2, 20); (3, 30); (4, 40); (5, 50)].
Proof. reflexivity. Qed.

(* ---------- 41.3 情形分析自动化：ins_not_E ---------- *)

(* 热身：任何 insert 的中间结果 ins 都不是空树。原书在这里用
   bdestruct/inv，本章全部换成标准战术：destruct 撕布尔与构造子、
   discriminate 关构造子等式。match goal 找到「目标是对 color 或
   tree 的 match」就 destruct，见到 T <> E 就 discriminate。 *)
Lemma ins_not_E : forall (V : Type) (x : key) (vx : V) (t : tree V),
    ins x vx t <> E.
Proof.
  intros V x vx t. destruct t as [ | c t1 k v t2]; simpl.
  - discriminate.
  - unfold balance.
    repeat
      match goal with
      | |- (if ?b then _ else _) <> _ => destruct b
      | |- match ?c with Red => _ | Black => _ end <> _ => destruct c
      | |- match ?t with E => _ | T _ _ _ _ _ => _ end <> _ => destruct t
      | |- T _ _ _ _ _ <> E => discriminate
      end.
Qed.

(* ---------- 41.4 BST 不变量：ForallT、balance_BST 与 insert_BST ---------- *)

(* ForallT P t：树上每个结点 (k,v) 都满足 P k v。 *)
Fixpoint ForallT {V : Type} (P : key -> V -> Prop) (t : tree V) : Prop :=
  match t with
  | E => True
  | T _ l k v r => P k v /\ ForallT P l /\ ForallT P r
  end.

Inductive BST {V : Type} : tree V -> Prop :=
| ST_E : BST E
| ST_T : forall (c : color) (l : tree V) (k : key) (v : V) (r : tree V),
    ForallT (fun k' _ => k' < k) l ->
    ForallT (fun k' _ => k' > k) r ->
    BST l ->
    BST r ->
    BST (T c l k v r).

Lemma empty_tree_BST : forall (V : Type), BST (@empty_tree V).
Proof. unfold empty_tree. constructor. Qed.

Lemma ForallT_imp : forall (V : Type) (P Q : key -> V -> Prop) t,
    ForallT P t ->
    (forall k v, P k v -> Q k v) ->
    ForallT Q t.
Proof.
  intros V P Q t. induction t as [ | c l k v r IHl IHr]; intros HP Himp.
  - exact I.
  - destruct HP as [Hk [Hl Hr]].
    repeat split; auto.
Qed.

(* 两条单调性小引理：整棵子树的键都 > k（或 < k），而 k 又 > k0
   （或 < k0），则子树全部键都 > k0（或 < k0）。供 balance_BST 的
   自动化收尾用。 *)
Lemma ForallT_greater : forall (V : Type) (t : tree V) (k k0 : key),
    ForallT (fun k' _ => k' > k) t ->
    k > k0 ->
    ForallT (fun k' _ => k' > k0) t.
Proof.
  intros V t k k0 H Hk.
  eapply ForallT_imp.
  - exact H.
  - intros k' v Hkv. simpl in Hkv. lia.
Qed.

Lemma ForallT_less : forall (V : Type) (t : tree V) (k k0 : key),
    ForallT (fun k' _ => k' < k) t ->
    k < k0 ->
    ForallT (fun k' _ => k' < k0) t.
Proof.
  intros V t k k0 H Hk.
  eapply ForallT_imp.
  - exact H.
  - intros k' v Hkv. simpl in Hkv. lia.
Qed.

(* balance 保 BST：手工展开后约 41 类情形。自动化按四条规则推进：
   假设里见到 ForallT _ (T ...) 就拆成根/左/右三份；假设里见到
   BST (T ...) 就 inversion 出孙辈的界；目标里见到 T 就 constructor；
   目标是 ForallT/其余算术不等式就 split + auto + lia。 *)
Lemma balance_BST : forall (V : Type) (c : color) (l : tree V) (k : key)
                      (v : V) (r : tree V),
    ForallT (fun k' _ => k' < k) l ->
    ForallT (fun k' _ => k' > k) r ->
    BST l ->
    BST r ->
    BST (balance c l k v r).
Proof.
  intros V c l k v r PL PR BL BR. unfold balance.
  repeat
    match goal with
    | H : ForallT _ (T _ _ _ _ _) |- _ => destruct H as [? [? ?] ]
    | H : BST (T _ _ _ _ _) |- _ => inversion H; subst; clear H
    | |- BST (T _ _ _ _ _) => constructor
    | |- BST (match ?c with Red => _ | Black => _ end) => destruct c
    | |- BST (match ?t with E => _ | T _ _ _ _ _ => _ end) => destruct t
    | |- ForallT _ (T _ _ _ _ _) => repeat split
    end;
    auto; try lia.
  (* 剩下的都是「子树全部键 <(>) 某个中间键」的目标，交给两条
     单调性引理接力。 *)
  all: try eapply ForallT_greater; try eapply ForallT_less; eauto; try lia.
Qed.

(* balance 保留任意逐结点谓词 P。 *)
Lemma balanceP : forall (V : Type) (P : key -> V -> Prop) (c : color)
                   (l r : tree V) (k : key) (v : V),
    ForallT P l ->
    ForallT P r ->
    P k v ->
    ForallT P (balance c l k v r).
Proof.
  intros V P c l r k v Hl Hr Hk. unfold balance.
  repeat
    match goal with
    | H : ForallT _ (T _ _ _ _ _) |- _ => destruct H as [? [? ?] ]
    | |- ForallT _ (match ?c with Red => _ | Black => _ end) => destruct c
    | |- ForallT _ (match ?t with E => _ | T _ _ _ _ _ => _ end) => destruct t
    | |- ForallT _ (T _ _ _ _ _) => repeat split
    end;
    auto.
Qed.

(* ins 保留任意逐结点谓词 P。对 t 归纳，无需情形自动化。 *)
Lemma insP : forall (V : Type) (P : key -> V -> Prop) (t : tree V)
               (k : key) (v : V),
    ForallT P t ->
    P k v ->
    ForallT P (ins k v t).
Proof.
  intros V P t. induction t as [ | c l IHl k' v' r IHr]; intros k v H HP.
  - simpl. repeat split; auto.
  - simpl in H. destruct H as [Hk [Hl Hr]]. simpl.
    destruct (Nat.ltb k k') eqn:E1.
    + apply balanceP; [apply IHl; auto | auto | auto].
    + destruct (Nat.ltb k' k) eqn:E2.
      * apply balanceP; [auto | apply IHr; auto | auto].
      * repeat split; auto.
Qed.

Lemma ins_BST : forall (V : Type) (t : tree V) (k : key) (v : V),
    BST t ->
    BST (ins k v t).
Proof.
  intros V t. induction t as [ | c l IHl k' v' r IHr]; intros k v H.
  - simpl. repeat constructor.
  - inversion H; subst. simpl.
    destruct (Nat.ltb k k') eqn:E1.
    + apply Nat.ltb_lt in E1.
      apply balance_BST.
      * apply insP; assumption.
      * assumption.
      * apply IHl; assumption.
      * assumption.
    + destruct (Nat.ltb k' k) eqn:E2.
      * apply Nat.ltb_lt in E2.
        apply balance_BST.
        -- assumption.
        -- apply insP; assumption.
        -- assumption.
        -- apply IHr; assumption.
      * apply Nat.ltb_ge in E1. apply Nat.ltb_ge in E2.
        assert (Hkk : k = k') by lia. subst k'.
        constructor; assumption.
Qed.

Theorem insert_BST : forall (V : Type) (t : tree V) (v : V) (k : key),
    BST t ->
    BST (insert k v t).
Proof.
  intros V t v k H. unfold insert.
  assert (Hins : BST (ins k v t)) by (apply ins_BST; assumption).
  destruct (ins k v t) as [ | c' l' k' v' r'] eqn:Ei.
  - exfalso. exact (ins_not_E V k v t Ei).
  - inversion Hins; subst. constructor; assumption.
Qed.

Print Assumptions insert_BST.

End Ex41Redblack.
