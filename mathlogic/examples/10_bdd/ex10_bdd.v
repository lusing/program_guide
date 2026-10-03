(* ex10 —— BDD：布尔函数的决策树与 apply（Ben-Ari 3e Ch5 / Huth&Ryan Ch6）
   设计：深度即变量索引——DNode 顶是变量 0，子树配 eshift 赋值；
   mkvar 用「复制消歧」：顶变量与目标无关时两支复制，
   语义上 if e 0 then t else t = t 把无关测试吸收掉。

   旗舰三条（零公理）：
     apply_correct   teval e (applyd op b1 b2) = op (teval e b1) (teval e b2)
     mkvar_correct   teval e (mkvar v) = e v
     mk_correct      teval e (mk f) = eval e f  ——公式到 BDD 编译保语义
   化简的规模红利在 Lean 通道现场（mknode 坍缩两分支相同节点）。 *)

Require Import List Bool Arith Lia.
Import ListNotations.

Inductive form : Type :=
| FVar : nat -> form
| FAnd : form -> form -> form
| FOr  : form -> form -> form
| FNeg : form -> form.

Fixpoint eval (e : nat -> bool) (f : form) : bool :=
  match f with
  | FVar n   => e n
  | FAnd a b => andb (eval e a) (eval e b)
  | FOr a b  => orb (eval e a) (eval e b)
  | FNeg a   => negb (eval e a)
  end.

(* ---------- 决策树：深度即变量索引 ---------- *)

Inductive dtree : Type :=
| DLeaf : bool -> dtree
| DNode : dtree -> dtree -> dtree.

Definition eshift (e : nat -> bool) : nat -> bool := fun m => e (S m).

Fixpoint teval (e : nat -> bool) (b : dtree) : bool :=
  match b with
  | DLeaf c => c
  | DNode lo hi => if e 0 then teval (eshift e) hi else teval (eshift e) lo
  end.

Fixpoint bsize (b : dtree) : nat :=
  match b with
  | DLeaf _ => 1
  | DNode lo hi => 1 + bsize lo + bsize hi
  end.

(* ---------- mapleaf：叶上变换 ---------- *)

Fixpoint mapleaf (f : bool -> bool) (b : dtree) : dtree :=
  match b with
  | DLeaf c => DLeaf (f c)
  | DNode lo hi => DNode (mapleaf f lo) (mapleaf f hi)
  end.

Lemma teval_mapleaf : forall b e f,
  teval e (mapleaf f b) = f (teval e b).
Proof.
  induction b as [c|lo IHlo hi IHhi]; intros e f; simpl.
  - reflexivity.
  - destruct (e 0); [rewrite IHhi | rewrite IHlo]; reflexivity.
Qed.

(* ---------- apply ---------- *)

Fixpoint applyd (op : bool -> bool -> bool) (b1 b2 : dtree) {struct b1} : dtree :=
  match b1, b2 with
  | DLeaf c1, _ => mapleaf (fun c => op c1 c) b2
  | _, DLeaf c2 => mapleaf (fun c => op c c2) b1
  | DNode l1 h1, DNode l2 h2 =>
      DNode (applyd op l1 l2) (applyd op h1 h2)
  end.

Theorem apply_correct : forall op b1 b2 e,
  teval e (applyd op b1 b2) = op (teval e b1) (teval e b2).
Proof.
  intros op b1. induction b1 as [c1|l1 IHl h1 IHh]; intros b2 e.
  - destruct b2 as [c2|l2 h2].
    + simpl. reflexivity.
    + simpl. destruct (e 0); rewrite teval_mapleaf; reflexivity.
  - destruct b2 as [c2|l2 h2].
    + simpl. destruct (e 0); rewrite teval_mapleaf; reflexivity.
    + simpl. destruct (e 0).
      * rewrite (IHh h2 (eshift e)). reflexivity.
      * rewrite (IHl l2 (eshift e)). reflexivity.
Qed.

(* ---------- 单变量树与公式编译 ---------- *)

Fixpoint mkvar (v : nat) : dtree :=
  match v with
  | 0 => DNode (DLeaf false) (DLeaf true)
  | S v' => DNode (mkvar v') (mkvar v')
  end.

Theorem mkvar_correct : forall v e, teval e (mkvar v) = e v.
Proof.
  induction v as [|v' IH]; intros e.
  - simpl. destruct (e 0); reflexivity.
  - simpl. destruct (e 0).
    + rewrite IH. reflexivity.
    + rewrite IH. reflexivity.
Qed.

(* 教学版不化简：mkvar v 是深度 v+1 的满树 *)
Lemma two_pow_pos : forall n, 0 < 2 ^ n.
Proof. induction n as [|n IH]; simpl; lia. Qed.

Lemma bsize_mkvar : forall v, bsize (mkvar v) = 2 ^ (v + 2) - 1.
Proof.
  induction v as [|v' IH]; simpl.
  - reflexivity.
  - rewrite IH.
    pose proof (two_pow_pos (v' + 2)) as H. lia.
Qed.

Fixpoint mk (f : form) : dtree :=
  match f with
  | FVar n   => mkvar n
  | FAnd a b => applyd andb (mk a) (mk b)
  | FOr a b  => applyd orb (mk a) (mk b)
  | FNeg a   => mapleaf negb (mk a)
  end.

Theorem mk_correct : forall f e, teval e (mk f) = eval e f.
Proof.
  induction f as [n|a IHa b IHb|a IHa b IHb|a IHa]; intros e; simpl.
  - apply mkvar_correct.
  - rewrite apply_correct, IHa, IHb. reflexivity.
  - rewrite apply_correct, IHa, IHb. reflexivity.
  - rewrite teval_mapleaf, IHa. reflexivity.
Qed.

Print Assumptions mk_correct.  (* Closed：编译零公理 *)

(* ---------- 现场 ---------- *)

Example mkvar_two :
  mkvar 1 = DNode (DNode (DLeaf false) (DLeaf true))
                  (DNode (DLeaf false) (DLeaf true)).
Proof. reflexivity. Qed.

Example xor_bdd : bsize (applyd xorb (mkvar 0) (mkvar 1)) = 7.
Proof. reflexivity. Qed.

(* 坑位速记（Coq 侧）：
   - 深度编码变量时，「坍缩 hi=lo 返回子树」会让变量错位
     （子树在下一层，语义配 eshift e）——正确坍缩须配 lift 垫回，
     而 lift(DNode)=DNode 的语义又要求 e 0 无关——教学版干脆不化简，
     化简红利在 Lean 通道用结构判等现场演示；
   - mkvar (S v) = DNode (mkvar v) (mkvar v) 的「复制消歧」：
     顶变量与内容无关，if e 0 then t else t ≡ t；
   - applyd 叶/节点交叉四种情况逐一收——mapleaf 是叶情形的统一出口。 *)
