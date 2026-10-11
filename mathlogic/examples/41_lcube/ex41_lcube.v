(* ex41_lcube.v —— λ-立方与定理证明器（Seldin 篇，书 ch7）
   机器件：三开关参数化的 PTS 类型检查器（燃料版）——
   (1) 项：var | Prop | Type | app | λx:A.M | Πx:A.B；通用规则
       (start 隐含于语境表；weakening 隐含于 lookup) + conversion(β)；
   (2) 差异只在 (ss′rule)：多态 (Type,Prop) / 依值 (Prop,Type) /
       类型算子 (Type,Type)——三开关拼出八系统；
   (3) λ 分支的排序判定要查「体类型的类型」——非结构递归，燃料版
       inferF；
   (4) 电池：id : ∀A:Prop.A→A 只有多态收；Leibniz 相等需要依值；
       ⊥ := ∀x:Prop.x 在 λ2 是合法命题、λ→ 不收；基系统 ⊥ 无候选
       居元（样本面）vs 坏假设 c1:Prop,c2:c1,c3:¬c1 立即爆 ⊥；
       conversion 的 β 面。
   零公理。坑位速记见 docs/41-lcube.md。 *)

From Stdlib Require Import List Arith Bool.
Import ListNotations.

Inductive tm : Type :=
| var (n : nat)
| srt (b : bool)          (* false=Prop(∗)  true=Type(□) *)
| app (a b : tm)
| lam (x : nat) (A b : tm)
| pi (x : nat) (A B : tm).

Fixpoint subst (x : nat) (T : tm) (a : tm) : tm :=
  match a with
  | var m => if Nat.eqb m x then T else var m
  | srt b => srt b
  | app u v => app (subst x T u) (subst x T v)
  | lam y A u => lam y (subst x T A)
                      (if Nat.eqb y x then u else subst x T u)
  | pi y A B => pi y (subst x T A)
                      (if Nat.eqb y x then B else subst x T B)
  end.

Fixpoint tmEq (a b : tm) : bool :=
  match a, b with
  | var n, var m => Nat.eqb n m
  | srt x, srt y => Bool.eqb x y
  | app u1 v1, app u2 v2 => andb (tmEq u1 u2) (tmEq v1 v2)
  | lam y1 A1 u1, lam y2 A2 u2 =>
      andb (Nat.eqb y1 y2) (andb (tmEq A1 A2) (tmEq u1 u2))
  | pi y1 A1 B1, pi y2 A2 B2 =>
      andb (Nat.eqb y1 y2) (andb (tmEq A1 A2) (tmEq B1 B2))
  | _, _ => false
  end.

Fixpoint whnfF (fuel : nat) (a : tm) {struct fuel} : tm :=
  match fuel with
  | 0 => a
  | S k =>
      match a with
      | app u v =>
          match whnfF k u with
          | lam x _ b => whnfF k (subst x v b)
          | u' => app u' v
          end
      | x => x
      end
  end.

Definition whnf (a : tm) : tm := whnfF 400 a.

Fixpoint convF (fuel : nat) (a b : tm) {struct fuel} : bool :=
  match fuel with
  | 0 => tmEq a b
  | S k =>
      let a' := whnf a in
      let b' := whnf b in
      match a', b' with
      | app u1 v1, app u2 v2 => andb (convF k u1 u2) (convF k v1 v2)
      | lam y1 A1 u1, lam y2 A2 u2 =>
          andb (tmEq A1 A2) (convF k u1 (subst y2 (var y1) u2))
      | pi y1 A1 B1, pi y2 A2 B2 =>
          andb (tmEq A1 A2) (convF k B1 (subst y2 (var y1) B2))
      | _, _ => tmEq a' b'
      end
  end.

Definition conv (a b : tm) : bool := convF 400 a b.

Fixpoint nfF (fuel : nat) (a : tm) {struct fuel} : tm :=
  match fuel with
  | 0 => a
  | S k =>
      match a with
      | app u v =>
          match nfF k u with
          | lam x _ b => nfF k (subst x (nfF k v) b)
          | u' => app u' (nfF k v)
          end
      | lam x A u => lam x (nfF k A) (nfF k u)
      | pi x A B => pi x (nfF k A) (nfF k B)
      | x => x
      end
  end.

Definition nf (a : tm) : tm := nfF 400 a.

(* ---------- 三开关与 (ss′rule) ---------- *)

Record flags : Type := mkFlags { fPoly : bool; fDep : bool; fTops : bool }.

Definition ruleOK (fl : flags) (s1 s2 : bool) : bool :=
  match s1, s2 with
  | false, false => true                       (* (∗,∗) 恒有 *)
  | true, false => fPoly fl                    (* (□,∗) 多态 *)
  | false, true => fDep fl                     (* (∗,□) 依值 *)
  | true, true => fTops fl                     (* (□,□) 类型算子 *)
  end.

Definition Ctx := list (nat * tm).

Fixpoint look (x : nat) (G : Ctx) : option tm :=
  match G with
  | [] => None
  | (y, A) :: t => if Nat.eqb y x then Some A else look x t
  end.

Definition asSort (T : tm) : option bool :=
  match whnf T with
  | srt b => Some b
  | _ => None
  end.

(* 燃料版推断：lam 分支要再查「体类型的类型」，非结构递归。 *)
Fixpoint inferF (fuel : nat) (fl : flags) (G : Ctx) (a : tm)
                {struct fuel} : option tm :=
  match fuel with
  | 0 => None
  | S k =>
    match a with
    | var x => look x G
    | srt false => Some (srt true)
    | srt true => None
    | app u v =>
        match inferF k fl G u with
        | Some (pi x A B) =>
            match inferF k fl G v with
            | Some Tv => if conv Tv A then Some (subst x v B) else None
            | None => None end
        | _ => None end
    | lam x A b =>
        match inferF k fl G A with
        | Some sA =>
            match asSort sA with
            | Some s1 =>
                match inferF k fl ((x, A) :: G) b with
                | Some TB =>
                    (* Πx:A.TB : s2 需要 TB : s2——查 TB 的类型 *)
                    match inferF k fl ((x, A) :: G) TB with
                    | Some (srt s2) =>
                        if ruleOK fl s1 s2 then Some (pi x A TB) else None
                    | _ => None end
                | None => None end
            | None => None end
        | _ => None end
    | pi x A B =>
        match inferF k fl G A with
        | Some sA =>
            match asSort sA with
            | Some s1 =>
                match inferF k fl ((x, A) :: G) B with
                | Some TB =>
                    match asSort TB with
                    | Some s2 =>
                        if ruleOK fl s1 s2 then Some (srt s2) else None
                    | None => None end
                | None => None end
            | None => None end
        | _ => None end
    end
  end.

Definition infer (fl : flags) (G : Ctx) (a : tm) : option tm :=
  inferF 200 fl G a.

Definition inferOK (fl : flags) (G : Ctx) (a T : tm) : bool :=
  match infer fl G a with
  | Some U => conv U T
  | None => false
  end.

(* ---------- 八系统 ---------- *)

Definition lARROW  : flags := mkFlags false false false.  (* λ→ *)
Definition lPOLY   : flags := mkFlags true  false false.  (* λ2 *)
Definition lDEP    : flags := mkFlags false true  false.  (* λP *)
Definition lPOLYDEP: flags := mkFlags true  true  false.  (* λP2 *)
Definition lTOPS   : flags := mkFlags false false true.   (* λω̄ *)
Definition lFOMEGA : flags := mkFlags true  false true.   (* λω (Fω) *)
Definition lDEPTOPS: flags := mkFlags false true  true.   (* λPω *)
Definition lCOC    : flags := mkFlags true  true  true.   (* λC *)

(* ---------- 断言电池 ---------- *)

Notation A := (var 0).

Definition idTerm : tm := lam 0 (srt false) (lam 1 A (var 1)).
Definition idType : tm := pi 0 (srt false) (pi 1 A A).

(* 电一：id 只有多态收——外层 ΠA:Prop 要 (Type,Prop) *)
Example id_needs_poly :
  andb (negb (inferOK lARROW [] idTerm idType))
       (andb (inferOK lPOLY [] idTerm idType)
             (inferOK lCOC [] idTerm idType))
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 电二：Leibniz 相等需要**依值+多态**两开关。G2=[A:Prop, a:A]；
   eqTy = ΠP:A→Prop. Πh:P a. P a——A→Prop 要 (Prop,Type)（依值），
   ΠP:(A→Prop). … 的 P 是「谓词变量」，要 (Type,Prop)（多态）。
   纯多态（λ2）与纯依值（λP）都不收；λP2 与 λC 收。 *)
Definition G2 : Ctx := [ (0, srt false); (5, A) ].
Definition arrT : tm := pi 3 A (srt false).
Definition eqTy : tm :=
  pi 2 arrT (pi 4 (app (var 2) (var 5)) (app (var 2) (var 5))).
Definition eqRefl : tm :=
  lam 2 arrT (lam 4 (app (var 2) (var 5)) (var 4)).

Example leibniz_needs_dep_and_poly :
  andb (negb (inferOK lPOLY G2 eqRefl eqTy))
       (andb (negb (inferOK lDEP G2 eqRefl eqTy))
             (andb (inferOK lPOLYDEP G2 eqRefl eqTy)
                   (inferOK lCOC G2 eqRefl eqTy)))
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 电三：⊥ := Πx:Prop.x 在 λ2 是合法命题（类型为 Prop），λ→ 不收 *)
Definition botT : tm := pi 9 (srt false) (var 9).

Definition isPropIn (fl : flags) (G : Ctx) (T : tm) : bool :=
  match infer fl G T with
  | Some U => match whnf U with srt false => true | _ => false end
  | None => false
  end.

Example bot_needs_poly :
  andb (isPropIn lPOLY [] botT) (negb (isPropIn lARROW [] botT)) = true.
Proof. vm_compute. reflexivity. Qed.

(* 电四：基系统 ⊥ 无候选居元（样本面：恒等实例与裸变量均拒——
   「无居元」本身是强正规化定理的推论，机器只能给样本面）；
   坏假设 c1:Prop,c2:c1,c3:c1→⊥ 立即爆 ⊥。 *)
Example base_consistent_samples :
  negb (orb (inferOK lCOC [] (lam 9 (srt false) (var 9)) botT)
            (inferOK lCOC [] (var 0) botT))
  = true.
Proof. vm_compute. reflexivity. Qed.

Definition negT (C : tm) : tm := pi 10 C botT.
Definition badCtx : Ctx :=
  [ (0, srt false); (1, var 0); (2, negT (var 0)) ].

Example bad_assumptions_explode :
  inferOK lCOC badCtx (app (var 2) (var 1)) botT = true.
Proof. vm_compute. reflexivity. Qed.

(* 电五：conversion 的 β 面 *)
Example conversion_beta :
  andb (conv (app (lam 9 (srt false) (var 9)) botT) botT)
       (tmEq (nf (app (lam 9 (srt false) (var 9)) botT)) botT)
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 冒烟 *)
Compute (infer lARROW [] idTerm).
Compute (infer lPOLY [] idTerm).
Compute (infer lPOLYDEP G2 eqRefl).
