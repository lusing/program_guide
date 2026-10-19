(* ex36 —— LTL 语义表列（Ben-Ari 3e §13.5）
   命题 α/β 照旧；新规则三条（定理 13.32 的展开）：
     □A（α 型）：当前添 A、next 添 □A——「现在真且永远真」；
     ◇A（β 型）：A ∨ X◇A——「现在真，或推迟到下一态」；
     X A（收集）：状态定形后取体搬进 next——新状态开始（文字不带走）。
   状态节点 = 文字 + X 公式（Def 13.35）；X-步迭代，公式集重现即环
   ——lasso（前缀+环）= 无穷路径的有限证书（有限表示，§13.5.1）。

   机器件：
     saturate —— 单路径饱和（orelse 取第一条开分支；完整判定需对 β
                 分支回溯——单路径探索的边界，docs/36 如实登记）
     lasso    —— X-步迭代 + 重现检测，返回 (状态公式集序列, 环起点)
     fulfill_ok —— 环上兑现检查（Def 13.49 的可计算版：位置 i 的 ◇A
                 在 [min(i,c), n) 内有见证）
     fulfill_ok_sound —— 旗舰（单向）：检查通过 ⟹ 每个 ◇A 的见证都
                 落在可达区间（含绕环）。 *)

From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.

Inductive lform : Type :=
| lAtom : nat -> lform
| lNot  : lform -> lform
| lAnd  : lform -> lform -> lform
| lOr   : lform -> lform -> lform
| lImp  : lform -> lform -> lform
| lNext : lform -> lform        (* X A *)
| lBox  : lform -> lform        (* □ A *)
| lDia  : lform -> lform.       (* ◇ A *)

(* ---------- NNF 预处理：否定推到原子（时态对偶 ¬X=X¬、¬□=◇¬、¬◇=□¬） *)

Fixpoint nnf (f : lform) : lform :=
  match f with
  | lAtom _ => f
  | lNot g => nnfNeg g
  | lAnd a b => lAnd (nnf a) (nnf b)
  | lOr  a b => lOr (nnf a) (nnf b)
  | lImp a b => lOr (nnfNeg a) (nnf b)
  | lNext a => lNext (nnf a)
  | lBox  a => lBox (nnf a)
  | lDia  a => lDia (nnf a)
  end
with nnfNeg (f : lform) : lform :=
  match f with
  | lAtom _ => lNot f
  | lNot g => nnf g
  | lAnd a b => lOr (nnfNeg a) (nnfNeg b)
  | lOr  a b => lAnd (nnfNeg a) (nnfNeg b)
  | lImp a b => lAnd (nnf a) (nnfNeg b)
  | lNext a => lNext (nnfNeg a)
  | lBox  a => lDia (nnfNeg a)
  | lDia  a => lBox (nnfNeg a)
  end.

(* ---------- 结构相等/成员/位置 ---------- *)

Fixpoint eqf (f g : lform) : bool :=
  match f, g with
  | lAtom a, lAtom b => Nat.eqb a b
  | lNot a, lNot b => eqf a b
  | lAnd a1 b1, lAnd a2 b2 => eqf a1 a2 && eqf b1 b2
  | lOr  a1 b1, lOr  a2 b2 => eqf a1 a2 && eqf b1 b2
  | lImp a1 b1, lImp a2 b2 => eqf a1 a2 && eqf b1 b2
  | lNext a, lNext b => eqf a b
  | lBox a, lBox b => eqf a b
  | lDia a, lDia b => eqf a b
  | _, _ => false
  end.

Fixpoint eqlL (Γ Δ : list lform) : bool :=
  match Γ, Δ with
  | [], [] => true
  | f :: Γ', g :: Δ' => eqf f g && eqlL Γ' Δ'
  | _, _ => false
  end.

Definition memL (Γ : list lform) (f : lform) : bool :=
  existsb (fun g => eqf g f) Γ.

(* 重现检查用**集合**语义（Ben-Ari 的 U(l) 是公式集）：多重集会因
   □◇ 的反复展开累积重复副本，集合比较才是正确的有限性判据 *)
Definition setEqL (Γ Δ : list lform) : bool :=
  forallb (fun f => memL Γ f) Δ && forallb (fun f => memL Δ f) Γ.

Fixpoint posOfL (cur : list lform) (seen : list (list lform)) : nat :=
  match seen with
  | [] => 0
  | s :: seen' => if setEqL s cur then 0 else S (posOfL cur seen')
  end.

(* ---------- 饱和：α/β/□/◇ 展开 + X 收集 ---------- *)

Fixpoint isLit (f : lform) : bool :=
  match f with
  | lAtom _ => true
  | lNot (lAtom _) => true
  | _ => false
  end.

(* 系统性纪律（Ben-Ari 算法 13.36）：α 规则优先于 β——否则 β 的
   「现在」支会带着未展开的 α 指数膨胀（本章实测的爆炸现场） *)
Fixpoint extractA (Γ : list lform) : option (lform * list lform) :=
  match Γ with
  | [] => None
  | f :: Γ' =>
      match f with
      | lAnd _ _ | lBox _ =>
          Some (f, Γ')
      | _ =>
          match extractA Γ' with
          | Some (g, rest) => Some (g, f :: rest)
          | None => None
          end
      end
  end.

Fixpoint extractB (Γ : list lform) : option (lform * list lform) :=
  match Γ with
  | [] => None
  | f :: Γ' =>
      match f with
      | lOr _ _ | lImp _ _ | lDia _ =>
          Some (f, Γ')
      | _ =>
          match extractB Γ' with
          | Some (g, rest) => Some (g, f :: rest)
          | None => None
          end
      end
  end.

Definition extractN (Γ : list lform) : option (lform * list lform) :=
  match extractA Γ with
  | Some r => Some r
  | None => extractB Γ
  end.

Definition compPair (Γ : list lform) : bool :=
  existsb (fun f => match f with
                    | lAtom p => memL Γ (lNot (lAtom p))
                    | _ => false
                    end) Γ.

Definition orelseL {A} (o1 o2 : option A) : option A :=
  match o1 with Some x => Some x | None => o2 end.

(* X 去壳：只取 X 的体；文字不带走（s_i 的赋值与 s_{i+1} 无关） *)
Fixpoint unX (Γ : list lform) : list lform :=
  match Γ with
  | [] => []
  | lNext a :: Γ' => a :: unX Γ'
  | _ :: Γ' => unX Γ'
  end.

(* 饱和当前集。返回 Some (stateLabel, next)：
   stateLabel = 文字+X 表（无互补对）；next = X 体 ++ 延迟的 □/◇ *)
Fixpoint saturate (fuel : nat) (Γ next : list lform)
  : option (list lform * list lform) :=
  match fuel with
  | 0 => None
  | S k =>
      if compPair Γ then None else
      match extractN Γ with
      | Some (lAnd a b, Γ') => saturate k (a :: b :: Γ') next
      | Some (lBox a, Γ')   => saturate k (a :: Γ') (lBox a :: next)
      | Some (lOr a b, Γ')  =>
          orelseL (saturate k (a :: Γ') next)
                  (saturate k (b :: Γ') next)
      | Some (lImp a b, Γ') =>
          orelseL (saturate k (lNot a :: Γ') next)
                  (saturate k (b :: Γ') next)
      | Some (lDia a, Γ')   =>
          orelseL (saturate k (a :: Γ') next)
                  (saturate k Γ' (lDia a :: next))
      | Some (_, _) => None    (* 文字/X 不会被 extractN 挑出 *)
      | None => Some (Γ, unX Γ ++ next)
      end
  end.

(* ---------- lasso：迭代 X-步，公式集重现即环 ---------- *)

Fixpoint lasso (fuel : nat) (seen : list (list lform)) (cur : list lform)
  : option (list (list lform) * nat) :=
  match fuel with
  | 0 => None
  | S k =>
      if existsb (fun s => setEqL s cur) seen then
        Some (rev (cur :: seen), posOfL cur (rev seen))
      else
        match saturate 64 cur [] with
        | Some (_, []) => Some (rev (cur :: seen), length seen)  (* 无后继：自环 *)
        | Some (_, next) => lasso k (cur :: seen) next
        | None => None    (* 本路径闭：单路径探索的边界 *)
        end
  end.

(* ---------- 兑现检查（Def 13.49 的 lasso 版） ---------- *)

(* 从某 suffix 起扫见证 *)
Fixpoint scanAny (l : list (list lform)) (a : lform) : bool :=
  match l with
  | [] => false
  | s :: l' => memL s a || scanAny l' a
  end.

(* 位置 i 的 ◇A 的见证区间：[min(i,c), n)（i<c 只需向前；i≥c 可绕环） *)
Definition witnessIn (full : list (list lform)) (c i : nat) (a : lform) : bool :=
  scanAny (skipn (Nat.min i c) full) a.

Fixpoint checkAll (full tail : list (list lform)) (c base : nat) : bool :=
  match tail with
  | [] => true
  | s :: tail' =>
      (forallb (fun f => match f with
                          | lDia a => witnessIn full c base a
                          | _ => true end) s)
      && checkAll full tail' c (S base)
  end.

Definition fulfill_ok (st : list (list lform)) (c : nat) : bool :=
  checkAll st st c 0.

(* 结构相等与成员的 Prop 侧换算 *)
Lemma eqf_eq : forall f g, eqf f g = true -> f = g.
Proof.
  induction f as [p | a IH | a IHa b IHb | a IHa b IHb | a IHa b IHb
                 | a IH | a IH | a IH];
    intros [q | c | c d | c d | c d | c | c | c] H; try discriminate;
    try (apply Nat.eqb_eq in H; subst; reflexivity).
  - f_equal. simpl in H. apply IH. exact H.
  - simpl in H. apply andb_true_iff in H. destruct H as [Ha Hb].
    f_equal; [apply IHa; exact Ha | apply IHb; exact Hb].
  - simpl in H. apply andb_true_iff in H. destruct H as [Ha Hb].
    f_equal; [apply IHa; exact Ha | apply IHb; exact Hb].
  - simpl in H. apply andb_true_iff in H. destruct H as [Ha Hb].
    f_equal; [apply IHa; exact Ha | apply IHb; exact Hb].
  - f_equal. simpl in H. apply IH. exact H.
  - f_equal. simpl in H. apply IH. exact H.
  - f_equal. simpl in H. apply IH. exact H.
Qed.

Lemma memL_In : forall G f, memL G f = true -> In f G.
Proof.
  induction G as [| g G' IH]; intros f H; simpl in H.
  - discriminate.
  - apply orb_true_iff in H. destruct H as [He | H].
    + left. apply eqf_eq in He. exact He.
    + right. apply IH. exact H.
Qed.

(* ---------- 见证扫描的健全性 ---------- *)

Lemma scanAny_sound : forall l a,
  scanAny l a = true ->
  exists k, k < length l /\ memL (nth k l []) a = true.
Proof.
  induction l as [| s l' IH]; intros a H; simpl in H.
  - discriminate.
  - apply orb_true_iff in H. destruct H as [Hs | H].
    + exists 0. split; [simpl; lia | exact Hs].
    + destruct (IH a H) as [k [Hk Hm]].
      exists (S k). split; [simpl; lia | exact Hm].
Qed.

Lemma nth_nil : forall (A : Type) (n : nat) (d : A), nth n [] d = d.
Proof. intros A n d. destruct n; reflexivity. Qed.

Lemma skipn_nil : forall (A : Type) (m : nat), @skipn A m [] = [].
Proof. intros A m. destruct m; reflexivity. Qed.

Lemma nth_skipn_app : forall (l : list (list lform)) m k,
  nth k (skipn m l) [] = nth (m + k) l [].
Proof.
  induction l as [| x l' IH]; intros m k.
  - rewrite skipn_nil, !nth_nil. reflexivity.
  - destruct m as [| m']; simpl.
    + reflexivity.
    + rewrite IH. reflexivity.
Qed.

Lemma skipn_length_lt : forall (l : list (list lform)) m k,
  k < length (skipn m l) -> m + k < length l.
Proof.
  induction l as [| x l' IH]; intros m k H; simpl in *.
  - destruct m; simpl in H; lia.
  - destruct m as [| m']; simpl in *.
    + lia.
    + apply IH in H. lia.
Qed.

Lemma witnessIn_sound : forall full c i a,
  witnessIn full c i a = true ->
  exists j, j < length full /\ (i <= j \/ c <= j) /\
            memL (nth j full []) a = true.
Proof.
  intros full c i a H. unfold witnessIn in H.
  destruct (scanAny_sound _ _ H) as [k [Hk Hm]].
  destruct (Nat.min_spec i c) as [[Hmin Hle] | [Hle Hmin]].
  - exists (Nat.min i c + k).
    split; [apply (skipn_length_lt _ _ _ Hk) | split; [left; lia | ]].
    rewrite nth_skipn_app in Hm. exact Hm.
  - exists (Nat.min i c + k).
    split; [apply (skipn_length_lt _ _ _ Hk) | split; [right; lia | ]].
    rewrite nth_skipn_app in Hm. exact Hm.
Qed.

Lemma checkAll_extract : forall full tail c base,
  checkAll full tail c base = true ->
  forall k a, k < length tail ->
  memL (nth k tail []) (lDia a) = true ->
  witnessIn full c (base + k) a = true.
Proof.
  induction tail as [| s tail' IH]; intros c0 base0 H k a Hk Hm;
    simpl in *.
  - lia.
  - destruct k as [| k'].
    + simpl in Hm.
      apply andb_prop in H. destruct H as [Hall _].
      rewrite forallb_forall in Hall.
      specialize (Hall (lDia a) (memL_In _ _ Hm)).
      simpl in Hall. rewrite Nat.add_0_r. exact Hall.
    + apply andb_prop in H. destruct H as [_ Hrec].
      replace (base0 + S k') with (S base0 + k') by lia.
      apply (IH c0 (S base0) Hrec).
      * lia.
      * exact Hm.
Qed.

(* ---------- 旗舰：兑现检查的健全性（单向） ---------- *)

Theorem fulfill_ok_sound : forall st c,
  fulfill_ok st c = true ->
  forall i a, i < length st ->
  memL (nth i st []) (lDia a) = true ->
  exists j, j < length st /\ (i <= j \/ c <= j) /\
            memL (nth j st []) a = true.
Proof.
  intros st c Hok i a Hi Hdia. unfold fulfill_ok in Hok.
  pose proof (checkAll_extract st st c 0 Hok i a Hi Hdia) as Hw.
  simpl in Hw.
  apply (witnessIn_sound st c i a). exact Hw.
Qed.

(* ---------- 现场例 ---------- *)

(* Ben-Ari §13.5.1 的「永远推迟」变体：□¬p ∧ □◇p —— ◇p 永不兑现 *)
Definition exUnsat : lform :=
  lAnd (lBox (lNot (lAtom 0))) (lBox (lDia (lAtom 0))).

(* ◇□p：终将永远 p —— 环 {p} 兑现 vacuous，模型 = 处处 p *)
Definition exFG : lform := lDia (lBox (lAtom 0)).

(* 现场一：◇□p 的 lasso——三态一环（环起点 1），兑现检查通过 *)
Example exFG_lasso :
  match lasso 30 [] [nnf exFG] with
  | Some (st, c) => (st, c, fulfill_ok st c)
  | None => ([], 0, false)
  end = ([[lDia (lBox (lAtom 0))]; [lBox (lAtom 0)]; [lBox (lAtom 0)]], 1, true).
Proof. reflexivity. Qed.

(* 现场二：□¬p ∧ □◇p —— lasso 稳定在含 ◇p 的环上，但 p 永不出现：
   ◇p 永远推迟——兑现检查失败 ⟹ 不可满足（Ben-Ari 的「defers forever」） *)
Example exUnsat_fulfill_fails :
  match lasso 30 [] [nnf exUnsat] with
  | Some (st, c) => (c, fulfill_ok st c)
  | None => (0, true)
  end = (1, false).
Proof. reflexivity. Qed.
