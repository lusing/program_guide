(* ex35 —— FOL 语义表列（Ben-Ari 3e §7.5-7.6）
   命题层（07 章）的 α/β 全部照用；新行李是量词的两条规则：
     γ（不消耗）：T-∀xA(x) / F-∃xA(x) 以分支常量实例化，公式留在分支上；
     δ（消耗）  ：T-∃xA(x) / F-∀xA(x) 以**新鲜常量**实例化（Ben-Ari 的
                  a_{f,i} 纪律——复用常量会虚关分支，见 docs/35 现场走查）。
   双层机器件：
     算法层 tsearch —— fuel 搜索：全闭 = None（不可满足），开饱和 = Some
       （读出 Herbrand 原子表）；γ-实例以（公式体×常量）done 表防重演；
     理论层 tclo   —— 闭表列的**推导证明对象**（演算作为数据），旗舰
       tclo_unsat = Ben-Ari 定理 7.42：闭表列 ⟹ 在一切抽象解释下不可满足。 *)

From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.

(* ============ 语法：谓词 + 常量（函数符号 3e ch9 才登场） ============ *)

Inductive ftm : Type :=
| fV : nat -> ftm          (* 变元 x_i *)
| fC : nat -> ftm.         (* 常量 a_i *)

Inductive fform : Type :=
| fP   : nat -> list ftm -> fform
| fNot : fform -> fform
| fAnd : fform -> fform -> fform
| fOr  : fform -> fform -> fform
| fImp : fform -> fform -> fform
| fAll : nat -> fform -> fform
| fEx  : nat -> fform -> fform.

(* 实例化：变元换成常量。常量不会被量词捕获——只需在同名量词下不动。 *)
Fixpoint tsub (t : ftm) (x a : nat) : ftm :=
  match t with
  | fV y => if Nat.eqb y x then fC a else fV y
  | fC _ => t
  end.

Fixpoint fsub (f : fform) (x a : nat) : fform :=
  match f with
  | fP p ts => fP p (map (fun t => tsub t x a) ts)
  | fNot g => fNot (fsub g x a)
  | fAnd g h => fAnd (fsub g x a) (fsub h x a)
  | fOr  g h => fOr  (fsub g x a) (fsub h x a)
  | fImp g h => fImp (fsub g x a) (fsub h x a)
  | fAll y g => if Nat.eqb y x then f else fAll y (fsub g x a)
  | fEx  y g => if Nat.eqb y x then f else fEx y (fsub g x a)
  end.

Fixpoint constsT (ts : list ftm) : list nat :=
  match ts with
  | [] => []
  | fC c :: ts' => c :: constsT ts'
  | fV _ :: ts' => constsT ts'
  end.

Fixpoint constsF (f : fform) : list nat :=
  match f with
  | fP _ ts => constsT ts
  | fNot g => constsF g
  | fAnd g h => constsF g ++ constsF h
  | fOr  g h => constsF g ++ constsF h
  | fImp g h => constsF g ++ constsF h
  | fAll _ g => constsF g
  | fEx  _ g => constsF g
  end.

Lemma constsT_In : forall ts c, In c (constsT ts) <-> In (fC c) ts.
Proof.
  induction ts as [| t ts' IH]; intros c; simpl.
  - split; contradiction.
  - destruct t as [v | k]; simpl.
    + split; intro H.
      * right. apply IH. exact H.
      * destruct H as [He | Hin]; [discriminate He | apply IH; exact Hin].
    + split; intro H.
      * destruct H as [-> | Hin]; [left; reflexivity | right; apply IH; exact Hin].
      * destruct H as [He | Hin].
        -- injection He as ->. left. reflexivity.
        -- right. apply IH. exact Hin.
Qed.

(* ============ 语义：抽象解释（域为记录参数 D；变元/常量指派分开） ============ *)

Record interp (D : Type) : Type := MkI {
  iasg : nat -> D;                 (* 变元指派 *)
  icon : nat -> D;                 (* 常量指派 *)
  ipr  : nat -> list D -> bool     (* 谓词指派 *)
}.
Arguments iasg {D}. Arguments icon {D}. Arguments ipr {D}.

Definition setV {D} (I : interp D) (x : nat) (d : D) : interp D :=
  {| iasg := fun y => if Nat.eqb y x then d else iasg I y;
     icon := icon I; ipr := ipr I |}.

Definition setC {D} (I : interp D) (c : nat) (d : D) : interp D :=
  {| iasg := iasg I;
     icon := fun k => if Nat.eqb k c then d else icon I k; ipr := ipr I |}.

Fixpoint tsem {D} (I : interp D) (t : ftm) : D :=
  match t with
  | fV y => iasg I y
  | fC c => icon I c
  end.

Inductive sign : Type := T | F.
Definition entry : Type := (sign * fform)%type.
Definition branch : Type := list entry.

(* 带符号语义：符号直接决定连接词的合取/析取形状（表列形状） *)
Fixpoint fsat {D} (I : interp D) (s : sign) (f : fform) {struct f} : Prop :=
  match s, f with
  | T, fP p ts => ipr I p (map (tsem I) ts) = true
  | F, fP p ts => ipr I p (map (tsem I) ts) = false
  | T, fAnd a b => fsat I T a /\ fsat I T b
  | F, fAnd a b => fsat I F a \/ fsat I F b
  | T, fOr a b  => fsat I T a \/ fsat I T b
  | F, fOr a b  => fsat I F a /\ fsat I F b
  | T, fImp a b => fsat I F a \/ fsat I T b
  | F, fImp a b => fsat I T a /\ fsat I F b
  | T, fNot a   => fsat I F a
  | F, fNot a   => fsat I T a
  | T, fAll x a => forall d : D, fsat (setV I x d) T a
  | F, fAll x a => exists d : D, fsat (setV I x d) F a
  | T, fEx x a  => exists d : D, fsat (setV I x d) T a
  | F, fEx x a  => forall d : D, fsat (setV I x d) F a
  end.

Definition satE {D} (I : interp D) (en : entry) : Prop := fsat I (fst en) (snd en).
Definition satB {D} (I : interp D) (B : branch) : Prop := forall en, In en B -> satE I en.

(* ============ 主引理一：逐点一致下的外延性 ============ *)

Lemma fsat_ext : forall (D : Type) f (I I' : interp D) (s : sign),
  (forall k, iasg I k = iasg I' k) ->
  (forall k, In k (constsF f) -> icon I k = icon I' k) ->
  (forall p l, ipr I p l = ipr I' p l) ->
  fsat I s f <-> fsat I' s f.
Proof.
  intros D f.
  induction f as [p ts | a IH | a IHa b IHb | a IHa b IHb | a IHa b IHb | x a IH | x a IH];
    intros I I' s Has Hcon Hpr.
  - (* 原子 *)
    assert (Hmap : map (tsem I) ts = map (tsem I') ts).
    { apply map_ext_in. intros t Ht. destruct t as [v | c]; simpl.
      - apply Has.
      - apply Hcon. simpl. apply constsT_In. exact Ht. }
    destruct s; simpl; rewrite Hmap, (Hpr p (map (tsem I') ts));
      split; intro Hb; exact Hb.
  - assert (HiF := IH I I' F Has Hcon Hpr).
    assert (HiT := IH I I' T Has Hcon Hpr).
    destruct s; simpl; tauto.
  - specialize (IHa I I' s Has
                 (fun k Hk => Hcon k (in_or_app _ _ _ (or_introl Hk))) Hpr).
    specialize (IHb I I' s Has
                 (fun k Hk => Hcon k (in_or_app _ _ _ (or_intror Hk))) Hpr).
    destruct s; simpl in *; tauto.
  - specialize (IHa I I' s Has
                 (fun k Hk => Hcon k (in_or_app _ _ _ (or_introl Hk))) Hpr).
    specialize (IHb I I' s Has
                 (fun k Hk => Hcon k (in_or_app _ _ _ (or_intror Hk))) Hpr).
    destruct s; simpl in *; tauto.
  - (* fImp：两分支翻号——四个方向都备好 *)
    assert (HaF := IHa I I' F Has
                 (fun k Hk => Hcon k (in_or_app _ _ _ (or_introl Hk))) Hpr).
    assert (HaT := IHa I I' T Has
                 (fun k Hk => Hcon k (in_or_app _ _ _ (or_introl Hk))) Hpr).
    assert (HbF := IHb I I' F Has
                 (fun k Hk => Hcon k (in_or_app _ _ _ (or_intror Hk))) Hpr).
    assert (HbT := IHb I I' T Has
                 (fun k Hk => Hcon k (in_or_app _ _ _ (or_intror Hk))) Hpr).
    destruct s; simpl; tauto.
  - assert (Hsv : forall d k, iasg (setV I x d) k = iasg (setV I' x d) k).
    { intros d k. unfold setV; simpl. destruct (Nat.eqb_spec k x) as [-> | _];
        [reflexivity | apply Has]. }
    destruct s; simpl.
    + (* T-∀：两侧都是 ∀ *)
      split; intros H d.
      * exact (proj1 (IH (setV I x d) (setV I' x d) T (Hsv d)
                       (fun k Hk => Hcon k Hk) Hpr) (H d)).
      * exact (proj2 (IH (setV I x d) (setV I' x d) T (Hsv d)
                       (fun k Hk => Hcon k Hk) Hpr) (H d)).
    + (* F-∀：两侧都是 ∃ *)
      split; intros H; destruct H as [d Hd]; exists d.
      * exact (proj1 (IH (setV I x d) (setV I' x d) F (Hsv d)
                       (fun k Hk => Hcon k Hk) Hpr) Hd).
      * exact (proj2 (IH (setV I x d) (setV I' x d) F (Hsv d)
                       (fun k Hk => Hcon k Hk) Hpr) Hd).
  - assert (Hsv : forall d k, iasg (setV I x d) k = iasg (setV I' x d) k).
    { intros d k. unfold setV; simpl. destruct (Nat.eqb_spec k x) as [-> | _];
        [reflexivity | apply Has]. }
    destruct s; simpl.
    + (* T-∃ *)
      split; intros H; destruct H as [d Hd]; exists d.
      * exact (proj1 (IH (setV I x d) (setV I' x d) T (Hsv d)
                       (fun k Hk => Hcon k Hk) Hpr) Hd).
      * exact (proj2 (IH (setV I x d) (setV I' x d) T (Hsv d)
                       (fun k Hk => Hcon k Hk) Hpr) Hd).
    + (* F-∃ *)
      split; intros H d.
      * exact (proj1 (IH (setV I x d) (setV I' x d) F (Hsv d)
                       (fun k Hk => Hcon k Hk) Hpr) (H d)).
      * exact (proj2 (IH (setV I x d) (setV I' x d) F (Hsv d)
                       (fun k Hk => Hcon k Hk) Hpr) (H d)).
Qed.

(* setV 的两条换名引理 *)
Lemma setV_setV_same : forall {D : Type} (I : interp D) x (c d : D) (s : sign) (f : fform),
  fsat (setV (setV I x c) x d) s f <-> fsat (setV I x d) s f.
Proof.
  intros. apply fsat_ext.
  - unfold setV; simpl. intros k.
    destruct (Nat.eqb_spec k x) as [-> | _]; reflexivity.
  - unfold setV; simpl. intros k Hk.
    destruct (Nat.eqb_spec k x) as [-> | _]; reflexivity.
  - reflexivity.
Qed.

Lemma setV_setV_comm : forall {D : Type} (I : interp D) x y (c d : D) (s : sign) (f : fform),
  x <> y ->
  fsat (setV (setV I y d) x c) s f <-> fsat (setV (setV I x c) y d) s f.
Proof.
  intros D I x y c d s f Hne. apply fsat_ext.
  - unfold setV; simpl. intros k.
    destruct (Nat.eqb k x) eqn:E1; destruct (Nat.eqb k y) eqn:E2;
      try reflexivity.
    exfalso. apply Hne.
    apply Nat.eqb_eq in E1. apply Nat.eqb_eq in E2. congruence.
  - unfold setV; simpl. intros k Hk. reflexivity.
  - reflexivity.
Qed.

(* ============ 主引理二：代入引理（γ/δ 正确性的心脏） ============ *)

Lemma tsub_sem : forall t {D} (I : interp D) x a,
  tsem I (tsub t x a) = tsem (setV I x (icon I a)) t.
Proof.
  induction t as [y | c]; intros D I x a; simpl.
  - destruct (Nat.eqb_spec y x) as [-> | _]; reflexivity.
  - reflexivity.
Qed.

Lemma subst_sem : forall (D : Type) f (I : interp D) (s : sign) (x a : nat),
  fsat I s (fsub f x a) <-> fsat (setV I x (icon I a)) s f.
Proof.
  intros D f.
  induction f as [p ts | g IH | g IHg h IHh | g IHg h IHh | g IHg h IHh | y g IH | y g IH];
    intros I s x a.
  - simpl. (* 原子 *)
    assert (Hmap : map (tsem I) (map (fun t => tsub t x a) ts)
                 = map (tsem (setV I x (icon I a))) ts).
    { rewrite map_map. apply map_ext. intros t.
      first [ apply tsub_sem | symmetry; apply tsub_sem ]. }
    destruct s; simpl; rewrite Hmap; split; intro Hb; exact Hb.
  - simpl. assert (HiF := IH I F x a). assert (HiT := IH I T x a).
    destruct s; simpl; tauto.
  - simpl. specialize (IHg I s x a). specialize (IHh I s x a).
    destruct s; simpl in *; tauto.
  - simpl. specialize (IHg I s x a). specialize (IHh I s x a).
    destruct s; simpl in *; tauto.
  - simpl. assert (HgF := IHg I F x a). assert (HgT := IHg I T x a).
    assert (HhF := IHh I F x a). assert (HhT := IHh I T x a).
    destruct s; simpl in *; tauto.
  - (* fAll *)
    simpl. destruct (Nat.eqb_spec y x) as [Heq | Hne].
    + subst y. destruct s; simpl.
      * split; intros H d.
        -- exact (proj2 (setV_setV_same I x (icon I a) d T g) (H d)).
        -- exact (proj1 (setV_setV_same I x (icon I a) d T g) (H d)).
      * split; intros H; destruct H as [d Hd]; exists d.
        -- exact (proj2 (setV_setV_same I x (icon I a) d F g) Hd).
        -- exact (proj1 (setV_setV_same I x (icon I a) d F g) Hd).
    + assert (Hxy : x <> y) by congruence.
      destruct s; simpl.
      * split; intros H e.
        -- exact (proj1 (setV_setV_comm I x y (icon I a) e T g Hxy)
                   (proj1 (IH (setV I y e) T x a) (H e))).
        -- exact (proj2 (IH (setV I y e) T x a)
                   (proj2 (setV_setV_comm I x y (icon I a) e T g Hxy) (H e))).
      * split; intros H; destruct H as [e He]; exists e.
        -- exact (proj1 (setV_setV_comm I x y (icon I a) e F g Hxy)
                   (proj1 (IH (setV I y e) F x a) He)).
        -- exact (proj2 (IH (setV I y e) F x a)
                   (proj2 (setV_setV_comm I x y (icon I a) e F g Hxy) He)).
  - (* fEx *)
    simpl. destruct (Nat.eqb_spec y x) as [Heq | Hne].
    + subst y. destruct s; simpl.
      * split; intros H; destruct H as [d Hd]; exists d.
        -- exact (proj2 (setV_setV_same I x (icon I a) d T g) Hd).
        -- exact (proj1 (setV_setV_same I x (icon I a) d T g) Hd).
      * split; intros H d.
        -- exact (proj2 (setV_setV_same I x (icon I a) d F g) (H d)).
        -- exact (proj1 (setV_setV_same I x (icon I a) d F g) (H d)).
    + assert (Hxy : x <> y) by congruence.
      destruct s; simpl.
      * split; intros H; destruct H as [e He]; exists e.
        -- exact (proj1 (setV_setV_comm I x y (icon I a) e T g Hxy)
                   (proj1 (IH (setV I y e) T x a) He)).
        -- exact (proj2 (IH (setV I y e) T x a)
                   (proj2 (setV_setV_comm I x y (icon I a) e T g Hxy) He)).
      * split; intros H e.
        -- exact (proj1 (setV_setV_comm I x y (icon I a) e F g Hxy)
                   (proj1 (IH (setV I y e) F x a) (H e))).
        -- exact (proj2 (IH (setV I y e) F x a)
                   (proj2 (setV_setV_comm I x y (icon I a) e F g Hxy) (H e))).
Qed.

(* ============ 理论层：闭表列推导即数据 ============ *)

Fixpoint constsB (B : branch) : list nat :=
  match B with
  | [] => []
  | (_, f) :: B' => constsF f ++ constsB B'
  end.

Inductive tclo : branch -> Prop :=
(* 闭：互补原子对 *)
| tcClose : forall B p ts,
    In (T, fP p ts) B -> In (F, fP p ts) B -> tclo B
(* 聚焦：把任一条款换到表头（推导的次序自由——Ben-Ari 的「first applicable
   rule」不挑位置；可靠性代价只是成员关系重排） *)
| tcSwap : forall B1 en B2,
    tclo (en :: (B1 ++ B2)) -> tclo (B1 ++ en :: B2)
(* α 型（一前提） *)
| tcAndT : forall B a b, tclo ((T,a)::(T,b)::B) -> tclo ((T, fAnd a b)::B)
| tcOrF  : forall B a b, tclo ((F,a)::(F,b)::B) -> tclo ((F, fOr a b)::B)
| tcImpF : forall B a b, tclo ((T,a)::(F,b)::B) -> tclo ((F, fImp a b)::B)
| tcNotT : forall B a, tclo ((F,a)::B) -> tclo ((T, fNot a)::B)
| tcNotF : forall B a, tclo ((T,a)::B) -> tclo ((F, fNot a)::B)
(* β 型（两前提） *)
| tcAndF : forall B a b,
    tclo ((F,a)::B) -> tclo ((F,b)::B) -> tclo ((F, fAnd a b)::B)
| tcOrT  : forall B a b,
    tclo ((T,a)::B) -> tclo ((T,b)::B) -> tclo ((T, fOr a b)::B)
| tcImpT : forall B a b,
    tclo ((F,a)::B) -> tclo ((T,b)::B) -> tclo ((T, fImp a b)::B)
(* γ 型（不消耗：T-∀ / F-∃，用分支常量实例化；γ 留在分支上） *)
| tcGT : forall B x a c,
    tclo ((T, fsub a x c)::(T, fAll x a)::B) -> tclo ((T, fAll x a)::B)
| tcGF : forall B x a c,
    tclo ((F, fsub a x c)::(F, fEx x a)::B) -> tclo ((F, fEx x a)::B)
(* δ 型（消耗：T-∃ / F-∀，用新鲜常量；新鲜性侧条件是推导数据的一部分） *)
| tcDT : forall B x a c,
    ~ In c (constsF (fEx x a) ++ constsB B) ->
    tclo ((T, fsub a x c)::B) -> tclo ((T, fEx x a)::B)
| tcDF : forall B x a c,
    ~ In c (constsF (fAll x a) ++ constsB B) ->
    tclo ((F, fsub a x c)::B) -> tclo ((F, fAll x a)::B).

Lemma constsB_In : forall B en, In en B ->
  forall c, In c (constsF (snd en)) -> In c (constsB B).
Proof.
  induction B as [| e B' IH]; intros en' Hin c Hc.
  - contradiction.
  - destruct e as [sg fm]. destruct Hin as [Heq | Hin].
    + subst en'. simpl. apply in_or_app. left. exact Hc.
    + simpl. apply in_or_app. right. apply (IH en' Hin c Hc).
Qed.

(* ============ 旗舰：tclo_unsat（Ben-Ari 定理 7.42） ============ *)

Theorem tclo_unsat : forall B, tclo B -> forall {D} (I : interp D), ~ satB I B.
Proof.
  intros B HT.
  induction HT as
    [B p ts H H0
    |B1 en B2 tp IHT
    |B a b tp IHT
    |B a b tp IHT
    |B a b tp IHT
    |B a tp IHT
    |B a tp IHT
    |B a b tp1 IHT1 tp2 IHT2
    |B a b tp1 IHT1 tp2 IHT2
    |B a b tp1 IHT1 tp2 IHT2
    |B x a c tp IHT
    |B x a c tp IHT
    |B x a c Hfr tp IHT
    |B x a c Hfr tp IHT];
  intros D I Hsat.
  (* 闭：同一原子两侧真值对撞 *)
  - pose proof (Hsat (T, fP p ts) H) as HT. simpl in HT.
    pose proof (Hsat (F, fP p ts) H0) as HF. simpl in HF.
    congruence.
  (* 聚焦：成员重排保满足 *)
  - apply (IHT D I). intros en' [Heq | Hin].
    + subst en'. apply (Hsat en). apply in_or_app. right. left. reflexivity.
    + apply in_app_or in Hin. destruct Hin as [Hb1 | Hb2].
      * apply (Hsat en'). apply in_or_app. left. exact Hb1.
      * apply (Hsat en'). apply in_or_app. right. right. exact Hb2.
  (* α 五条 *)
  - apply (IHT D I). intros en [Heq | [Heq | Hin]].
    + subst en. simpl. destruct (Hsat (T, fAnd a b) (or_introl eq_refl)) as [H1 _].
      exact H1.
    + subst en. simpl. destruct (Hsat (T, fAnd a b) (or_introl eq_refl)) as [_ H2].
      exact H2.
    + apply (Hsat en). right. exact Hin.
  - apply (IHT D I). intros en [Heq | [Heq | Hin]].
    + subst en. simpl. destruct (Hsat (F, fOr a b) (or_introl eq_refl)) as [H1 _].
      exact H1.
    + subst en. simpl. destruct (Hsat (F, fOr a b) (or_introl eq_refl)) as [_ H2].
      exact H2.
    + apply (Hsat en). right. exact Hin.
  - apply (IHT D I). intros en [Heq | [Heq | Hin]].
    + subst en. simpl. destruct (Hsat (F, fImp a b) (or_introl eq_refl)) as [H1 _].
      exact H1.
    + subst en. simpl. destruct (Hsat (F, fImp a b) (or_introl eq_refl)) as [_ H2].
      exact H2.
    + apply (Hsat en). right. exact Hin.
  - apply (IHT D I). intros en [Heq | Hin].
    + subst en. pose proof (Hsat (T, fNot a) (or_introl eq_refl)) as H1.
      simpl in H1. exact H1.
    + apply (Hsat en). right. exact Hin.
  - apply (IHT D I). intros en [Heq | Hin].
    + subst en. pose proof (Hsat (F, fNot a) (or_introl eq_refl)) as H1.
      simpl in H1. exact H1.
    + apply (Hsat en). right. exact Hin.
  (* β 三条 *)
  - pose proof (Hsat (F, fAnd a b) (or_introl eq_refl)) as Hd. simpl in Hd.
    destruct Hd as [Ha | Hb].
    + apply (IHT1 D I). intros en [Heq | Hin].
      * subst en. exact Ha.
      * apply (Hsat en). right. exact Hin.
    + apply (IHT2 D I). intros en [Heq | Hin].
      * subst en. exact Hb.
      * apply (Hsat en). right. exact Hin.
  - pose proof (Hsat (T, fOr a b) (or_introl eq_refl)) as Hd. simpl in Hd.
    destruct Hd as [Ha | Hb].
    + apply (IHT1 D I). intros en [Heq | Hin].
      * subst en. exact Ha.
      * apply (Hsat en). right. exact Hin.
    + apply (IHT2 D I). intros en [Heq | Hin].
      * subst en. exact Hb.
      * apply (Hsat en). right. exact Hin.
  - pose proof (Hsat (T, fImp a b) (or_introl eq_refl)) as Hd. simpl in Hd.
    destruct Hd as [Ha | Hb].
    + apply (IHT1 D I). intros en [Heq | Hin].
      * subst en. exact Ha.
      * apply (Hsat en). right. exact Hin.
    + apply (IHT2 D I). intros en [Heq | Hin].
      * subst en. exact Hb.
      * apply (Hsat en). right. exact Hin.
  (* γ-T：∀ 的实例在任何常量指派下成立 *)
  - apply (IHT D I). intros en [Heq | [Heq | Hin]].
    + subst en. simpl.
      pose proof (Hsat (T, fAll x a) (or_introl eq_refl)) as HF. simpl in HF.
      exact (proj2 (subst_sem D a I T x c) (HF (icon I c))).
    + subst en. exact (Hsat (T, fAll x a) (or_introl eq_refl)).
    + apply (Hsat en). right. exact Hin.
  (* γ-F *)
  - apply (IHT D I). intros en [Heq | [Heq | Hin]].
    + subst en. simpl.
      pose proof (Hsat (F, fEx x a) (or_introl eq_refl)) as HF. simpl in HF.
      exact (proj2 (subst_sem D a I F x c) (HF (icon I c))).
    + subst en. exact (Hsat (F, fEx x a) (or_introl eq_refl)).
    + apply (Hsat en). right. exact Hin.
  (* δ-T：∃ 见证 d 搬到新鲜常量 c；c 对 B 中公式隐形 *)
  - pose proof (Hsat (T, fEx x a) (or_introl eq_refl)) as Hex. simpl in Hex.
    destruct Hex as [d Hd].
    assert (Hfa : ~ In c (constsF a)).
    { intro Hc. apply Hfr. apply in_or_app. left. simpl. exact Hc. }
    assert (HfB : forall en, In en B -> ~ In c (constsF (snd en))).
    { intros en Hin Hc. apply Hfr. apply in_or_app. right.
      apply (constsB_In B en Hin c Hc). }
    apply (IHT D (setC I c d)). intros en [Heq | Hin].
    + subst en. unfold satE. simpl.
      apply (proj2 (subst_sem D a (setC I c d) T x c)).
      replace (icon (setC I c d) c) with d
        by (unfold setC; simpl; rewrite Nat.eqb_refl; reflexivity).
      assert (Hiff : fsat (setV I x d) T a <-> fsat (setV (setC I c d) x d) T a).
      { apply fsat_ext.
        - unfold setV; simpl. intros k.
          destruct (Nat.eqb_spec k x) as [-> | _]; reflexivity.
        - unfold setV; simpl. intros k Hk.
          destruct (Nat.eqb_spec k c) as [-> | Hkc].
          + exfalso. apply Hfa. exact Hk.
          + reflexivity.
        - reflexivity. }
      exact (proj1 Hiff Hd).
    + pose proof (Hsat en (or_intror Hin)) as HsatE. simpl in HsatE.
      assert (Hiff : satE I en <-> satE (setC I c d) en).
      { unfold satE. apply fsat_ext.
        - reflexivity.
        - intros k Hk. unfold setC; simpl.
          destruct (Nat.eqb_spec k c) as [-> | Hkc].
          + exfalso. apply (HfB en Hin). exact Hk.
          + reflexivity.
        - reflexivity. }
      exact (proj1 Hiff HsatE).
  (* δ-F：F-∀ 的反例见证同样搬家 *)
  - pose proof (Hsat (F, fAll x a) (or_introl eq_refl)) as Hall. simpl in Hall.
    destruct Hall as [d Hd].
    assert (Hfa : ~ In c (constsF a)).
    { intro Hc. apply Hfr. apply in_or_app. left. simpl. exact Hc. }
    assert (HfB : forall en, In en B -> ~ In c (constsF (snd en))).
    { intros en Hin Hc. apply Hfr. apply in_or_app. right.
      apply (constsB_In B en Hin c Hc). }
    apply (IHT D (setC I c d)). intros en [Heq | Hin].
    + subst en. unfold satE. simpl.
      apply (proj2 (subst_sem D a (setC I c d) F x c)).
      replace (icon (setC I c d) c) with d
        by (unfold setC; simpl; rewrite Nat.eqb_refl; reflexivity).
      assert (Hiff : fsat (setV I x d) F a <-> fsat (setV (setC I c d) x d) F a).
      { apply fsat_ext.
        - unfold setV; simpl. intros k.
          destruct (Nat.eqb_spec k x) as [-> | _]; reflexivity.
        - unfold setV; simpl. intros k Hk.
          destruct (Nat.eqb_spec k c) as [-> | Hkc].
          + exfalso. apply Hfa. exact Hk.
          + reflexivity.
        - reflexivity. }
      exact (proj1 Hiff Hd).
    + pose proof (Hsat en (or_intror Hin)) as HsatE. simpl in HsatE.
      assert (Hiff : satE I en <-> satE (setC I c d) en).
      { unfold satE. apply fsat_ext.
        - reflexivity.
        - intros k Hk. unfold setC; simpl.
          destruct (Nat.eqb_spec k c) as [-> | Hkc].
          + exfalso. apply (HfB en Hin). exact Hk.
          + reflexivity.
        - reflexivity. }
      exact (proj1 Hiff HsatE).
Qed.

(* ============ 算法层：fuel 搜索（07 章 tsearch 的量词扩容） ============ *)

Fixpoint eqt (t1 t2 : ftm) : bool :=
  match t1, t2 with
  | fV a, fV b => Nat.eqb a b
  | fC a, fC b => Nat.eqb a b
  | _, _ => false
  end.

Fixpoint eqts (l1 l2 : list ftm) : bool :=
  match l1, l2 with
  | [], [] => true
  | t1 :: l1', t2 :: l2' => eqt t1 t2 && eqts l1' l2'
  | _, _ => false
  end.

Fixpoint eqf (f1 f2 : fform) : bool :=
  match f1, f2 with
  | fP p ts, fP q us => Nat.eqb p q && eqts ts us
  | fNot a, fNot b => eqf a b
  | fAnd a1 b1, fAnd a2 b2 => eqf a1 a2 && eqf b1 b2
  | fOr  a1 b1, fOr  a2 b2 => eqf a1 a2 && eqf b1 b2
  | fImp a1 b1, fImp a2 b2 => eqf a1 a2 && eqf b1 b2
  | fAll x a, fAll y b => Nat.eqb x y && eqf a b
  | fEx  x a, fEx  y b => Nat.eqb x y && eqf a b
  | _, _ => false
  end.

Definition eqs (s1 s2 : sign) : bool :=
  match s1, s2 with T, T => true | F, F => true | _, _ => false end.

Definition eqen (e1 e2 : entry) : bool :=
  match e1, e2 with
  | (s1, f1), (s2, f2) => eqs s1 s2 && eqf f1 f2
  end.

Fixpoint inEntry (B : branch) (en : entry) : bool :=
  match B with
  | [] => false
  | e :: B' => eqen e en || inEntry B' en
  end.

Fixpoint inDone (D : list (fform * nat)) (pr : fform * nat) : bool :=
  match D with
  | [] => false
  | q :: D' => (eqf (fst q) (fst pr) && Nat.eqb (snd q) (snd pr)) || inDone D' pr
  end.

Definition isCT (t : ftm) : bool :=
  match t with fC _ => true | _ => false end.

Definition isGroundLit (en : entry) : bool :=
  match en with
  | (_, fP _ ts) => forallb isCT ts
  | _ => false
  end.

Definition isGammaE (en : entry) : bool :=
  match en with
  | (T, fAll _ _) => true
  | (F, fEx _ _) => true
  | _ => false
  end.

Definition compLit (e1 e2 : entry) : bool :=
  match e1, e2 with
  | (T, fP p ts), (F, fP q us) =>
      Nat.eqb p q && eqts ts us && forallb isCT ts
  | (F, fP p ts), (T, fP q us) =>
      Nat.eqb p q && eqts ts us && forallb isCT ts
  | _, _ => false
  end.

Definition closedB (B : branch) : bool :=
  existsb (fun e1 => existsb (fun e2 => compLit e1 e2) B) B.

(* 挑第一个「非地面文字、非 γ」条款（δ 在内） *)
Fixpoint extract (B : branch) : option (sign * fform * branch) :=
  match B with
  | [] => None
  | en :: B' =>
      if isGroundLit en || isGammaE en then
        match extract B' with
        | Some (s, f, rest) => Some (s, f, en :: rest)
        | None => None
        end
      else Some (fst en, snd en, B')
  end.

Fixpoint freshC (B : branch) : nat :=
  match constsB B with
  | [] => 0
  | l => S (fold_left Nat.max l 0)
  end.

Definition gconsts (B : branch) : list nat :=
  match constsB B with [] => [0] | l => l end.

Definition orelse (o1 o2 : option branch) : option branch :=
  match o1 with Some b => Some b | None => o2 end.

Fixpoint pickC (en : entry) (cs : list nat) (B : branch)
               (D : list (fform * nat)) : option (entry * (fform * nat)) :=
  match cs with
  | [] => None
  | c :: cs' =>
      match en with
      | (T, fAll x a) =>
          if negb (inEntry B (T, fsub a x c)) && negb (inDone D (a, c))
          then Some ((T, fsub a x c), (a, c))
          else pickC en cs' B D
      | (F, fEx x a) =>
          if negb (inEntry B (F, fsub a x c)) && negb (inDone D (a, c))
          then Some ((F, fsub a x c), (a, c))
          else pickC en cs' B D
      | _ => None
      end
  end.

Fixpoint gstepL (Bfull : branch) (B : branch) (cs : list nat)
                (D : list (fform * nat)) : option (entry * (fform * nat)) :=
  match B with
  | [] => None
  | en :: B' =>
      match pickC en cs Bfull D with
      | Some r => Some r
      | None => gstepL Bfull B' cs D
      end
  end.

Definition gstep (B : branch) (cs : list nat) (D : list (fform * nat)) :=
  gstepL B B cs D.

Fixpoint tsearch (fuel : nat) (B : branch) (D : list (fform * nat))
  : option branch :=
  match fuel with
  | 0 => None
  | S k =>
      if closedB B then None else
      match extract B with
      | Some (T, fAnd a b, B') => tsearch k ((T,a)::(T,b)::B') D
      | Some (F, fAnd a b, B') => orelse (tsearch k ((F,a)::B') D)
                                            (tsearch k ((F,b)::B') D)
      | Some (T, fOr a b, B')  => orelse (tsearch k ((T,a)::B') D)
                                            (tsearch k ((T,b)::B') D)
      | Some (F, fOr a b, B')  => tsearch k ((F,a)::(F,b)::B') D
      | Some (T, fImp a b, B') => orelse (tsearch k ((F,a)::B') D)
                                            (tsearch k ((T,b)::B') D)
      | Some (F, fImp a b, B') => tsearch k ((T,a)::(F,b)::B') D
      | Some (T, fNot a, B')   => tsearch k ((F,a)::B') D
      | Some (F, fNot a, B')   => tsearch k ((T,a)::B') D
      | Some (T, fEx x a, B')  => tsearch k ((T, fsub a x (freshC B))::B') D
      | Some (F, fAll x a, B') => tsearch k ((F, fsub a x (freshC B))::B') D
      | Some (_, fAll _ _, _) => None
      | Some (_, fEx _ _, _) => None
      | Some (_, fP _ _, _) => None
      | None =>
          match gstep B (gconsts B) D with
          | Some (inst, pr) => tsearch k (inst :: B) (pr :: D)
          | None => Some B
          end
      end
  end.

(* 读出：开饱和分支的正原子表（Herbrand 模型的谓词解释） *)
Fixpoint constList (ts : list ftm) : option (list nat) :=
  match ts with
  | [] => Some []
  | fC c :: ts' => match constList ts' with Some l => Some (c :: l) | None => None end
  | fV _ :: _ => None
  end.

Fixpoint atomsOf (B : branch) : list (nat * list nat) :=
  match B with
  | [] => []
  | (T, fP p ts) :: B' =>
      match constList ts with
      | Some l => (p, l) :: atomsOf B'
      | None => atomsOf B'
      end
  | _ :: B' => atomsOf B'
  end.

(* ============ 现场例 ============ *)

(* Ben-Ari 例 7.33：∀x(p→q) → (∀x p → ∃x q) —— 有效式，否定闭表列 *)
Definition pX := fP 0 [fV 0].
Definition qX := fP 1 [fV 0].
Definition a733 : fform :=
  fImp (fAll 0 (fImp pX qX)) (fImp (fAll 0 pX) (fEx 0 qX)).

(* 推导证明对象版（演算作为数据）：两条 α 聚焦 + 三次 γ + β 两支各闭 *)
Example tclo_733 : tclo [(F, a733)].
Proof.
  apply tcImpF.
  apply (tcSwap [(T, fAll 0 (fImp pX qX))] (F, fImp (fAll 0 pX) (fEx 0 qX)) []).
  apply tcImpF.
  (* 分支：[(T,∀p), (F,∃q), (T,∀(p→q))] *)
  apply (tcSwap [(T, fAll 0 pX); (F, fEx 0 qX)] (T, fAll 0 (fImp pX qX)) []).
  apply (tcGT _ 0 (fImp pX qX) 0).
  apply tcImpT.
  - (* 左支 (F,p(a0)) …：γ(T,∀p) 补出 T,p(a0) 后闭 *)
    apply (tcSwap [(F, fP 0 [fC 0]); (T, fAll 0 (fImp pX qX))]
                 (T, fAll 0 pX) [(F, fEx 0 qX)]).
    apply (tcGT _ 0 pX 0).
    apply (tcClose _ 0 [fC 0]).
    + apply in_eq.
    + apply in_cons. apply in_cons. apply in_eq.
  - (* 右支 (T,q(a0)) …：γ(F,∃q) 补出 F,q(a0) 后闭 *)
    apply (tcSwap [(T, fP 1 [fC 0]); (T, fAll 0 (fImp pX qX)); (T, fAll 0 pX)]
                 (F, fEx 0 qX) []).
    apply (tcGF _ 0 qX 0).
    apply (tcClose _ 1 [fC 0]).
    + apply in_cons. apply in_cons. apply in_eq.
    + apply in_eq.
Qed.

Corollary valid_733 : forall {D} (I : interp D), ~ satB I [(F, a733)].
Proof. intros D I. apply (@tclo_unsat [(F, a733)] tclo_733 D I). Qed.

(* 算法层同一公式：搜索直接判闭 *)
Example ex733_closed : tsearch 40 [(F, a733)] [] = None.
Proof. reflexivity. Qed.

(* Ben-Ari 例 7.34/7.35：∀x(p∨q) → (∀x p ∨ ∀x q) —— 可满足不有效，
   否定的表列开：读出 Herbrand 模型（p、q 各真一个常量） *)
Definition a734 : fform :=
  fImp (fAll 0 (fOr pX qX)) (fOr (fAll 0 pX) (fAll 0 qX)).

(* 读出的模型：q(a0) ∧ p(a1)——「p、q 各真一个常量」的 Herbrand 见证 *)
Example ex734_open :
  match tsearch 40 [(F, a734)] [] with
  | Some B => atomsOf B
  | None => [(99,[99])]
  end = [(1,[0]); (0,[1])].
Proof. reflexivity. Qed.

(* Ben-Ari 例 7.36：∀x∃y p(x,y) —— 表列不终止（fuel 耗尽 ≠ 不可满足） *)
Definition a736 : fform := fAll 0 (fEx 0 (fP 2 [fV 0; fV 1])).

Example ex736_fuel : tsearch 30 [(T, a736)] [] = None.
Proof. reflexivity. Qed.
