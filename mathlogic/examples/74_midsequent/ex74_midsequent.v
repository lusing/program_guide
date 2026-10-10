(* 第 74 章 中矢列与 Herbrand 定理（Takeuti §6 Thm 6.4+Ex 6.7）
   机器面：分层推导树（上部命题/下部量词）+qfree 检查+order 计算+
   midsequent 判定+Herbrand 实例化样本。零公理。 *)

Require Import List.
Import ListNotations.

Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => true | x :: t => andb (f x) (forallb f t) end.

Inductive mfm : Type :=
| mp (n : nat)                    (* 命题原子 p_n *)
| mq (n v : nat)                  (* 一阶原子 q_n(c_v)；v=0 绑定位 *)
| mng (a : mfm)
| mand (a b : mfm)
| mor (a b : mfm)
| mimp (a b : mfm)
| mall (a : mfm)
| mex (a : mfm).

Fixpoint qfree (a : mfm) : bool :=
  match a with
  | mp _ | mq _ _ => true
  | mng b => qfree b
  | mand b c => andb (qfree b) (qfree c)
  | mor b c => andb (qfree b) (qfree c)
  | mimp b c => andb (qfree b) (qfree c)
  | mall _ | mex _ => false
  end.

Fixpoint substQ (a : mfm) (t : nat) : mfm :=
  match a with
  | mq n w => if Nat.eqb w 0 then mq n t else mq n w
  | mng b => mng (substQ b t)
  | mand b c => mand (substQ b t) (substQ c t)
  | mor b c => mor (substQ b t) (substQ c t)
  | mimp b c => mimp (substQ b t) (substQ c t)
  | mall b => mall (substQ b t)
  | mex b => mex (substQ b t)
  | mp _ => a
  end.

(* 分层推导：prule 命题推理（上）/qrule 量词推理（下） *)
Inductive mder : Type :=
| max (s : list mfm * list mfm)                       (* 公理叶 D=>D *)
| mandL (s : list mfm * list mfm) (sub : mder)         (* 命题：/\:left *)
| morR  (s : list mfm * list mfm) (sub : mder)         (* 命题：\/:right *)
| mallR (s : list mfm * list mfm) (sub : mder)         (* 量词：!:right 新常量 *)
| mexL  (s : list mfm * list mfm) (sub : mder).        (* 量词：?:left 新常量 *)

Definition seqOf (d : mder) : list mfm * list mfm :=
  match d with
  | max s => s | mandL s _ => s | morR s _ => s
  | mallR s _ => s | mexL s _ => s
  end.

(* isPropRule：命题层判定 *)
Definition isPropRule (d : mder) : bool :=
  match d with max _ | mandL _ _ | morR _ _ => true | _ => false end.

(* order：量词推理之下（=之上方）的命题推理计数（Thm 6.4 的 order） *)
Fixpoint qBelow (d : mder) : nat :=
  (* d 之下（closer to root）的命题推理数 *)
  match d with
  | max _ => 0
  | mandL _ sub | morR _ sub =>
      if isPropRule d then S (qBelow sub) else qBelow sub
  | mallR _ sub | mexL _ sub => qBelow sub
  end.

(* 简化口径：机器面直接数「量词推理在命题推理之下」的对数 *)
Fixpoint isQuantBelow (d : mder) : bool :=
  match d with
  | max _ => false
  | mandL _ sub | morR _ sub => isQuantBelow sub
  | mallR _ _ | mexL _ _ => true
  end.

Fixpoint badPairs (d : mder) : nat :=
  match d with
  | max _ => 0
  | mandL _ sub | morR _ sub =>
      if isQuantBelow sub then S (badPairs sub) else badPairs sub
  | mallR _ sub | mexL _ sub => badPairs sub
  end.

(* midsequent 判定：树中是否存在全量词自由的矢列节点
   （先查当前节点、再下钻——命题层与量词层的交界） *)
Definition qfreeS (s : list mfm * list mfm) : bool :=
  match s with
  | (G, D) => andb (forallb (fun a => qfree a) G) (forallb (fun a => qfree a) D)
  end.

Fixpoint findMid (d : mder) : option (list mfm * list mfm) :=
  match d with
  | max s => if qfreeS s then Some s else None
  | mandL s sub => if qfreeS s then Some s else findMid sub
  | morR s sub => if qfreeS s then Some s else findMid sub
  | mallR _ sub | mexL _ sub => findMid sub
  end.

(* ---------- 账例 ----------
   矢列 => ?x q_0(x) 的分层证明：
   公理 q_0(c_1) => q_0(c_1)
   --?:right 全例化（量词层）--> q_0(c_1),q_0(c_2) => ?x q_0(x)  简化：单例化
   中矢列 = q_0(c_1) => q_0(c_1)（无量词、上命题=公理、下量词） *)
Definition dEx2 : mder :=
  (* => p_0 /\ p_0 -> p_0：mandL 单层命题——中矢列即根（全命题） *)
  morR ([], [mor (mp 0) (mp 0)]) (max ([mp 0], [mp 0])).

Example qfreeLeaf :
  match findMid dEx2 with
  | Some (G, D) => andb (forallb (fun a => qfree a) G)
                         (forallb (fun a => qfree a) D)
  | None => false
  end = true.
Proof. reflexivity. Qed.

Example orderZero : Nat.eqb (badPairs dEx2) 0 = true.
Proof. reflexivity. Qed.

(* 量词在上的分层：mallR 包住命题层——badPairs=0（好分层） *)
Definition dEx3 : mder :=
  mallR ([], [mall (mor (mq 0 0) (mq 0 0))])
        (morR ([], [mor (mq 0 0) (mq 0 0)])
              (max ([mq 0 1], [mq 0 1]))).

Example goodLayering : Nat.eqb (badPairs dEx3) 0 = true.
Proof. reflexivity. Qed.

(* 坏分层：命题推理（\/:right）位于量词推理（!:right）之下——
   order>0 的现场：Thm 6.4 证明的换位目标正是这种倒置 *)
Definition dBad : mder :=
  morR ([], [mor (mq 0 1) (mq 0 1)])
        (mallR ([], [mall (mor (mq 0 0) (mq 0 0))])
               (max ([mq 0 1], [mq 0 1]))).

Example badLayering : Nat.eqb (badPairs dBad) 1 = true.
Proof. reflexivity. Qed.

(* ---------- Herbrand 实例化样本（中矢列定理的下游） ----------
   前束矢列 => !x ?y (p \/ q(y)) 的中矢列=命题化后全实例化：
   机器面：herbExpand 对量词对逐常量例化（Herbrand 域 {c1,c2}） *)
Definition DOM2 : list nat := [1; 2].

Fixpoint herbExpand (s : list mfm * list mfm) : list mfm * list mfm :=
  match s with
  | (G, D) =>
      (flat_map (fun a => match a with
                  | mall b => map (fun t => substQ b t) DOM2
                  | _ => [a] end) G,
       flat_map (fun a => match a with
                   | mex b => map (fun t => substQ b t) DOM2
                   | _ => [a] end) D)
  end.

Example herbAcct :
  match herbExpand ([], [mex (mp 0)]) with
  | (_, D) => Nat.eqb (List.length D) 2   (* ?x p 展开成两份 p *)
  end = true.
Proof. reflexivity. Qed.
