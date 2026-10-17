(* ============================================================ *)
(* 39 子类型 —— Coq：算法子类型化的可靠性与结构终止（书 16.1/17）*)
(*   甲·声明式子类型 <:（图 15.1+15.3；记录三律合并为图 16.1     *)
(*      的紧致宏规则 S_Rcd——书 16.1.1 的等价改写）              *)
(*   乙·算法化子类型 asub：S-Refl/S-Trans 清除、SA-Top/Arrow/    *)
(*      Rcd 三条；对【右参 T】结构递归——终止性（16.1.6）白送    *)
(*   丙·可靠性：asub T S = true → S <: T（16.1.5 的方向一）；    *)
(*      置换使 <: 非反对称的见证（15.2 末）                      *)
(* ============================================================ *)

Require Import List Arith.
Import ListNotations.
Require Import Lia.

(* 标签用 nat；类型：Top / 箭头 / 记录 *)
Inductive ty : Type :=
| Top  : ty
| Arrow : ty -> ty -> ty
| Rcd  : list (nat * ty) -> ty.

(* ---- 甲·声明式（紧致形式：图 16.1） ---- *)
Inductive sub : ty -> ty -> Prop :=
| S_Refl : forall S, sub S S
| S_Trans : forall S U T, sub S U -> sub U T -> sub S T
| S_Top : forall S, sub S Top
| S_Arrow : forall S1 S2 T1 T2,
    sub T1 S1 -> sub S2 T2 -> sub (Arrow S1 S2) (Arrow T1 T2)
| S_Rcd : forall SF TF,
    (forall l T1, In (l, T1) TF ->
                exists S1, In (l, S1) SF /\ sub S1 T1) ->
    sub (Rcd SF) (Rcd TF).


(* ---- 乙·算法化 ---- *)
(* 逆变交换了参数角色（SA-Arrow 的参数检查以 S1 为上界侧），
   单参数结构递归放不下——用尺寸燃料编码终止性（16.1.6 的度量：
   每次递归两侧类型都严格变小）。记录侧检查用 forallb（可靠性走 forallb_forall）。 *)
Fixpoint findf (l : nat) (fs : list (nat * ty)) : option ty :=
  match fs with
  | [] => None
  | (l', T) :: rest => if l =? l' then Some T else findf l rest
  end.

Fixpoint asub (n : nat) (T S : ty) : bool :=
  match n with
  | O => false                                  (* 燃料尽：按否 *)
  | S n' =>
      match T with
      | Top => true                               (* SA-Top：叶子只留 Top *)
      | Arrow T1 T2 =>
          match S with
          | Arrow S1 S2 =>
              andb (asub n' S1 T1) (asub n' T2 S2) (* SA-Arrow：参数侧反向 *)
          | _ => false
          end
      | Rcd TF =>
          match S with
          | Rcd SF =>
              (* SA-Rcd：T 的每个字段在 S 里有子型匹配 *)
              forallb (fun ft =>
                match findf (fst ft) SF with
                | Some S1 => asub n' (snd ft) S1
                | None => false
                end) TF
          | _ => false
          end
      end
  end.

(* ---- 丙·可靠性：算法 ⊆ 声明式（16.1.5 方向一） ---- *)
Lemma findf_sound : forall SF l S1, findf l SF = Some S1 -> In (l, S1) SF.
Proof.
  induction SF as [ | [l0 T0] SF IH]; intros l S1 H; simpl in H.
  - discriminate.
  - destruct (l =? l0) eqn:E.
    + apply Nat.eqb_eq in E. subst. inversion H. left. reflexivity.
    + right. apply IH. assumption.
Qed.

(* 记录检查的可靠性：参数化在「同燃料的 asub 可靠」上——
   这样 asub 与 rcdcheck 的互递归在证明侧解开（asub 的 Rcd 分支
   调 rcdcheck，rcdcheck 的字段调 asub，两层各自归纳） *)

Theorem asub_sound : forall n T S, asub n T S = true -> sub S T.
Proof.
  induction n as [ | n IHn]; intros T S H; simpl in H.
  - discriminate.
  - destruct T as [ | T1 T2 | TF].
    + apply S_Top.
    + destruct S as [ | S1 S2 | SF]; try discriminate.
      apply andb_prop in H. destruct H as [H1 H2].
      apply S_Arrow.
      * (* 逆变：asub n S1 T1 的实例化恰给 sub T1 S1 *)
        apply IHn. assumption.
      * apply IHn. assumption.
    + destruct S as [ | S1 S2 | SF]; try discriminate.
      rewrite forallb_forall in H. apply S_Rcd.
      intros l2 U Hin. specialize (H (l2, U) Hin).
      destruct (findf l2 SF) as [S1 |] eqn:Hf;
        [| cbn in H; rewrite Hf in H; discriminate].
      exists S1. split.
      * eapply findf_sound. eassumption.
      * cbn in H; rewrite Hf in H; cbn in H; apply IHn; assumption.
Qed.

(* ---- 见证：宽度/深度/置换与箭头逆变 ---- *)
Example width_ok :
  asub 10 (Rcd [(1, Top)]) (Rcd [(1, Top); (2, Top)]) = true.
Proof. reflexivity. Qed.

Example arrow_contravariance :
  asub 10 (Arrow (Rcd [(1, Top); (2, Top)]) Top)
         (Arrow (Rcd [(1, Top)]) Top) = true.
Proof. reflexivity. Qed.

(* 置换：非反对称的见证（15.2 末——子类型是前序不是偏序） *)
Example perm_both :
  sub (Rcd [(1, Top); (2, Top)]) (Rcd [(2, Top); (1, Top)])/\
  sub (Rcd [(2, Top); (1, Top)]) (Rcd [(1, Top); (2, Top)]).
Proof.
  split.
  - apply S_Rcd. intros l U Hin. simpl in Hin.
    destruct Hin as [E1 | [E2 | F]].
    + inversion E1; subst. exists Top.
      split; [simpl; auto | apply S_Refl].
    + inversion E2; subst. exists Top.
      split; [simpl; auto | apply S_Refl].
    + destruct F.
  - apply S_Rcd. intros l U Hin. simpl in Hin.
    destruct Hin as [E1 | [E2 | F]].
    + inversion E1; subst. exists Top.
      split; [simpl; auto | apply S_Refl].
    + inversion E2; subst. exists Top.
      split; [simpl; auto | apply S_Refl].
    + destruct F.
Qed.

(* 反例：算法化拒绝「加字段」方向 *)
Example width_reversed :
  asub 10 (Rcd [(1, Top); (2, Top)]) (Rcd [(1, Top)]) = false.
Proof. reflexivity. Qed.
