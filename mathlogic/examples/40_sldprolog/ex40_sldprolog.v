(* ex40 —— SLD 与逻辑编程语义（Ben-Ari 3e ch11 + 2e §8.3/8.5 精选）
   从 20 章 T_P 语义到 Prolog 工程化之间的桥梁是 SLD 消解：
     计算规则（选哪个原子）——**独立性**：fair 规则下，可解出的
       答案集不依赖选元（3e 定理 11.x 的实例级机器版）；
     搜索规则（选哪个子句）——决定解的次序与完备性（Prolog 的
       DFS 会掉进无穷支——文档级）。
   cut/NAF/CWA/CLP 的现场在 Prolog 通道（ex40_sldprolog.pl）。

   机器件：常量+变元的最小合一 → SLD 步（子句变元换新鲜）→
   sldAll 枚举答案 → 最左/最右两条计算规则 → 实例级独立性
   （同一程序同一目标，答案集相等，reflexivity 直收）。 *)

From Stdlib Require Import List Bool Arith Lia.
Import ListNotations.

(* ---------- 项与原子（常量+变元；祖先例够用） ---------- *)

Inductive tm : Type :=
| VC : nat -> tm      (* 常量 c_i *)
| VV : nat -> tm.     (* 变元 x_i *)

Definition atom := (nat * list tm)%type.     (* p(t1..tn) *)
Definition clause := (atom * list atom)%type.  (* 头 :- 体 *)
Definition goal := list atom.

(* ---------- 最小合一 ---------- *)

Definition sub := list (nat * tm).

Fixpoint tsub (s : sub) (t : tm) : tm :=
  match t with
  | VV x => match find (fun p => Nat.eqb (fst p) x) s with
            | Some (_, t') => t' | None => t end
  | VC _ => t
  end.

Fixpoint asub (s : sub) (a : atom) : atom :=
  (fst a, map (tsub s) (snd a)).

Fixpoint gsub (s : sub) (g : goal) : goal := map (asub s) g.

Fixpoint unify (t u : tm) : option sub :=
  match t, u with
  | VC a, VC b => if Nat.eqb a b then Some [] else None
  | VV x, VV y => if Nat.eqb x y then Some [] else Some [(x, VV y)]
  | VV x, u => Some [(x, u)]
  | t, VV y => Some [(y, t)]
  end.

Fixpoint unifyL (s : sub) (l1 l2 : list tm) : option sub :=
  match l1, l2 with
  | [], [] => Some s
  | t1 :: r1, t2 :: r2 =>
      match unify (tsub s t1) (tsub s t2) with
      | Some s1 => unifyL (s1 ++ s) r1 r2
      | None => None
      end
  | _, _ => None
  end.

Fixpoint unifyA (a b : atom) : option sub :=
  if Nat.eqb (fst a) (fst b) then unifyL [] (snd a) (snd b) else None.

(* ---------- 子句变元换新鲜（偏移 k：x_i ↦ x_{i+k}） ---------- *)

Fixpoint toff (k : nat) (t : tm) : tm :=
  match t with
  | VV x => VV (k + x)
  | VC _ => t
  end.

Definition aoff (k : nat) (a : atom) : atom := (fst a, map (toff k) (snd a)).
Definition coff (k : nat) (c : clause) : clause :=
  (aoff k (fst c), map (aoff k) (snd c)).

(* ---------- SLD 一步与答案枚举 ---------- *)

Fixpoint remove_first (i : nat) (g : goal) : goal :=
  match i, g with
  | 0, _ :: g' => g'
  | S j, a :: g' => a :: remove_first j g'
  | _, [] => []
  end.



Definition resolve (c : clause) (g : goal) (i : nat) (k : nat)
  : option (goal * sub) :=
  (* 用换新鲜后的子句在位置 i 归结 *)
  let (h, body) := coff k c in
  match nth_error g i with
  | None => None
  | Some sel =>
      match unifyA sel h with
      | Some s => Some (gsub s (body ++ (remove_first i g)), s)
      | None => None
      end
  end.

(* 枚举全部答案（DFS 按子句序；答案 = 沿链累积的代换） *)
Fixpoint sldAll (fuel : nat) (rule : nat -> nat) (P : list clause)
                (k : nat) (g : goal) (acc : sub) : list sub :=
  match fuel with
  | 0 => []
  | S fr =>
      match g with
      | [] => [acc]
      | _ =>
          let i := rule (length g) in
          flat_map (fun c =>
            match resolve c g i k with
            | Some (g', s) => sldAll fr rule P (S k + length P) g' (s ++ acc)
            | None => []
            end) P
      end
  end.

Definition leftmost (n : nat) : nat := 0.
Definition rightmost (n : nat) : nat := n - 1.

(* ---------- 现场程序（2e 例 8.19 的祖先族谱） ---------- *)

Definition aConst := 100.  (* 常量 c_100..c_107：8 个人名 *)
Definition bob := VC 100. Definition allen := VC 101.
Definition fred := VC 102. Definition dave := VC 103.
Definition catherine := VC 104. Definition george := VC 105.
Definition ellen := VC 106. Definition harry := VC 107.

Definition parentXY : atom := (1, [VV 0; VV 1]).
Definition ancXY : atom := (2, [VV 0; VV 1]).
Definition ancXZ : atom := (2, [VV 0; VV 2]).
Definition ancZY : atom := (2, [VV 2; VV 1]).
Definition parXZ : atom := (1, [VV 0; VV 2]).

Definition progA : list clause :=
  [ (ancXY, [parentXY]);                     (* ancestor(X,Y) :- parent(X,Y). *)
    (ancXY, [parXZ; ancZY]) ]             (* ancestor(X,Y) :- parent(X,Z), ancestor(Z,Y). *)
  ++ map (fun pr => ((1, [fst pr; snd pr]), []))
       [ (bob, allen); (fred, dave); (catherine, allen)
       ; (harry, george); (dave, bob); (ellen, bob) ].

(* 答案的显示版：把 X（x_0）追到常量（沿换名链） *)
Fixpoint chaseX (fuel : nat) (s : sub) (x : nat) : option nat :=
  match fuel with
  | 0 => None
  | S fr => match find (fun p => Nat.eqb (fst p) x) s with
            | Some (_, VC c) => Some c
            | Some (_, VV y) => chaseX fr s y
            | None => None
            end
  end.

Definition ansX (s : sub) : option nat := chaseX 20 s 0.

Fixpoint answersX (l : list sub) : list (option nat) :=
  map ansX l.

(* 目标：ancestor(X, bob) —— 两种计算规则，同一答案集 *)
Definition goalG : goal := [(2, [VV 0; bob])].

(* 集合相等（去重比较） *)
Fixpoint nodupb (l : list (option nat)) : list (option nat) :=
  match l with
  | [] => []
  | x :: l' => if existsb (fun y => match x, y with
                                    | Some a, Some b => Nat.eqb a b
                                    | None, None => true
                                    | _, _ => false end) (nodupb l')
               then nodupb l' else x :: nodupb l'
  end.

Definition setEqA (l1 l2 : list (option nat)) : bool :=
  let d1 := nodupb l1 in let d2 := nodupb l2 in
  (forallb (fun x => existsb (fun y => match x, y with
                                       | Some a, Some b => Nat.eqb a b
                                       | None, None => true
                                       | _, _ => false end) d2) d1)
  && (forallb (fun x => existsb (fun y => match x, y with
                                          | Some a, Some b => Nat.eqb a b
                                          | None, None => true
                                          | _, _ => false end) d1) d2).

(* 独立性（实例级）：最左与最右选元解出同一答案集
   —— {dave=103, ellen=106, fred=102} *)
Example indep_left_answers :
  answersX (sldAll 30 leftmost progA 10 goalG [])
  = [Some 103; Some 106; Some 102].
Proof. reflexivity. Qed.

Example indep_right_answers :
  answersX (sldAll 30 rightmost progA 10 goalG [])
  = [Some 103; Some 106; Some 102].
Proof. reflexivity. Qed.

Example indep_sld : setEqA (answersX (sldAll 30 leftmost progA 10 goalG []))
                         (answersX (sldAll 30 rightmost progA 10 goalG [])) = true.
Proof. reflexivity. Qed.
