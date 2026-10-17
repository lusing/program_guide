(* ============================================================
   52 证明无关性与驴句 —— Coq（罗朝晖书 3.5 + 5.3.3）
   ① 证明无关性 PI（书 5.3.2 的 Axiom；此处用 Coq 标准库）：
      同一命题的证明相等——|P| ≤ 1（式 3.116）
   ② 计数问题：MLTT 用 Σ 兼任存在量词导致 |ΣΣ 型| 计数崩
      （式 3.122–3.124：|F_D| ≥ 19 ≠ 10）——UTT 以 Σ(子集)
      + ∃(弱和) 分工修复（式 3.126）
   ③ Most 的书式定义（定义 3.2 / 书 5.3.3 代码：Fin + inj）
   ④ 驴句双读法（式 3.125 vs 3.129）：三农夫有限模型上
      **全称读法假、存在读法真**——同句两义，机器判决
   ============================================================ *)

Require Import ProofIrrelevance.
Require Import Lia.

(* ---- ① 证明无关性（书式 PI / 3.116）---------------------- *)
Check proof_irrelevance :
  forall (P : Prop) (p q : P), p = q.
(* 直观：任一命题要么空、要么单点——计数与证明方式无关 *)

(* ---- ② 三农夫模型（计数问题的最小戏台）------------------
   own：f1 养两头驴（d1 d2）、f2 养一头（d3）、f3 不养；
   beat：f1 揍 d1（不揍 d2）、f2 揍 d3。 *)
Inductive F3 : Type := f1 | f2 | f3.
Inductive D3 : Type := d1 | d2 | d3.

Definition own (x : F3) (y : D3) : Prop :=
  match x, y with
  | f1, d1 => True | f1, d2 => True
  | f2, d3 => True
  | _, _ => False
  end.
Definition beat (x : F3) (y : D3) : Prop :=
  match x, y with
  | f1, d1 => True
  | f2, d3 => True
  | _, _ => False
  end.

(* MLTT 式：ΣΣ 兼任存在量词（式 3.122 的 F_D） *)
Record FD := mkFD { fd_f :> F3 ; fd_d :> D3 ; own_prf : own fd_f fd_d }.
(* UTT 式：Σ(子集) + ∃(弱和)（式 3.126 的 F1） *)
Record F1 := mkF1 { farmer :> F3 ; own_ex : exists y : D3, own farmer y }.
(* 驴句回指载体：D_owned x = Σy:Donkey.own(x,y)（式 3.125 用） *)
Record D_owned (x : F3) := mkDo { donkey :> D3 ; d_own : own x donkey }.

(* 计数问题现场：F_D 有 **三个** 对象 *)
Lemma FD_enum : forall z : FD,
  z = mkFD f1 d1 I \/ z = mkFD f1 d2 I \/ z = mkFD f2 d3 I.
Proof.
  intros z. destruct z as [x y Hp].
  destruct x; destruct y; cbv in Hp; try destruct Hp;
    try (left; reflexivity);
    try (right; left; reflexivity);
    try (right; right; reflexivity).
Qed.
(* 而农夫只有两个养驴——|F_D| = 3 ≠ 2：
   多出来的 (f1,d2) 是「f1 拥有 d2 的证明」作祟 *)
Lemma FD_three_distinct :
  mkFD f1 d1 I <> mkFD f1 d2 I /\ mkFD f1 d1 I <> mkFD f2 d3 I.
Proof. split; intros H; discriminate H. Qed.

(* PI 修复：F1 的两个对象只要农夫相同就相等——|F1| = 2 *)
Lemma F1_pi : forall z z' : F1, farmer z = farmer z' -> z = z'.
Proof.
  intros z z' Heq. destruct z as [a Ha]. destruct z' as [b Hb].
  simpl in Heq. subst b. f_equal.
  apply proof_irrelevance.
Qed.
(*   ——「如何证明拥有」不再计入计数（3.117：|Σx:A.Q(x)| = |A|） *)

(* ---- ③ Most 的书式定义（定义 3.2 / 书 5.3.3 代码）-------- *)
Inductive Fin : nat -> Type :=
| f_zero : forall n : nat, Fin (S n)
| f_succ : forall n : nat, Fin n -> Fin (S n).

Definition inj {A B : Type} (f : A -> B) : Prop :=
  forall x y : A, f x = f y -> x = y.

Definition card_F3 : nat := 3.
Definition Most (P : F3 -> Prop) : Prop :=
  exists k : nat, k > Nat.div card_F3 2
    /\ exists f : Fin k -> F3,
        inj f /\ forall x : Fin k, P (f x).
(*   ——F3 中**多于半数**的对象满足 P（书：多数农夫……） *)

(* Most ⇒ 至少两个不同的对象满足 P（k ≥ 2 的 Fin 取前两位） *)
Lemma most_two : forall P : F3 -> Prop, Most P ->
  exists a b : F3, a <> b /\ P a /\ P b.
Proof.
  intros P [k [Hk [f [Hinj Hall]]]].
  destruct k as [|[|[|m]]]; unfold card_F3 in Hk; cbn in Hk; try lia.
  - exists (f (f_zero 1)), (f (f_succ 1 (f_zero 0))).
    split; [ | split ].
    + intros Heq. apply Hinj in Heq. discriminate.
    + exact (Hall _).
    + exact (Hall _).
  - exists (f (f_zero (S (S m)))), (f (f_succ (S (S m)) (f_zero (S m)))).
    split; [ | split ].
    + intros Heq. apply Hinj in Heq. discriminate.
    + exact (Hall _).
    + exact (Hall _).
Qed.

(* ---- ④ 驴句双读法（式 3.125 vs 3.129）--------------------
   「多数有毛驴的农夫都揍它」——「它」的全称/存在两读：
     全称读法 P_u：揍**每一头**自己养的驴（3.127）
     存在读法 P_e：揍**某头**自己养的驴（3.128）
   F1 的两个成员：f1（养 d1 d2、只揍 d1）与 f2（养 d3、揍）。
   P_u：f1 假、f2 真 → Most 假；P_e：两者皆真 → Most 真。 *)

Definition P_u (z : F1) : Prop :=
  forall y' : D_owned (farmer z), beat (farmer z) (donkey (farmer z) y').
Definition P_e (z : F1) : Prop :=
  exists y' : D_owned (farmer z), beat (farmer z) (donkey (farmer z) y').

(* F1 的农夫只有 f1 或 f2（f3 不养驴，own_ex 为空） *)
Lemma F1_farmer_cases : forall z : F1, farmer z = f1 \/ farmer z = f2.
Proof.
  intros z. destruct z as [x Hx]. destruct x.
  - left. reflexivity.
  - right. reflexivity.
  - destruct Hx as [y Hy]. destruct y; cbv in Hy; destruct Hy.
Qed.

Lemma Pu_f1 : forall p : (exists y : D3, own f1 y), ~ P_u (mkF1 f1 p).
Proof.
  intros p H. pose proof (H (mkDo f1 d2 I)) as Hb. cbv in Hb. exact Hb.
Qed.   (* f1 养 d2 却不揍 d2：全称读法在 f1 上破产 *)

Theorem universal_Most_false :
  ~ Most (fun x => exists z : F1, farmer z = x /\ P_u z).
Proof.
  intros H. destruct (most_two _ H) as [a [b [Hab [Ha Hb]]]].
  destruct Ha as [za [Hza Hua]]. destruct Hb as [zb [Hzb Hub]].
  destruct (F1_farmer_cases za) as [C1|C1];
    destruct (F1_farmer_cases zb) as [C2|C2];
    rewrite <- Hza, <- Hzb in Hab.
  - congruence.                        (* f1 ≠ f1 自相矛盾 *)
  - exfalso. unfold P_u in Hua. rewrite C1 in Hua.
    pose proof (Hua (mkDo f1 d2 I)) as Hc. cbv in Hc. exact Hc.
      (* f1 养 d2 却不揍 d2：全称读法在 f1 上破产 *)
  - exfalso. unfold P_u in Hub. rewrite C2 in Hub.
    pose proof (Hub (mkDo f1 d2 I)) as Hc. cbv in Hc. exact Hc.
  - congruence.                        (* f2 ≠ f2 自相矛盾 *)
Qed.

(* 三元素版「过半」：至少两个不同对象满足 P——书定义 3.2 在
   |A| = 3 时的等价形（Most ⟹ Most3 由 most_two 给出；反向须
   构造 Fin 2 见证，其依赖等式消解需 Fin 1 唯一性辅助引理，
   教学从略）。 *)
Definition Most3 (P : F3 -> Prop) : Prop :=
  exists a b : F3, a <> b /\ P a /\ P b.

Lemma Most_Most3 : forall P : F3 -> Prop, Most P -> Most3 P.
Proof. exact most_two. Qed.

Theorem existential_Most3_true : Most3 (fun x =>
  exists z : F1, farmer z = x /\ P_e z).
Proof.
  exists f1, f2. split; [discriminate | split].
  - exists (mkF1 f1 (ex_intro _ d1 I)). split; [reflexivity | ].
    exists (mkDo f1 d1 I). exact I.
  - exists (mkF1 f2 (ex_intro _ d3 I)). split; [reflexivity | ].
    exists (mkDo f2 d3 I). exact I.
Qed.

(* 双读法分道扬镳：同一句话「多数有毛驴的农夫都揍它」——
   全称读法（3.127）在书式 Most 下**假**、存在读法（3.128）
   在其等价形下**真**：同一句子两个真值，机器判决。信用卡句
   （式 3.130/3.131）只取存在读法——结构同 P_e。 *)

(* ---- 收束：势的直觉（定义 3.1 的可计算注）---------------- *)
Definition countF (P : F3 -> bool) : nat :=
  (if P f1 then 1 else 0) + (if P f2 then 1 else 0)
  + (if P f3 then 1 else 0).
Definition owns (x : F3) : bool :=
  match x with f1 => true | f2 => true | f3 => false end.
Compute (countF owns).    (* = 2：养驴的农夫恰两人——|F1| 的
                              可计算面（书 81 页势 |·| 的对照） *)
