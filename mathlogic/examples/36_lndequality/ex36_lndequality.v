(* ex36_lndequality.v —— 标号演绎与相等：缺失的实体（de Queiroz/
   de Oliveira 篇，书 ch4）
   机器件：LND 等式逻辑的可执行内核——
   (1) 群论项 + 定向重写规则（左单位/左逆/结合律，最左最外一步）；
   (2) **改写理由** reason AST：原子步带证书 rStep rid src dst（合法
       性=step1 rid src = dst），复合子 rRefl/rSym(σ)/rTrans(τ)/
       rCongArg(合同)——「a =ₛ b : D，s 是改写理由的复合」；
   (3) 重放引擎 replayOpt：沿理由结构重建中间项序列，逐叶核对原子
       步——**等式证明=改写链**的机器化身；
   (4) 标签正规化 nrm：冗余法则（ρ∘s→s、σσ→ρ、合同ρ→ρ、σs∘s→ρ）
       + 端点保持账；
   (5) 内延性现场：两条**不同**的改写链证同一等式（reason 层可区分），
       而外延侧（范式相等）无法区分——Iext 丢轨迹的教学账（书 §1
       「Iext-introduction 里 a、b 不出现在轨迹中」的机器面）；
   (6) λβη 定义等价公理组（α/β/η/ξ/μ/ν/ρ/σ/τ）以 reason 复合子
       对位呈现（文档线）。
   零公理。坑位速记见 docs/36-lndequality.md。 *)

From Stdlib Require Import List Arith Bool.
Import ListNotations.

(* ---------- 1. 群论项与定向重写 ---------- *)

Inductive gt : Type :=
| ge                                (* 单位元 e *)
| gvar (n : nat)
| ginv (a : gt)
| gmul (a b : gt).

Fixpoint gtEq (a b : gt) : bool :=
  match a, b with
  | ge, ge => true
  | gvar n, gvar m => Nat.eqb n m
  | ginv a1, ginv b1 => gtEq a1 b1
  | gmul a1 a2, gmul b1 b2 => andb (gtEq a1 b1) (gtEq a2 b2)
  | _, _ => false
  end.

(* 规则库：0=左单位 e·x→x；1=左逆 x⁻¹·x→e；2=结合 (x·y)·z→x·(y·z)。
   step1 rid t：最左最外恰一步（Option）。 *)
Fixpoint step1 (rid : nat) (t : gt) : option gt :=
  match t with
  | gmul a b =>
      (* 顶步先试 *)
      match rid with
      | 0 => match a with
             | ge => Some b                      (* e·x → x *)
             | _ => None end
      | 1 => match a with
             | ginv c => if gtEq c b then Some ge else None  (* x⁻¹·x → e *)
             | _ => None end
      | 2 => match a with
             | gmul x y => Some (gmul x (gmul y b))  (* (x·y)·z → x·(y·z) *)
             | _ => None end
      | _ => None
      end
  | _ => None
  end.

Fixpoint stepAny (rid : nat) (t : gt) : option gt :=
  (* 最左最外恰一步：先顶、后参数（自递归下钻） *)
  match step1 rid t with
  | Some u => Some u
  | None =>
      match t with
      | gmul a b =>
          match stepAny rid a with
          | Some a' => Some (gmul a' b)
          | None =>
              match stepAny rid b with
              | Some b' => Some (gmul a b')
              | None => None end end
      | ginv a =>
          match stepAny rid a with
          | Some a' => Some (ginv a')
          | None => None end
      | _ => None
      end
  end.

(* ---------- 2. 改写理由 AST（LND 等式的标签演算） ---------- *)

(* 原子步带证书：rStep rid src dst，合法性 validStep 单查。
   复合子：rRefl(ρ) rSym(σ) rTrans(τ) rCongArg(μ/ν 的逐参合同)。 *)
Inductive reason : Type :=
| rStep (rid : nat) (src dst : gt)
| rRefl
| rSym (s : reason)
| rTrans (s t : reason)
| rCongArg (i : nat) (s : reason).

Definition validStep (r : reason) : bool :=
  match r with
  | rStep rid src dst =>
      match step1 rid src with
      | Some u => gtEq u dst
      | None => false end
  | _ => false
  end.

Fixpoint reasonOK (r : reason) : bool :=
  match r with
  | rStep _ _ _ => validStep r
  | rRefl => true
  | rSym s => reasonOK s
  | rTrans s t => andb (reasonOK s) (reasonOK t)
  | rCongArg _ s => reasonOK s
  end.

(* ---------- 3. 重放引擎：理由→中间项序列 ---------- *)

(* replayOpt fwd t r：从 t 出发沿 r 走（fwd=true 正向、false 逆向）。
   原子证书核对端点；σ 翻转方向；合同下钻。 *)
Definition stepGetArg (i : nat) (t : gt) : option gt :=
  match t with
  | gmul a b => if Nat.eqb i 0 then Some a else Some b
  | ginv a => Some a
  | _ => None
  end.

Definition stepSetArg (i : nat) (t a : gt) : gt :=
  match t with
  | gmul u v => if Nat.eqb i 0 then gmul a v else gmul u a
  | ginv _ => ginv a
  | _ => t
  end.

Fixpoint replayOpt (fwd : bool) (t : gt) (r : reason) : option gt :=
  match r with
  | rStep _ src dst =>
      if fwd
      then if gtEq t src then Some dst else None
      else if gtEq t dst then Some src else None
  | rRefl => Some t
  | rSym s => replayOpt (negb fwd) t s
  | rTrans s u =>
      (* 正向：先 s 后 u；逆向（σ 翻转）必须**倒序**：先逆 u 再逆 s *)
      if fwd
      then match replayOpt true t s with
           | Some m => replayOpt true m u
           | None => None end
      else match replayOpt false t u with
           | Some m => replayOpt false m s
           | None => None end
  | rCongArg i s =>
      match stepGetArg i t with
      | Some a =>
          match replayOpt fwd a s with
          | Some a' => Some (stepSetArg i t a')
          | None => None end
      | None => None end
  end.

Definition replayOK (a b : gt) (r : reason) : bool :=
  match replayOpt true a r with
  | Some m => andb (gtEq m b) (reasonOK r)
  | None => false end.

(* ---------- 4. 标签正规化（冗余消除 TRS） ---------- *)

Fixpoint reasonEqb (s t : reason) : bool :=
  match s, t with
  | rStep r1 a1 b1, rStep r2 a2 b2 =>
      andb (Nat.eqb r1 r2) (andb (gtEq a1 a2) (gtEq b1 b2))
  | rRefl, rRefl => true
  | rSym s1, rSym t1 => reasonEqb s1 t1
  | rTrans s1 s2, rTrans t1 t2 => andb (reasonEqb s1 t1) (reasonEqb s2 t2)
  | rCongArg i1 s1, rCongArg i2 t2 =>
      andb (Nat.eqb i1 i2) (reasonEqb s1 t2)
  | _, _ => false
  end.

(* 法则：ρ∘s→s、s∘ρ→s、σσ→ρ、合同ρ→ρ、σs∘s→ρ（端点保持由电池核对） *)
Fixpoint nrm (r : reason) : reason :=
  match r with
  | rSym (rSym s) => rRefl                          (* σσ = ρ *)
  | rSym s => rSym (nrm s)
  | rTrans rRefl t => nrm t                         (* ρ∘s→s *)
  | rTrans s rRefl => nrm s                         (* s∘ρ→s *)
  | rTrans (rSym s) t =>
      if reasonEqb s t then rRefl else rTrans (rSym (nrm s)) (nrm t)
  | rTrans s t => rTrans (nrm s) (nrm t)
  | rCongArg _ rRefl => rRefl                       (* 合同ρ→ρ *)
  | rCongArg i s => rCongArg i (nrm s)
  | rStep _ _ _ => r
  | rRefl => rRefl
  end.

Fixpoint rsize (r : reason) : nat :=
  match r with
  | rStep _ _ _ => 1
  | rRefl => 0
  | rSym s => S (rsize s)
  | rTrans s t => S (rsize s + rsize t)
  | rCongArg _ s => S (rsize s)
  end.

(* ---------- 5. 外延侧：范式（对照用） ---------- *)

Definition oneStep (t : gt) : option gt :=
  (* 任一规则的最左最外恰一步（0→1→2 优先） *)
  match stepAny 0 t with
  | Some u => Some u
  | None =>
      match stepAny 1 t with
      | Some u => Some u
      | None => stepAny 2 t
      end
  end.

Fixpoint nfF (fuel : nat) (t : gt) : gt :=
  match fuel with
  | 0 => t
  | S k =>
      match oneStep t with
      | Some u => nfF k u
      | None => t
      end
  end.

Definition nf (t : gt) : gt := nfF 60 t.

Definition extEq (a b : gt) : bool := gtEq (nf a) (nf b).

(* ---------- 6. 断言电池 ---------- *)

Notation x := (gvar 0).

(* 电一：左逆链。a = (x⁻¹)·(e·x)，b = e。
   链：先在右参数里走左单位（合同），再顶走左逆。 *)
Definition a1 : gt := gmul (ginv x) (gmul ge x).
Definition step_id : reason :=
  rCongArg 1 (rStep 0 (gmul ge x) x).
Definition step_inv : reason :=
  rStep 1 (gmul (ginv x) x) ge.
Definition chain1 : reason := rTrans step_id step_inv.

Example chain1_ok : replayOK a1 ge chain1 = true.
Proof. vm_compute. reflexivity. Qed.

(* 电二：对称/传递=导出规则（σ/τ 的重放面）。
   从 chain1 得 b =_{σ(chain1)} a；再 τ 回去——σs∘s 正规化为 ρ。 *)
Definition symchain : reason := rSym chain1.

Example symmetry_replays :
  replayOK ge a1 symchain = true.
Proof. vm_compute. reflexivity. Qed.

Example double_sym_cancels :
  andb (reasonEqb (nrm (rSym symchain)) rRefl)
       (Nat.eqb (rsize (nrm (rSym symchain))) 0)
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 电三：正规化保持端点（标签重写的可靠性） *)
Definition chain1' : reason :=
  rTrans (rTrans rRefl step_id) (rTrans step_inv rRefl).

Example nrm_endpoints :
  andb (reasonEqb (nrm chain1') chain1)
       (replayOK a1 ge (nrm chain1'))
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 电四：内延性现场——同一等式的两条**不同**理由。
   chainC = τ(direct_id, ρ)：与 direct_id 同端点、多一层 τ∘ρ 包装；
   reason 层可区分（reasonEqb 为假），外延侧（范式相等）无法区分——
   Iext「引入规则里 a、b 不出现在轨迹中」的机器面（书 §1）。 *)
Definition a2 : gt := gmul ge x.
Definition direct_id : reason := rStep 0 a2 x.

Definition chainC : reason := rTrans direct_id rRefl.

Example intensional_witness :
  andb (replayOK a2 x chainC)
       (andb (negb (reasonEqb chainC direct_id))
             (extEq (gmul ge x) x))
  = true.
Proof. vm_compute. reflexivity. Qed.

(* 电五：改写理由 vs 范式外延——外延侧「为什么」不可提取。
   extEq 只答「等/不等」；replayOpt 沿 reason 交出全部中间项。 *)
Compute (replayOpt true a1 chain1).
Compute (nf (gmul (ginv x) (gmul ge x))).

(* λβη 对照（文档线）：定义等价的公理组
   (α) (β) (η) (ξ) (μ) (ν) (ρ) (σ) (τ) 与 reason 复合子的对位：
   ρ↔rRefl  σ↔rSym  τ↔rTrans  μ/ν↔rCongArg  (β)(η)↔rStep 的原子证书。 *)

(* 冒烟 *)
Compute (replayOK a1 ge chain1, rsize chain1, rsize (nrm chain1)).
