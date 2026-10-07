(* ex25 —— 霍尔逻辑：赋值公理、while 规则与具体程序验证
   对书：Huth&Ryan ch4 / Ben-Ari 3e ch15

   三元组 {P} c {Q}（部分正确性）：P 成立时执行 c 终止则 Q 成立。
   旗舰三条（零公理）：
     hoare_skip      {P} skip {P}
     hoare_while     循环规则（不变式）
     countdown       具体程序：倒数计数的完全验证 *)

From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.

(* ---------- while 语言 ---------- *)

Definition state := nat -> nat.

Definition upd (s : state) (x v : nat) : state :=
  fun m => if Nat.eqb m x then v else s m.

Inductive cmd : Type :=
| cskip : cmd
| cass : nat -> (state -> nat) -> cmd        (* x := f(state) *)
| cseq : cmd -> cmd -> cmd
| cwhile : (state -> bool) -> cmd -> cmd.    (* while b do c *)

(* 状态 = 变元赋值 *)
Inductive exec : cmd -> state -> state -> Prop :=
| eSkip : forall s, exec cskip s s
| eAss : forall x f s, exec (cass x f) s (upd s x (f s))
| eSeq : forall c1 c2 s1 s2 s3, exec c1 s1 s2 -> exec c2 s2 s3 -> exec (cseq c1 c2) s1 s3
| eWhileT : forall b c s1 s2 s3,
    b s1 = true -> exec c s1 s2 -> exec (cwhile b c) s2 s3 ->
    exec (cwhile b c) s1 s3
| eWhileF : forall b c s, b s = false -> exec (cwhile b c) s s.

(* ---------- 霍尔三元组（部分正确性） ---------- *)

Definition hoare (P : state -> Prop) (c : cmd) (Q : state -> Prop) : Prop :=
  forall s1 s2, P s1 -> exec c s1 s2 -> Q s2.

(* ---------- 旗舰一：skip 规则 ---------- *)

Theorem hoare_skip : forall P, hoare P cskip P.
Proof. intros P s1 s2 HP He. inversion He; subst; assumption. Qed.

(* ---------- 旗舰二：赋值公理 ---------- *)

Theorem hoare_ass : forall Q x f,
  hoare (fun s => Q (fun m => if Nat.eqb m x then f s else s m))
        (cass x f) Q.
Proof.
  intros Q x f s1 s2 HP He. inversion He; subst; assumption.
Qed.

(* ---------- 旗舰三：while 规则 ---------- *)

Theorem hoare_seq : forall P c1 Q c2 R,
  hoare P c1 Q -> hoare Q c2 R -> hoare P (cseq c1 c2) R.
Proof.
  intros P c1 Q c2 R H1 H2 s1 s3 HP He.
  inversion He; subst. eapply H2; [| eassumption]. eapply H1; eassumption.
Qed.

Theorem hoare_while : forall P b c,
  hoare (fun s => P s /\ b s = true) c P ->
  hoare P (cwhile b c) (fun s => P s /\ b s = false).
Proof.
  intros P b c Hbody s1 s2 HP He.
  remember (cwhile b c) as w eqn:Hw. revert HP.
  induction He as
    [s | x f s | c1 c2 s1' s2' s3' H1 IH1 H2 IH2
    | b' c' s1' s2' s3' Hb Hstep IHstep Hloop IHloop
    | b' c' s Hb]; intros HP; inversion Hw; subst.
  - apply IHloop; [reflexivity |].
    exact (Hbody s1' s2' (conj HP Hb) Hstep).
  - split; assumption.
Qed.

Print Assumptions hoare_skip.   (* Closed *)
Print Assumptions hoare_ass.   (* Closed *)
Print Assumptions hoare_while. (* Closed *)

(* ---------- 现场演示：倒数程序 ---------- *)

(* countdown(x,y) := while (x ≠ 0) do (x := x-1; y := y+1)
   不变式：s x + s y = C。别名警告：x = y 时两个「变量」是同一格，
   不变式修补项 +1/-1 不再抵消——正确性须以 x <> y 为前提。 *)
Definition countdown (x y : nat) : cmd :=
  cwhile (fun s => negb (Nat.eqb (s x) 0))
         (cseq (cass x (fun s => s x - 1))
               (cass y (fun s => s y + 1))).

Definition inv (x y C : nat) : state -> Prop :=
  fun s => s x + s y = C.

(* upd 读出引理：写格子自读、旁格不扰 *)
Lemma upd_read : forall x s, upd s x (s x - 1) x = s x - 1.
Proof. intros x s. unfold upd. rewrite Nat.eqb_refl. reflexivity. Qed.

Lemma upd_other : forall x s m, m <> x -> upd s x (s x - 1) m = s m.
Proof.
  intros x s m Hm. unfold upd.
  destruct (Nat.eqb_spec m x); [contradiction | reflexivity].
Qed.

(* 完全组装：部分正确性 + 出口守卫 = x 归零 *)
Theorem countdown_correct : forall x y C s1 s2,
  x <> y -> inv x y C s1 -> exec (countdown x y) s1 s2 ->
  inv x y C s2 /\ s2 x = 0.
Proof.
  intros x y C s1 s2 Hne Hinv1 He.
  assert (Hne' : y <> x) by (intro E; apply Hne; symmetry; exact E).
  (* 身体三元组：{inv ∧ x≠0} x:=x-1; y:=y+1 {inv} *)
  assert (Hbody :
    hoare (fun s => inv x y C s /\ negb (Nat.eqb (s x) 0) = true)
          (cseq (cass x (fun s => s x - 1)) (cass y (fun s => s y + 1)))
          (inv x y C)).
  { apply (hoare_seq _ _ (fun t => t x + t y + 1 = C)).
    - intros s t HP Hx. inversion Hx; subst.
      destruct HP as [Hinv' Hg]. unfold inv in Hinv'.
      assert (Hpos : s x <> 0).
      { intro E. rewrite E in Hg. simpl in Hg. discriminate. }
      rewrite upd_read, (upd_other x s y Hne'). lia.
    - intros t u HQ Hx. inversion Hx; subst.
      unfold inv. simpl.
      unfold upd at 1. destruct (Nat.eqb_spec x y); [contradiction | ].
      unfold upd. rewrite Nat.eqb_refl. lia. }
  destruct (hoare_while _ _ _ Hbody s1 s2 Hinv1 He) as [Hinv2 Hb].
  split; [exact Hinv2 |].
  apply negb_false_iff in Hb. apply Nat.eqb_eq in Hb. exact Hb.
Qed.

Print Assumptions hoare_seq.           (* Closed *)
Print Assumptions countdown_correct.   (* Closed *)

(* 坑位速记（Coq 侧）：
   - hoare_while 的证明是 remember (cwhile b c) + revert HP + induction：
     方程 Hw 被自动归入动机，五个构造子分支里前三支被 inversion Hw
     灭掉，IHloop 携带等式前提 eq_refl 喂入——不 remember 直接
     induction 会把 cmd 索引完全泛化（skip 分支变得不可证）；
   - 身体三元组里 exec 的赋值后继状态是 upd 复合——中间不变式
     选 t x + t y + 1 = C（先减后加的一轮修补），别名 x = y 时
     修补项不抵消，countdown_correct 必须以 x <> y 为前提；
   - 截断减法坑：s x - 1 + 1 = s x 需要 s x > 0——循环守卫
     negb (eqb (s x) 0) = true 提供它，缺了 lia 直接找不到见证。 *)
