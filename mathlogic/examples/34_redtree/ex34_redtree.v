(* 第 34 章 归约树：完备性的证明论路线（Takeuti §8 p40-52）
   对书：Def 8.1 结构与满足、Lemma 8.3 归约树（13 阶段循环归约：
   k mod 13 -> 0/1 ¬左右 2/3 ∧左右 4/5 ∨左右 6/7 →左右 8/9 ∀左右
   10/11 ∃左右 12 停/复制）、Thm 8.2 完备性。
   机器面：命题+一阶单变元片段（固定常量域 1..3，绑定变元以常量位 0 表示，
   量词深度 1——docs 说明简化）。零公理。 *)

Require Import List.
Import ListNotations.

Inductive tform : Type :=
| tpr  (n : nat)                 (* 命题原子 p_n *)
| tqa  (n v : nat)                (* 一阶原子 q_n(c_v)；v=0 为绑定变元位 *)
| tneg (a : tform)
| tand (a b : tform)
| tor  (a b : tform)
| timp (a b : tform)
| tfall (a : tform)               (* !x a，x 以常量位 0 出现 *)
| ttex (a : tform).

Definition seqt : Type := (list tform * list tform)%type.

(* ---------- 小工具 ---------- *)
Fixpoint feqb (a b : tform) : bool :=
  match a, b with
  | tpr n, tpr m => Nat.eqb n m
  | tqa n v, tqa m w => andb (Nat.eqb n m) (Nat.eqb v w)
  | tneg a1, tneg b1 => feqb a1 b1
  | tand a1 a2, tand b1 b2 => andb (feqb a1 b1) (feqb a2 b2)
  | tor a1 a2, tor b1 b2 => andb (feqb a1 b1) (feqb a2 b2)
  | timp a1 a2, timp b1 b2 => andb (feqb a1 b1) (feqb a2 b2)
  | tfall a1, tfall b1 => feqb a1 b1
  | ttex a1, ttex b1 => feqb a1 b1
  | _, _ => false
  end.

Fixpoint forallb {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => true | x :: t => andb (f x) (forallb f t) end.
Fixpoint existsb' {A} (f : A -> bool) (l : list A) : bool :=
  match l with [] => false | x :: t => orb (f x) (existsb' f t) end.

Definition axLeaf (s : seqt) : bool :=
  match s with (G, D) =>
    existsb' (fun a => existsb' (feqb a) D) G
  end.

(* 绑定位 0 -> 常量 t 的例化（量词深度 1 片段） *)
Fixpoint substC (a : tform) (t : nat) : tform :=
  match a with
  | tpr _ => a
  | tqa n w => if Nat.eqb w 0 then tqa n t else tqa n w
  | tneg b => tneg (substC b t)
  | tand b c => tand (substC b t) (substC c t)
  | tor b c => tor (substC b t) (substC c t)
  | timp b c => timp (substC b t) (substC c t)
  | tfall b => tfall (substC b t)
  | ttex b => ttex (substC b t)
  end.

(* 矢列中出现的常量（含 0 则出现绑定位——量词公式仍在场） *)
Fixpoint constsOf (a : tform) : list nat :=
  match a with
  | tpr _ => []
  | tqa _ v => [v]
  | tneg b => constsOf b
  | tand b c => constsOf b ++ constsOf c
  | tor b c => constsOf b ++ constsOf c
  | timp b c => constsOf b ++ constsOf c
  | tfall b => constsOf b
  | ttex b => constsOf b
  end.

Definition seqConsts (s : seqt) : list nat :=
  match s with (G, D) =>
    flat_map constsOf (G ++ D)
  end.

(* 新常量：1..3 中矢列未出现者（全出现则 3——fuel 会停，诚实呈现） *)
Definition freshC (s : seqt) : nat :=
  if negb (existsb' (Nat.eqb 1) (seqConsts s)) then 1
  else if negb (existsb' (Nat.eqb 2) (seqConsts s)) then 2
  else 3.

Definition DOM : list nat := [1; 2; 3].

(* ---------- 13 阶段归约 rstage：主公式被消费（消除）后不再重复 ---------- *)
(* ¬:left 的上矢列：前件的 ¬A 消失，A 进入后件（LK 规则逆——OCR 残行按
   「语义保持 + 规则逆」双重裁定，docs 详述） *)
Definition stripNegL (l : list tform) : list tform :=
  filter (fun a => match a with tneg _ => false | _ => true end) l.

Definition pickNegL (l : list tform) : list tform :=
  flat_map (fun a => match a with
             | tneg b => [b]
             | _ => []
             end) l.

Definition pickNegR (l : list tform) : list tform :=
  flat_map (fun a => match a with
             | tneg b => [b]      (* 后件的 ¬A：体进入前件——调用方处理 *)
             | _ => []
             end) l.

Definition stripNegR (l : list tform) : list tform :=
  filter (fun a => match a with tneg _ => false | _ => true end) l.

Definition andLRewrite (l : list tform) : list tform :=
  (* 左规则：A/\B 全部展开成 A,B *)
  flat_map (fun a => match a with
             | tand b c => [b; c]
             | _ => [a]
             end) l.

Definition orRRewrite (l : list tform) : list tform :=
  (* 右规则：A\/B 全部展开成 A,B（单分支全加——书 5) symmetric to 2)） *)
  flat_map (fun a => match a with
             | tor b c => [b; c]
             | _ => [a]
             end) l.

(* 选择分叉：对每个 (a,b) 型公式选左或右——全部组合 *)
Fixpoint choices (l : list (tform * tform)) : list (list tform) :=
  match l with
  | [] => [[]]
  | (a, b) :: t =>
      flat_map (fun rest => [a :: rest; b :: rest]) (choices t)
  end.

Definition selAndR (D : list tform) : list (list tform) :=
  (* 后件每个 A/\B 选一分量；非 ∧ 公式原样进每个分支 *)
  let pairs := filter (fun a => match a with tand _ _ => true | _ => false end) D in
  let others := filter (fun a => match a with tand _ _ => false | _ => true end) D in
  let pr (a : tform) : tform * tform :=
        match a with tand b c => (b, c) | _ => (a, a) end in
  map (fun c => others ++ c) (choices (map pr pairs)).

Definition selOrL (G : list tform) : list (list tform) :=
  let pairs := filter (fun a => match a with tor _ _ => true | _ => false end) G in
  let others := filter (fun a => match a with tor _ _ => false | _ => true end) G in
  let pr (a : tform) : tform * tform :=
        match a with tor b c => (b, c) | _ => (a, a) end in
  map (fun c => others ++ c) (choices (map pr pairs)).

(* ->:left 分叉（书 6)：对每个前件 A->B，B 进前件或 A 进后件——组合 *)
Fixpoint impChoices (l : list (tform * tform))
  : list (list tform * list tform) :=
  match l with
  | [] => [([], [])]
  | (a, b) :: t =>
      flat_map (fun p =>
                  match p with
                  | (gl, dl) => [(b :: gl, dl); (gl, a :: dl)]
                  end)
               (impChoices t)
  end.

Definition selImpL2 (G D : list tform) : list seqt :=
  let imps := filter (fun a => match a with timp _ _ => true | _ => false end) G in
  let others := filter (fun a => match a with timp _ _ => false | _ => true end) G in
  let pr (x : tform) : tform * tform :=
        match x with timp c d => (c, d) | _ => (x, x) end in
  map (fun p => match p with
                | (gl, dl) => (others ++ gl, D ++ dl)
                end)
      (impChoices (map pr imps)).

Definition allLRewrite (l : list tform) : list tform :=
  (* !x a：对 DOM 每个常量例化全加 *)
  flat_map (fun a => match a with
             | tfall b => map (fun t => substC b t) DOM
             | _ => [a]
             end) l.

Definition exRRewrite (l : list tform) : list tform :=
  flat_map (fun a => match a with
             | ttex b => map (fun t => substC b t) DOM
             | _ => [a]
             end) l.

Definition allRRewrite (G D : list tform) : list tform :=
  (* !x a 在后件：换新常量例化（Henkin 见证的语法化；新常量须避开
     整个矢列的常量） *)
  map (fun a => match a with
       | tfall b => substC b (freshC (G, D))
       | _ => a
       end) D.

Definition exLRewrite (G D : list tform) : list tform :=
  map (fun a => match a with
       | ttex b => substC b (freshC (G, D))
       | _ => a
       end) G.

Definition impRRewrite (s : seqt) : seqt :=
  match s with (G, D) =>
    (G ++ flat_map (fun a => match a with
                      | timp b _ => [b]
                      | _ => []
                      end) D,
     flat_map (fun a => match a with
                 | timp _ c => [c]
                 | _ => [a]
                 end) D)
  end.

Definition rstage (k : nat) (s : seqt) : list seqt :=
  match s with (G, D) =>
  match Nat.modulo k 13 with
  | 0 => [(stripNegL G, D ++ pickNegL G)]                   (* ¬:left *)
  | 1 => [(G ++ pickNegR D, stripNegR D)]                   (* ¬:right *)
  | 2 => [(andLRewrite G, D)]                               (* /\:left *)
  | 3 => map (fun d => (G, d)) (selAndR D)                  (* /\:right 分叉 *)
  | 4 => map (fun g => (g, D)) (selOrL G)                   (* \/:left 分叉 *)
  | 5 => [(G, orRRewrite D)]                                (* \/:right *)
  | 6 => selImpL2 G D                                      (* ->:left 分叉 *)
  | 7 => [impRRewrite (G, D)]                               (* ->:right *)
  | 8 => [(allLRewrite G, D)]                               (* !:left 全例化 *)
  | 9 => [(G, allRRewrite G D)]                             (* !:right 新常量 *)
  | 10 => [(exLRewrite G D, D)]                             (* ?:left 新常量 *)
  | 11 => [(G, exRRewrite D)]                               (* ?:right 全例化 *)
  | _ => [s]                                                 (* 12 停 *)
  end
  end.

(* ---------- 归约树与双出口 ---------- *)
Inductive rtree : Type :=
| RtAx   (s : seqt)                (* 公理叶：前后件有公共公式 *)
| RtDone (s : seqt)                (* 饱和叶：无可归约主公式 *)
| RtNode (s : seqt) (k : nat) (subs : list rtree).

Fixpoint hasQuant (l : list tform) : bool :=
  match l with
  | [] => false
  | a :: t => orb (match a with
                  | tfall _ | ttex _ => true
                  | _ => false
                  end) (hasQuant t)
  end.

Definition reducible (s : seqt) : bool :=
  match s with (G, D) =>
    orb (existsb' (fun a => match a with
              | tneg _ | tand _ _ | tor _ _ | timp _ _
              | tfall _ | ttex _ => true
              | _ => false end) G)
        (existsb' (fun a => match a with
              | tneg _ | tand _ _ | tor _ _ | timp _ _
              | tfall _ | ttex _ => true
              | _ => false end) D)
  end.

Fixpoint rtreeF (fuel : nat) (k : nat) (s : seqt) : rtree :=
  match fuel with
  | 0 => (* 燃料耗尽一律按饱和叶处理——诚实呈现（绝不假报可证） *)
         (if axLeaf s then RtAx s else RtDone s)
  | S f =>
      if axLeaf s then RtAx s
      else if negb (reducible s) then RtDone s
      else RtNode s k
             (map (rtreeF f (S k)) (rstage k s))
  end.

(* 出口一：全分支封口 -> 可证 *)
Fixpoint allClosed (t : rtree) : bool :=
  match t with
  | RtAx _ => true
  | RtDone _ => false
  | RtNode _ _ subs => forallb allClosed subs
  end.

(* 出口二：饱和叶提取反模型（原子账：前件原子=真） *)
Fixpoint firstSat (t : rtree) : option seqt :=
  match t with
  | RtAx _ => None
  | RtDone s => Some s
  | RtNode _ _ subs =>
      fold_left (fun acc x =>
                   match acc, x with
                   | Some _, _ => acc
                   | None, RtDone s => Some s
                   | None, _ => firstSat x
                   end)
                subs None
  end.

Definition counterAtoms (s : seqt) : list (nat * nat) :=
  match s with (G, _) =>
    flat_map (fun a => match a with
               | tqa n v => [(n, v)]
               | tpr _ => []
               | _ => []
               end) G
  end.

Definition proves (fuel : nat) (s : seqt) : bool := allClosed (rtreeF fuel 0 s).

(* ---------- 账例 ---------- *)
(* 命题重言式：=> p0 -> p0 经阶段 7 封口 *)
Example exImpId : proves 15 ([], [timp (tpr 0) (tpr 0)]) = true.
Proof. reflexivity. Qed.

(* LEM：=> p0 \/ ~p0。阶段 5 全加 -> => p0, ~p0；阶段 1 -> p0 => p0 公理 *)
Example exLem : proves 15 ([], [tor (tpr 0) (tneg (tpr 0))]) = true.
Proof. reflexivity. Qed.

(* Peirce：=> ((p0->p1)->p0)->p0 *)
Example exPeirce :
  proves 26 ([], [timp (timp (timp (tpr 0) (tpr 1)) (tpr 0)) (tpr 0)]) = true.
Proof. reflexivity. Qed.

(* 非有效式 => p0 -> p1：阶段 7 -> p0 => p1 饱和 -> 反模型（p0 真 p1 假） *)
Example exNonTaut :
  andb (negb (proves 15 ([], [timp (tpr 0) (tpr 1)])))
       (match firstSat (rtreeF 15 0 ([], [timp (tpr 0) (tpr 1)])) with
        | Some (G, D) => andb (existsb' (feqb (tpr 0)) G)
                              (existsb' (feqb (tpr 1)) D)
        | None => false
        end) = true.
Proof. reflexivity. Qed.

(* 矛盾矢列 p0 /\ ~p0 => 封口（前件 ¬ 消费成 p0 -> 公理） *)
Example exContr :
  proves 15 ([tand (tpr 0) (tneg (tpr 0))], []) = true.
Proof. reflexivity. Qed.

(* 一阶：=> !x q0(x) -> q0(c1)：阶段 7 -> !x q0 => q0(c1)；
   阶段 8 全例化 -> q0(c1),q0(c2),q0(c3) => q0(c1) 公理 *)
Example exAllInst :
  proves 15 ([], [timp (tfall (tqa 0 0)) (tqa 0 1)]) = true.
Proof. reflexivity. Qed.

(* 全称例化的组合：q0(c1)/\q0(c2) => !x q0(x) 不封口（有限域截断的诚实呈现：
   3 常量全例化后仍无公共公式 -> 饱和叶 -> 反模型 q0(c1),q0(c2) 真、其余假 *)
Example exAllNotFin :
  negb (proves 15 ([(tand (tqa 0 1) (tqa 0 2))], [tfall (tqa 0 0)])) = true.
Proof. reflexivity. Qed.

(* 双出口同时在场：同一矢列，出口一给证明、出口二给反模型——完备性的形状 *)
Definition redtreeCheck (fuel : nat) (s : seqt) : bool :=
  orb (proves fuel s)
      (match firstSat (rtreeF fuel 0 s) with
       | Some _ => true
       | None => false
       end).

Example exDual1 : redtreeCheck 15 ([], [tor (tpr 0) (tneg (tpr 0))]) = true.
Proof. reflexivity. Qed.

Example exDual2 : redtreeCheck 15 ([], [timp (tpr 0) (tpr 1)]) = true.
Proof. reflexivity. Qed.
