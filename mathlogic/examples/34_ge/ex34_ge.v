(* ex34_ge.v —— 广义消去规则与高层次规则（Schroeder-Heister 篇，书 ch1）
   机器件：极小逻辑 {原子,∧,→} 的推导 AST，三套消去系统并存——
   (1) MP 系：标准 ∧E1/∧E2 与 →E（modus ponens）；
   (2) GEN 系：∧EGEN（从 A∧B 与 [A,B]⊢C 得 C）+ →ESL（层 3：从 A→B、
       A、[B]⊢C 得 C——Dyckhoff/Tennant/López-Escobar/von Plato）；
   (3) HL 系：→EHL（层 4）——副前提假设的是**规则** A⇒B（dRule 把
       规则假设用起来）；层 1=公式、层 α+1=(R₁..Rₙ)⇒A。
   六个翻译函数把书 §1-§4 的等价论证程序化（替换假设/替换规则应用），
   逐条断言保判断；类型驱动的 β 收缩（坐标由 typeOf 喂入）+正规形+
   子公式性；和谐账本：β（局部可靠）与 η（局部完备）在引入形上互逆。
   零公理。坑位速记见 docs/34-ge.md。 *)

From Stdlib Require Import List Arith Bool.
Import ListNotations.

(* ---------- 1. 公式、上下文条目 ---------- *)

Inductive form : Type :=
| atom (n : nat)
| fand (a b : form)
| fimp (a b : form).

(* 上下文条目：公式假设 EF，或**规则假设** ER a b（读作 a ⇒ b）。
   ——高层次演算的核心：规则像公式一样可被假设、被卸除。 *)
Inductive entry : Type :=
| EF (a : form)
| ER (a b : form).

Fixpoint eqF (x y : form) : bool :=
  match x, y with
  | atom n, atom m => Nat.eqb n m
  | fand x1 x2, fand y1 y2 => andb (eqF x1 y1) (eqF x2 y2)
  | fimp x1 x2, fimp y1 y2 => andb (eqF x1 y1) (eqF x2 y2)
  | _, _ => false
  end.

Fixpoint inCtx (e : entry) (G : list entry) : bool :=
  match G with
  | [] => false
  | x :: t =>
      match e, x with
      | EF a, EF b => eqF a b
      | ER a1 b1, ER a2 b2 => andb (eqF a1 a2) (eqF b1 b2)
      | _, _ => false
      end || inCtx e t
  end.

(* ---------- 2. 推导 AST：三套消去系统并存 ---------- *)

(* dRule x y d1：把语境中的规则假设 (x ⇒ y) 应用在 d1 : x 上得 y。
   规则假设只经 dRule 显形——「应用规则=同时假设它」的形式化。 *)
Inductive der : Type :=
| dHyp (a : form)
| dRule (x y : form) (d1 : der)
| dAndI (d1 d2 : der)
| dImpI (x : form) (d : der)
| dAndE1 (d : der)
| dAndE2 (d : der)
| dMP (d1 d2 : der)
| dAndGEN (d0 d : der)
| dImpSL (d0 d1 d : der)
| dImpHL (d0 d : der).

(* ---------- 3. 类型演算 typeOf：单公式返回（良型则恰一个） ---------- *)

Fixpoint typeOf (G : list entry) (d : der) : list form :=
  match d with
  | dHyp a => if inCtx (EF a) G then [a] else []
  | dRule x y d1 =>
      if andb (inCtx (ER x y) G)
              (match typeOf G d1 with [z] => eqF z x | _ => false end)
      then [y] else []
  | dAndI d1 d2 =>
      match typeOf G d1, typeOf G d2 with
      | [x], [y] => [fand x y] | _, _ => [] end
  | dImpI x d =>
      match typeOf (EF x :: G) d with
      | [y] => [fimp x y] | _ => [] end
  | dAndE1 d => match typeOf G d with [fand x _] => [x] | _ => [] end
  | dAndE2 d => match typeOf G d with [fand _ y] => [y] | _ => [] end
  | dMP d1 d2 =>
      match typeOf G d1, typeOf G d2 with
      | [fimp x y], [x'] => if eqF x x' then [y] else []
      | _, _ => [] end
  | dAndGEN d0 d =>
      match typeOf G d0 with
      | [fand x y] => typeOf (EF x :: EF y :: G) d
      | _ => [] end
  | dImpSL d0 d1 d =>
      match typeOf G d0, typeOf G d1 with
      | [fimp x y], [x'] => if eqF x x' then typeOf (EF y :: G) d else []
      | _, _ => [] end
  | dImpHL d0 d =>
      match typeOf G d0 with
      | [fimp x y] => typeOf (ER x y :: G) d
      | _ => [] end
  end.

Definition wtdOK (G : list entry) (d : der) (c : form) : bool :=
  match typeOf G d with [x] => eqF x c | _ => false end.

(* ---------- 4. 两个替换：翻译与收缩的发动机 ---------- *)

(* substF a E d：把 d 中所有「公式假设 a」的出现换成 E
   （样本避开同名再绑定——Barendregt 约定的教学简化）。 *)
Fixpoint substF (a : form) (E : der) (d : der) : der :=
  match d with
  | dHyp b => if eqF a b then E else dHyp b
  | dRule x y d1 => dRule x y (substF a E d1)
  | dAndI d1 d2 => dAndI (substF a E d1) (substF a E d2)
  | dImpI x d1 => dImpI x (substF a E d1)
  | dAndE1 d1 => dAndE1 (substF a E d1)
  | dAndE2 d1 => dAndE2 (substF a E d1)
  | dMP d1 d2 => dMP (substF a E d1) (substF a E d2)
  | dAndGEN d0 d1 => dAndGEN (substF a E d0) (substF a E d1)
  | dImpSL d0 d1 d2 =>
      dImpSL (substF a E d0) (substF a E d1) (substF a E d2)
  | dImpHL d0 d1 => dImpHL (substF a E d0) (substF a E d1)
  end.

(* substR x y D1 d：把 d 中所有**规则假设 (x⇒y) 的应用点** dRule x y d1
   换成 C:=y 的平凡 →ESL：dImpSL D1 d1 (dHyp y)（书 p.25 构造 (3)）。 *)
Fixpoint substR (x y : form) (D1 : der) (d : der) : der :=
  match d with
  | dHyp b => dHyp b
  | dRule u v d1 =>
      if andb (eqF x u) (eqF y v)
      then dImpSL D1 (substR x y D1 d1) (dHyp y)
      else dRule u v (substR x y D1 d1)
  | dAndI d1 d2 => dAndI (substR x y D1 d1) (substR x y D1 d2)
  | dImpI u d1 => dImpI u (substR x y D1 d1)
  | dAndE1 d1 => dAndE1 (substR x y D1 d1)
  | dAndE2 d1 => dAndE2 (substR x y D1 d1)
  | dMP d1 d2 => dMP (substR x y D1 d1) (substR x y D1 d2)
  | dAndGEN d0 d1 => dAndGEN (substR x y D1 d0) (substR x y D1 d1)
  | dImpSL d0 d1 d2 =>
      dImpSL (substR x y D1 d0) (substR x y D1 d1) (substR x y D1 d2)
  | dImpHL d0 d1 => dImpHL (substR x y D1 d0) (substR x y D1 d1)
  end.

(* ---------- 5. 六个翻译（书 §1-§4 构造的程序化） ---------- *)

Notation p := (atom 0).
Notation q := (atom 1).

(* (i) ESL 的恒等副前提就是 MP（书 p.23 反向：→ESL ⊢ →EMP） *)
Definition mpFromEsl (x y : form) (D1 D2 : der) : der :=
  dImpSL D1 D2 (dHyp y).

(* (ii) MP 的替换论证（书 p.23 正向：→EMP ⊢ →ESL 实例）——
   把副前提 d 里的 y 假设全换成 MP(D1,D2) *)
Definition mpDerivesEsl (y : form) (D1 D2 d : der) : der :=
  substF y (dMP D1 D2) d.

(* (iii) ESL 化 HL（书 p.24：B 假设换成规则应用点） *)
Definition hlFromEsl (x y : form) (D1 D2 d : der) : der :=
  dImpHL D1 (substF y (dRule x y D2) d).

(* (iv) HL 化 ESL（书 p.25：规则应用点全换成 C:=y 的平凡 ESL） *)
Definition eslFromHl (x y : form) (D1 d : der) : der :=
  substR x y D1 d.

(* (v)(vi) ∧E ↔ ∧EGEN（书 p.6：实例化 C:=A 与替换论证） *)
Definition andFromGenL (x y : form) (D0 : der) : der := dAndGEN D0 (dHyp x).
Definition andFromGenR (x y : form) (D0 : der) : der := dAndGEN D0 (dHyp y).
Definition genFromAnd (x y : form) (D0 d : der) : der :=
  dAndGEN D0 (substF x (dAndE1 D0) (substF y (dAndE2 D0) d)).

(* ---------- 6. 类型驱动的 β 收缩 ---------- *)

Fixpoint derEqb (d e : der) : bool :=
  match d, e with
  | dHyp a, dHyp b => eqF a b
  | dRule x1 y1 d1, dRule x2 y2 e1 =>
      andb (eqF x1 x2) (andb (eqF y1 y2) (derEqb d1 e1))
  | dAndI a1 b1, dAndI a2 b2 => andb (derEqb a1 a2) (derEqb b1 b2)
  | dImpI x1 d1, dImpI x2 e1 => andb (eqF x1 x2) (derEqb d1 e1)
  | dAndE1 d1, dAndE1 e1 => derEqb d1 e1
  | dAndE2 d1, dAndE2 e1 => derEqb d1 e1
  | dMP a1 b1, dMP a2 b2 => andb (derEqb a1 a2) (derEqb b1 b2)
  | dAndGEN a1 b1, dAndGEN a2 b2 => andb (derEqb a1 a2) (derEqb b1 b2)
  | dImpSL a1 b1 c1, dImpSL a2 b2 c2 =>
      andb (derEqb a1 a2) (andb (derEqb b1 b2) (derEqb c1 c2))
  | dImpHL a1 b1, dImpHL a2 b2 => andb (derEqb a1 a2) (derEqb b1 b2)
  | _, _ => false
  end.

(* 红ex四型；收缩需要的**公式坐标**（绑定式/前后件/左右成分）由
   typeOf 在红ex现场喂入——纯语法反查不可靠（顶构造不含坐标）。 *)
Inductive redex : Type :=
| rMP (x : form) (db d1 : der)
| rSL (x y : form) (db d1 d : der)
| rHL (x y : form) (db d : der)
| rAG (x y : form) (d1 d2 d : der).

Definition contract (r : redex) : der :=
  match r with
  | rMP x db d1 => substF x d1 db
  | rSL x y db d1 d => substF y (substF x d1 db) d
  | rHL x y db d => substR x y (dImpI x db) d
  | rAG x y d1 d2 d => substF x d1 (substF y d2 d)
  end.

Definition ty1 (G : list entry) (d : der) (fb : form) : form :=
  match typeOf G d with [z] => z | _ => fb end.

(* beta1 G d：在语境 G 下找**顶**红ex并收缩；下穿引入规则时语境
   随之扩张——坐标正确性全靠这一步（GC 期「下穿加绑定」坑位）。 *)
Fixpoint beta1 (G : list entry) (d : der) : der :=
  match d with
  | dMP d1 d2 =>
      match d1 with
      | dImpI x db => substF x d2 db
      | _ => dMP (beta1 G d1) (beta1 G d2)
      end
  | dAndE1 d => match d with dAndI d1 _ => d1 | _ => dAndE1 (beta1 G d) end
  | dAndE2 d => match d with dAndI _ d2 => d2 | _ => dAndE2 (beta1 G d) end
  | dAndGEN d0 d =>
      match d0 with
      | dAndI d1 d2 =>
          substF (ty1 G d1 p) d1 (substF (ty1 G d2 q) d2 d)
      | _ => match typeOf G d0 with
             | [fand x y] => dAndGEN (beta1 G d0) (beta1 (EF x :: EF y :: G) d)
             | _ => dAndGEN (beta1 G d0) (beta1 G d)
             end
      end
  | dImpSL d0 d1 d =>
      match d0 with
      | dImpI x db =>
          substF (ty1 (EF x :: G) db q) (substF x d1 db) d
      | _ => match typeOf G d0 with
             | [fimp x y] =>
                 dImpSL (beta1 G d0) (beta1 G d1) (beta1 (EF y :: G) d)
             | _ => dImpSL (beta1 G d0) (beta1 G d1) (beta1 G d)
             end
      end
  | dImpHL d0 d =>
      match d0 with
      | dImpI x db =>
          let y := ty1 (EF x :: G) db q in
          substR x y (dImpI x db) d
      | _ => match typeOf G d0 with
             | [fimp x y] => dImpHL (beta1 G d0) (beta1 (ER x y :: G) d)
             | _ => dImpHL (beta1 G d0) (beta1 G d)
             end
      end
  | dImpI x d1 => dImpI x (beta1 (EF x :: G) d1)
  | dRule x y d1 => dRule x y (beta1 G d1)
  | dAndI d1 d2 => dAndI (beta1 G d1) (beta1 G d2)
  | dHyp a => dHyp a
  end.

Fixpoint normalize (fuel : nat) (d : der) : der :=
  match fuel with
  | 0 => d
  | S k => let d' := beta1 [] d in
           if derEqb d d' then d' else normalize k d'
  end.

(* ---------- 7. 断言电池 ---------- *)

Definition imp_pq : form := fimp p q.
Definition G0 : list entry := [EF imp_pq; ER p q; EF p; EF q].

(* 电一：三系统同一判断——p→q, p ⊢ q 的三种推导 *)
Definition mpD  : der := dMP (dHyp imp_pq) (dHyp p).
Definition eslD : der := dImpSL (dHyp imp_pq) (dHyp p) (dHyp q).
Definition hlD  : der := dImpHL (dHyp imp_pq) (dRule p q (dHyp p)).

Example three_systems_same :
  andb (wtdOK G0 mpD q)
       (andb (wtdOK G0 eslD q) (wtdOK G0 hlD q)) = true.
Proof. vm_compute. reflexivity. Qed.

(* 电二：翻译保判断+形状对齐。
   (iv) HL 化 ESL：规则应用点换成平凡 ESL——输出应恰是 eslD，
   且不再需要规则假设（语境里没有 ER 也良型） *)
Example esl_from_hl_shape :
  andb (derEqb (eslFromHl p q (dHyp imp_pq) (dRule p q (dHyp p))) eslD)
       (wtdOK [EF imp_pq; EF p]
              (eslFromHl p q (dHyp imp_pq) (dRule p q (dHyp p))) q)
  = true.
Proof. vm_compute. reflexivity. Qed.

(* (iii) ESL 化 HL：B 假设换成规则应用点——输出应恰是 hlD *)
Example hl_from_esl_shape :
  derEqb (hlFromEsl p q (dHyp imp_pq) (dHyp p) (dHyp q)) hlD = true.
Proof. vm_compute. reflexivity. Qed.

(* (i) ESL 的恒等副前提即 MP：(→ESL) ⊢ (→EMP) 逐实例 *)
Example mp_from_esl :
  derEqb (mpFromEsl p q (dHyp imp_pq) (dHyp p)) eslD = true.
Proof. vm_compute. reflexivity. Qed.

(* (ii) MP 替换论证：q∧q 从 [q]——换掉 q 假设后无须 q 在语境 *)
Definition D3qq : der := dAndI (dHyp q) (dHyp q).
Example mp_derives_esl :
  andb (derEqb (mpDerivesEsl q (dHyp imp_pq) (dHyp p) D3qq)
               (dAndI mpD mpD))
       (wtdOK [EF imp_pq; EF p] (mpDerivesEsl q (dHyp imp_pq) (dHyp p) D3qq)
              (fand q q))
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 电三：GE 绕道 β。G=[p;q]，∧I 主前提 + ∧EGEN 副前提 [p,q]⊢p∧q *)
Definition Gpq : list entry := [EF p; EF q].
Definition genDetour : der :=
  dAndGEN (dAndI (dHyp p) (dHyp q)) (dAndI (dHyp p) (dHyp q)).

Example gen_beta :
  derEqb (normalize 30 genDetour) (dAndI (dHyp p) (dHyp q)) = true.
Proof. vm_compute. reflexivity. Qed.

(* 电四：→ESL 绕道 β（类型驱动坐标：y 由 typeOf (EF p::G) db 给出）。
   主前提 →I 的体 db := MP(imp_pq, 绑定的 p)（真用 p，非退化）；
   副前提 [q] ⊢ q∧q。收缩 = q 假设换成「db 喂入 d1」。 *)
Definition db_pq : der := dMP (dHyp imp_pq) (dHyp p).
Definition slDetour : der :=
  dImpSL (dImpI p db_pq) (dHyp p) (dAndI (dHyp q) (dHyp q)).

Example sl_beta :
  derEqb (normalize 30 slDetour) (dAndI db_pq db_pq) = true.
Proof. vm_compute. reflexivity. Qed.

(* 电五：→EHL 绕道 β（规则应用点换成平凡 ESL，再被 ESL 绕道收缩
   吸收——两步账：HL 红ex先消，留一个 SL 红ex） *)
Definition hlDetour : der :=
  dImpHL (dImpI p db_pq) (dRule p q (dMP (dHyp imp_pq) (dHyp p))).

Example hl_beta :
  derEqb (normalize 30 hlDetour) (dMP (dHyp imp_pq) db_pq) = true.
Proof. vm_compute. reflexivity. Qed.

(* 电六：子公式性——β 后推导里只出现端式（p∧q）的子公式 *)
Fixpoint subF (a c : form) : bool :=
  match a with
  | atom _ => eqF a c
  | fand x y => eqF a c || orb (subF x c) (subF y c)
  | fimp x y => eqF a c || orb (subF x c) (subF y c)
  end.

Fixpoint formsIn (d : der) : list form :=
  match d with
  | dHyp a => [a]
  | dRule x y d1 => x :: y :: formsIn d1
  | dAndI d1 d2 => formsIn d1 ++ formsIn d2
  | dImpI x d1 => x :: formsIn d1
  | dAndE1 d1 => formsIn d1
  | dAndE2 d1 => formsIn d1
  | dMP d1 d2 => formsIn d1 ++ formsIn d2
  | dAndGEN d0 d1 => formsIn d0 ++ formsIn d1
  | dImpSL d0 d1 d2 => formsIn d0 ++ formsIn d1 ++ formsIn d2
  | dImpHL d0 d1 => formsIn d0 ++ formsIn d1
  end.

Example subformula_property :
  forallb (fun c => subF (fand p q) c) (formsIn (normalize 30 genDetour))
  = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 8. 和谐账本：β 与 η 在引入形上互逆 ---------- *)

(* η 展开（MP 系 ∧）：d : p∧q ↦ ∧I(∧E1 d)(∧E2 d)；
   局部完备性的机器面：对引入形 d，β(η(d)) = d *)
Definition etaAnd (d : der) : der := dAndI (dAndE1 d) (dAndE2 d).

Example eta_beta_roundtrip :
  derEqb (normalize 30 (etaAnd (dAndI (dHyp p) (dHyp q))))
         (dAndI (dHyp p) (dHyp q)) = true.
Proof. vm_compute. reflexivity. Qed.

(* 反向 β 后 η：GE 绕道收缩后再 η 展开不增公式（正规形稳定性） *)
Example normal_stable :
  derEqb (normalize 30 (etaAnd (normalize 30 genDetour)))
         (dAndI (dHyp p) (dHyp q)) = true.
Proof. vm_compute. reflexivity. Qed.

(* ---------- 9. 高层次强于标准层：嵌套规则应用 ---------- *)

(* 语境含两层规则假设：p ⇒ q 与 (p→q) ⇒ r。构造 p→r 的推导——
   内层：假设规则 p⇒q 在 →I 体里当 modus ponens 用（dRule 层 2 的
   应用点）；外层：把这样造出的 p→q 证据喂给层 3 规则 (p→q)⇒r。
   标准层没有规则假设这个实体——这正是「不可扁平化」的直觉面。 *)
Definition r2 : form := atom 2.
Definition G3 : list entry :=
  [ER p q; ER (fimp p q) r2; EF p].

Definition viaRules : der :=
  dImpI p (dRule (fimp p q) r2 (dImpI p (dRule p q (dHyp p)))).

Example nested_rule_application :
  wtdOK G3 viaRules (fimp p r2) = true.
Proof. vm_compute. reflexivity. Qed.

(* 冒烟 *)
Compute (typeOf G0 mpD, typeOf G0 hlD, normalize 30 slDetour).
