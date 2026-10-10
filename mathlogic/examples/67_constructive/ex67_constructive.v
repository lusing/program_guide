(* ex67_constructive.v —— 构造性与 Heyting 语义（Müller-Stach ch6/ch9）
   机器件：Gödel–Gentzen 双否定 FOL 翻译器（七行规则）+「翻译保持
   经典意义」全枚举账；Coq 直觉语境样本（tauto 不碰 Classic，
   Print Assumptions = Closed）；Sierpinski 型下集拓扑开集格上的
   Heyting 蕴含/否定——¬¬U≠U（弱排中失败）与 ¬A∨B ⊆ A→B 账本；
   布尔/Heyting 同格对照；四平方构造搜索器（构造性存在=算法给出
   见证）。Brouwer 连续性、χ_Q、Hilbert 1899 信记文档线。 *)

From Stdlib Require Import List Arith Lia.
Import ListNotations.

(* ---------- 1. Gödel–Gentzen 双否定翻译（FOL 七行） ---------- *)

Inductive form : Type :=
| atom (b : nat)              (* 原子 P_b *)
| ffalse                      (* ⊥ *)
| fand (a b : form)
| for_ (a b : form)
| fimp (a b : form)
| fall (a : form)             (* ∀x. a —— 演示用单变量 *)
| fex (a : form).             (* ∃x. a *)

(* 翻译规则（书 p97 全表）：
   Pⁿ=¬¬P  ⊥ⁿ=⊥  (a∧b)ⁿ=aⁿ∧bⁿ  (a∨b)ⁿ=¬(¬aⁿ∧¬bⁿ)
   (a→b)ⁿ=aⁿ→bⁿ  (∀x a)ⁿ=∀x aⁿ  (∃x a)ⁿ=¬∀x¬aⁿ *)
Fixpoint nnF (a : form) : form :=
  match a with
  | atom b => fimp (fimp (atom b) ffalse) ffalse   (* ¬¬P *)
  | ffalse => ffalse
  | fand x y => fand (nnF x) (nnF y)
  | for_ x y => fimp (fand (fimp (nnF x) ffalse)
                           (fimp (nnF y) ffalse)) ffalse
  | fimp x y => fimp (nnF x) (nnF y)
  | fall x => fall (nnF x)
  | fex x => fimp (fall (fimp (nnF x) ffalse)) ffalse
  end.

(* 经典语义（布尔论域量词——24 章前束范式招）：量词变量作赋值位 0 *)
Fixpoint evF (a : form) (v : list bool) : bool :=
  match a with
  | atom b => nth b v false
  | ffalse => false
  | fand x y => andb (evF x v) (evF y v)
  | for_ x y => orb (evF x v) (evF y v)
  | fimp x y => implb (evF x v) (evF y v)
  | fall x => andb (evF x (false :: v)) (evF x (true :: v))
  | fex x => orb (evF x (false :: v)) (evF x (true :: v))
  end.

(* 账本一：翻译保持经典意义（样本公式 × 全部 4 赋值逐位相等） *)
Definition samples : list form :=
  [ atom 0
  ; fimp (atom 0) (atom 0)
  ; for_ (atom 0) (fimp (atom 0) ffalse)      (* P ∨ ¬P *)
  ; fand (atom 0) (atom 1)
  ; fimp (fand (atom 0) (atom 1)) (atom 0)
  ; fex (atom 0)
  ; fall (for_ (atom 0) (atom 1))
  ; for_ (fand (atom 0) (atom 1)) (fand (atom 1) (atom 0)) ].

Definition asg4 : list (list bool) :=
  [[false;false];[false;true];[true;false];[true;true]].

Example nn_preserves_classical :
  forallb (fun f => forallb (fun v => Bool.eqb (evF (nnF f) v) (evF f v)) asg4)
          samples
  = true.
Proof. reflexivity. Qed.
(* 翻译不改变经典真值——改变的只是「证明的形状」：∨ 与 ∃ 被
   压成 ¬(¬∧¬) 与 ¬∀¬，经典推理里的「分情况」与「见证」在
   直觉侧变成「不可能双方都无见证」。 *)

(* ---------- 2. Coq 的直觉语境：tauto 不碰 Classic ---------- *)

(* Coq 的 CIC 本身是直觉系统——tauto/auto 不调用排中。
   翻译器每步产生 ¬¬ 形状；两个直觉可证的关键账： *)

Example triple_neg : forall P : Prop, ~ ~ ~ P -> ~ P.
Proof. tauto. Qed.

Example kripke_lemma : forall P Q : Prop, ~ ~ P -> ~ ~ Q -> ~ ~ (P /\ Q).
Proof. tauto. Qed.

Print Assumptions triple_neg.    (* Closed under global context *)
Print Assumptions kripke_lemma.  (* Closed under global context *)
(* 对照：~~P -> P 若强行证明必引入 Classic——文档线（16 章两世界
   反例的 Prop 版）；Gödel–Gentzen 定理说：DPA 的每条定理翻成 ⁿ
   形状后 Heyting 算术 HA 全部接得住——两个算术等一致。 *)

(* ---------- 3. Sierpinski 型开集格上的 Heyting 语义 ---------- *)

(* 3 点偏序 0<1<2 的下集拓扑：开集 = 下集（Alexandrov）。
   开集表示=3 位布尔表 [位0;位1;位2]。
   OPENS = 000,100,110,111（∅,{0},{0,1},{0,1,2}） *)
Definition OPENS : list (list bool) :=
  [ [false; false; false]; [true; false; false];
    [true; true; false]; [true; true; true] ].

Fixpoint eqL (u v : list bool) : bool :=
  match u, v with
  | [], [] => true
  | x :: t, y :: t' => andb (Bool.eqb x y) (eqL t t')
  | _, _ => false
  end.

Definition subL (a b : list bool) : bool :=
  (* 长度守卫：combine 对长度不齐会静默截断、空对照恒真 *)
  andb (Nat.eqb (length a) (length b))
       (forallb (fun p => implb (fst p) (snd p)) (combine a b)).

Fixpoint cupL (a b : list bool) : list bool :=
  match a, b with
  | [], r => r | r, [] => r    (* 空侧的并=另一方（∪ 的单位元） *)
  | x :: t, y :: t' => orb x y :: cupL t t'
  end.

Definition negL1 (a : list bool) : list bool := map negb a.

(* interior(x) = ⊆x 的最大开集：枚举 OPENS 求并 *)
Definition intL (x : list bool) : list bool :=
  fold_left (fun acc o => if subL o x then cupL acc o else acc) OPENS [].

Definition negL (a : list bool) : list bool := intL (negL1 a).
Definition impL (a b : list bool) : list bool :=
  intL (cupL (negL1 a) b).    (* A→B = int(Aᶜ ∪ B) *)

(* 账本：¬¬110 = 111 ≠ 110 —— 弱排中 ¬¬U→U 失败现场 *)
Example heyting_weak_law :
  andb (eqL (negL (negL [true; true; false])) [true; true; true])
       (negb (eqL (negL (negL [true; true; false])) [true; true; false]))
  = true.
Proof. reflexivity. Qed.
(* U={0,1}=[T;T;F]：¬U=int([F;F;T])=[]（{2} 非下集，内部为空）；
   ¬¬U=int([T;T;T])=全集。布尔代数里 ¬¬U=U 恒真；开集格只有
   U ≤ ¬¬U 单向——「Heyting 只有不等式，布尔才有等式」（书
   p34 表述）的机器现场。 *)

(* 账本：¬A∨B ≤ A→B（经典等式降级为格中不等式），全 16 对开集 *)
Example heyting_le :
  forallb (fun ab => subL (cupL (negL (fst ab)) (snd ab))
                         (impL (fst ab) (snd ab)))
          (flat_map (fun a => map (fun b => (a, b)) OPENS) OPENS)
  = true.
Proof. reflexivity. Qed.

(* 真不等样本：A={0}、B={0,1} 时 ¬A∨B=B 而 A→B=全集——
   弱侧够不到强侧的顶 *)
Example heyting_neq :
  andb (eqL (cupL (negL [true; false; false]) [true; true; false])
            [true; true; false])
       (eqL (impL [true; false; false] [true; true; false])
            [true; true; true])
  = true.
Proof. reflexivity. Qed.

(* 布尔/Heyting 同格对照：布尔补（逐位取反）vs Heyting 否定（补的内部） *)
Example bool_vs_heyting :
  map (fun a => (negL1 a, negL a)) OPENS
  = [ ([true; true; true], [true; true; true]);
      ([false; true; true], [false; false; false]);
      ([false; false; true], [false; false; false]);
      ([false; false; false], [false; false; false]) ].
Proof. reflexivity. Qed.
(* 读法：布尔补在 {0}=[T;F;F] 处给 {1,2}；Heyting 否定给 ∅
   ——{1,2} 不是开集，内部坍缩为空。同一格、两种否定，经典
   与直觉的分野全部浓缩在这两列。 *)

(* ---------- 4. 四平方：构造性存在的机器面 ---------- *)

(* 构造语境的「∃n. Σa²=n」必须交出见证——搜索器就是见证工厂。
   直接枚举（a≤b≤c≤d ≤ n 的四元组），首个平方和命中即见证 *)
(* 四元组表示 (a,(b,(c,d)))——× 右结合，全部走显式投影
   （64 章/上轮 CHEATSheet 的老坑：嵌套积的 let-解构在某些
   推断路径下报「非单构造子」） *)
Definition sq4 (t : nat * (nat * (nat * nat))) : nat :=
  fst t * fst t + fst (snd t) * fst (snd t)
  + fst (snd (snd t)) * fst (snd (snd t))
  + snd (snd (snd t)) * snd (snd (snd t)).

Definition quadOK (n : nat) (t : nat * (nat * (nat * nat))) : bool :=
  Nat.eqb (sq4 t) n.

Definition quads (n : nat) : list (nat * (nat * (nat * nat))) :=
  flat_map (fun a => flat_map (fun b => flat_map (fun c =>
      map (fun d => (a, (b, (c, d)))) (seq c (S (n - c))))
      (seq b (S (n - b))))
    (seq a (S (n - a)))) (seq 0 (S n)).

Definition lagrange4 (n : nat) : option (nat * (nat * (nat * nat))) :=
  find (quadOK n) (quads n).

(* 1..24 全部交出见证且恒等式成立 *)
Example four_squares_ledger :
  forallb (fun n => match lagrange4 n with
                    | Some t => quadOK n t
                    | None => false
                    end) (seq 1 24)
  = true.
Proof. reflexivity. Qed.
(* Lagrange 定理（1770）的「存在」在经典证明里走下降归纳；
   构造语境要的是每个具体 n 的 (a,b,c,d)——搜索器全部交出。
   存在陈述的两种面目：证明它真 vs 造出见证。 *)

(* 冒烟 *)
Compute (map lagrange4 [1; 2; 3; 7; 23]).
Compute (negL [true; true; false], impL [true; false; false] [true; false; false]).
