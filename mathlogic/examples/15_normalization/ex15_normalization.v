(* ex15_normalization.v —— 正规化定理（马明辉 2.3，定理 2.3/2.4）
   引例：引入联结词之后又立即消去的步骤是「赘步」（切割公式）。
   机器件：推导树+良构检查 wf；红元检测 cutFmls（∧/→ 的引入-消去）；
   一步归约 red1（∧-变换/→-变换=β-归约+∨-置换）；切割高度 ch(D)=(k,n)
   字典序；归约解释器 dnorm 跑到底+降序账；子公式性质（推论 2.3）。
   NK° 原子限制（⊥E^a/RAA^a，引理 2.2）记注释；∨-置换的度量分离
   （书引理 2.6 的排列变换不消除切割公式只重排）如实呈现。 *)

From Stdlib Require Import Bool Arith Lia List.
Import ListNotations.

(* ============ 一、公式、推导树与良构 ============ *)

Inductive fform : Type :=
| pvar (n : nat)
| fbot
| fand (a b : fform)
| forr (a b : fform)
| fimp (a b : fform).

Definition fneg (a : fform) : fform := fimp a fbot.

Fixpoint feqb (a b : fform) : bool :=
  match a, b with
  | pvar m, pvar n => Nat.eqb m n
  | fbot, fbot => true
  | fand a1 a2, fand b1 b2 => andb (feqb a1 b1) (feqb a2 b2)
  | forr a1 a2, forr b1 b2 => andb (feqb a1 b1) (feqb a2 b2)
  | fimp a1 a2, fimp b1 b2 => andb (feqb a1 b1) (feqb a2 b2)
  | _, _ => false
  end.

Fixpoint dcomp (a : fform) : nat :=
  match a with
  | pvar _ | fbot => 0
  | fand a b | forr a b | fimp a b => S (Nat.max (dcomp a) (dcomp b))
  end.

(* 推导树：消去节点携带结论公式与分解片段（保证 conc 全函数） *)
Inductive der : Type :=
| dHyp (n : nat) (a : fform)                       (* 标记 n 的假设 a *)
| dAI (d1 d2 : der)                                (* ∧I *)
| dAEL (a b : fform) (d : der)                     (* ∧E 左：d 应是 a∧b *)
| dAER (a b : fform) (d : der)                     (* ∧E 右 *)
| dOI1 (a b : fform) (d : der)                     (* ∨I1 *)
| dOI2 (a b : fform) (d : der)                     (* ∨I2 *)
| dOE (a b c : fform) (d0 d1 d2 : der)             (* ∨E：d0 应是 a∨b *)
| dII (n : nat) (a b : fform) (d : der)            (* →I：撤销 n:a，d 应是 b *)
| dIE (a b : fform) (d1 d2 : der)                  (* →E：d1 应是 a→b，d2 应是 a *)
| dBotE (c : fform) (d : der).                     (* ⊥E *)

Fixpoint conc (d : der) : fform :=
  match d with
  | dHyp _ a => a
  | dAI d1 d2 => fand (conc d1) (conc d2)
  | dAEL a _ _ => a
  | dAER _ b _ => b
  | dOI1 a b _ => forr a b
  | dOI2 a b _ => forr a b
  | dOE _ _ c _ _ _ => c
  | dII _ a b _ => fimp a b
  | dIE _ b _ _ => b
  | dBotE c _ => c
  end.

(* 良构：每个节点的子推导结论与节点注记吻合 *)
Fixpoint wf (d : der) : bool :=
  match d with
  | dHyp _ _ => true
  | dAI d1 d2 => andb (wf d1) (wf d2)
  | dAEL a b d => andb (feqb (conc d) (fand a b)) (wf d)
  | dAER a b d => andb (feqb (conc d) (fand a b)) (wf d)
  | dOI1 a b d => andb (feqb (conc d) a) (wf d)
  | dOI2 a b d => andb (feqb (conc d) b) (wf d)
  | dOE a b c d0 d1 d2 =>
      andb (feqb (conc d0) (forr a b))
        (andb (feqb (conc d1) c)
          (andb (feqb (conc d2) c)
            (andb (wf d0) (andb (wf d1) (wf d2)))))
  | dII _ a b d => andb (feqb (conc d) b) (wf d)
  | dIE a b d1 d2 =>
      andb (feqb (conc d1) (fimp a b))
        (andb (feqb (conc d2) a)
          (andb (wf d1) (wf d2)))
  | dBotE c d => andb (feqb (conc d) fbot) (wf d)
  end.

(* ============ 二、切割公式与红元（书定义 2.4） ============ *)

(* 切割公式 = 引入规则的结论恰是消去规则的大前提。
   机器面只计「引入-消去」红元（∧-红元/→-红元）——它们进 ch(D)；
   ∨-置换红元（∨E 的结论被消去）单独处理（书定义 2.10 切割段的
   排列变换，度量分离见第四节）。 *)
Fixpoint cutFmls (d : der) : list fform :=
  match d with
  | dHyp _ _ => []
  | dAI d1 d2 => cutFmls d1 ++ cutFmls d2
  | dAEL _ _ d' =>
      (match d' with
       | dAI _ _ => [conc d']              (* ∧I 的结论即被 ∧E：∧-赘步 *)
       | dOE _ _ _ _ _ _ => [conc d']      (* ∨E 的结论被 ∧E：置换段 *)
       | _ => []
       end) ++ cutFmls d'
  | dAER _ _ d' =>
      (match d' with
       | dAI _ _ => [conc d']
       | dOE _ _ _ _ _ _ => [conc d']
       | _ => []
       end) ++ cutFmls d'
  | dOI1 _ _ d' => cutFmls d'
  | dOI2 _ _ d' => cutFmls d'
  | dOE _ _ _ d0 d1 d2 => cutFmls d0 ++ cutFmls d1 ++ cutFmls d2
  | dII _ _ _ d' => cutFmls d'
  | dIE _ _ d1 d2 =>
      (match d1 with
       | dII _ _ _ _ => [conc d1]                  (* →I 的结论即被 →E *)
       | dOE _ _ _ _ _ _ => [conc d1]              (* ∨E 的结论被 →E：置换段 *)
       | _ => []
       end) ++ cutFmls d1 ++ cutFmls d2
  | dBotE _ d' => cutFmls d'
  end.

(* 切割高度 ch(D)=(k,n)：k=极大切割公式复杂度，n=其个数（书定义 2.7） *)
Definition chD (d : der) : (nat * nat)%type :=
  let ks := map dcomp (cutFmls d) in
  match ks with
  | [] => (0, 0)
  | k0 :: rest =>
      (fold_right Nat.max k0 rest,
       length (filter (fun k => Nat.eqb k (fold_right Nat.max k0 rest)) ks))
  end.

(* 字典序：k1<k2 或 (k1=k2 且 n1<n2)——N×N 良序（书定义 2.7） *)
Definition lexLt (p q : (nat * nat)%type) : bool :=
  orb (Nat.ltb (fst p) (fst q))
      (andb (Nat.eqb (fst p) (fst q)) (Nat.ltb (snd p) (snd q))).

(* ============ 三、一步归约 red1（书的两类变换+置换） ============ *)

(* 代换：把标记 n 的假设整体替换为推导 r（β-归约的主体） *)
Fixpoint dsubst (n : nat) (r : der) (d : der) : der :=
  match d with
  | dHyp m _ => if Nat.eqb m n then r else d
  | dAI d1 d2 => dAI (dsubst n r d1) (dsubst n r d2)
  | dAEL a b d' => dAEL a b (dsubst n r d')
  | dAER a b d' => dAER a b (dsubst n r d')
  | dOI1 a b d' => dOI1 a b (dsubst n r d')
  | dOI2 a b d' => dOI2 a b (dsubst n r d')
  | dOE a b c d0 d1 d2 => dOE a b c (dsubst n r d0) (dsubst n r d1) (dsubst n r d2)
  | dII m a b d' => dII m a b (dsubst n r d')
  | dIE a b d1 d2 => dIE a b (dsubst n r d1) (dsubst n r d2)
  | dBotE c d' => dBotE c (dsubst n r d')
  end.

(* 根部红元：优先引入-消去（降 ch），否则 ∨-置换（书引理 2.6 的重排） *)
Definition rootRed (d : der) : option der :=
  match d with
  | dAEL _ _ (dAI d1 _) => Some d1                       (* ∧-变换 *)
  | dAER _ _ (dAI _ d2) => Some d2
  | dIE a b (dII n _ _ e) d2 => Some (dsubst n d2 e)     (* →-变换=β *)
  | dAEL a b (dOE a' b' _ d0 d1 d2) =>                   (* ∨-置换：∧E 下潜 *)
      Some (dOE a' b' a d0 (dAEL a b d1) (dAEL a b d2))
  | dAER a b (dOE a' b' _ d0 d1 d2) =>
      Some (dOE a' b' b d0 (dAER a b d1) (dAER a b d2))
  | _ => None
  end.

(* 一步归约：优先根部红元，否则深入子推导（结构递归，最左优先） *)
Fixpoint red1 (d : der) : option der :=
  match rootRed d with
  | Some d' => Some d'
  | None =>
      match d with
      | dHyp _ _ => None
      | dAI d1 d2 =>
          match red1 d1 with
          | Some d1' => Some (dAI d1' d2)
          | None => match red1 d2 with
                    | Some d2' => Some (dAI d1 d2')
                    | None => None
                    end
          end
      | dAEL a b d' => match red1 d' with
                       | Some e => Some (dAEL a b e)
                       | None => None end
      | dAER a b d' => match red1 d' with
                       | Some e => Some (dAER a b e)
                       | None => None end
      | dOI1 a b d' => match red1 d' with
                       | Some e => Some (dOI1 a b e)
                       | None => None end
      | dOI2 a b d' => match red1 d' with
                       | Some e => Some (dOI2 a b e)
                       | None => None end
      | dOE a b c d0 d1 d2 =>
          match red1 d0 with
          | Some e => Some (dOE a b c e d1 d2)
          | None => match red1 d1 with
                    | Some e => Some (dOE a b c d0 e d2)
                    | None => match red1 d2 with
                              | Some e => Some (dOE a b c d0 d1 e)
                              | None => None
                              end
                    end
          end
      | dII n a b d' => match red1 d' with
                        | Some e => Some (dII n a b e)
                        | None => None end
      | dIE a b d1 d2 =>
          match red1 d1 with
          | Some e => Some (dIE a b e d2)
          | None => match red1 d2 with
                    | Some e => Some (dIE a b d1 e)
                    | None => None
                    end
          end
      | dBotE c d' => match red1 d' with
                      | Some e => Some (dBotE c e)
                      | None => None end
      end
  end.

(* 归约解释器：跑到底（fuel 防） *)
Fixpoint dnorm (fuel : nat) (d : der) : der :=
  match fuel with
  | O => d
  | S f => match red1 d with
           | Some d' => dnorm f d'
           | None => d
           end
  end.

(* 归约轨迹的 ch 序列（降序账的证据） *)
Fixpoint dtrace (fuel : nat) (d : der) : list ((nat * nat)%type) :=
  match fuel with
  | O => []
  | S f => match red1 d with
           | Some d' => chD d :: dtrace f d'
           | None => [chD d]
           end
  end.

(* ============ 四、子公式性质（推论 2.3） ============ *)

Fixpoint sub (a : fform) : list fform :=
  match a with
  | pvar _ | fbot => [a]
  | fand x y | forr x y | fimp x y => a :: (sub x ++ sub y)
  end.

Definition subClosed (l : list fform) : bool :=
  forallb (fun a => forallb (fun b => existsb (fun c => feqb b c) l) (sub a)) l.

Fixpoint allFmls (d : der) : list fform :=
  match d with
  | dHyp _ a => [a]
  | dAI d1 d2 => conc d :: (allFmls d1 ++ allFmls d2)
  | dAEL a b d' => fand a b :: (a :: b :: allFmls d')
  | dAER a b d' => fand a b :: (a :: b :: allFmls d')
  | dOI1 a b d' => forr a b :: (a :: allFmls d')
  | dOI2 a b d' => forr a b :: (b :: allFmls d')
  | dOE a b c d0 d1 d2 =>
      forr a b :: (c :: (allFmls d0 ++ allFmls d1 ++ allFmls d2))
  | dII _ a b d' => fimp a b :: (b :: allFmls d')
  | dIE a b d1 d2 => fimp a b :: (a :: (allFmls d1 ++ allFmls d2))
  | dBotE c d' => c :: allFmls d'
  end.

(* ============ 五、账例 ============ *)

Definition p0 := pvar 0.
Definition p1 := pvar 1.

(* 例 2.4(1)：α,β ⊢ α∧β 后接 ∧E——最简 ∧-赘步 *)
Definition exDetour : der :=
  dAER p0 p1 (dAI (dHyp 0 p0) (dHyp 1 p1)).

Example exDetour_wf : wf exDetour = true.
Proof. reflexivity. Qed.
Example exDetour_ch : chD exDetour = (1, 1).
Proof. reflexivity. Qed.
Example exDetour_steps : dtrace 5 exDetour = [(1,1); (0,0)].
Proof. reflexivity. Qed.
Example exDetour_nf : dnorm 5 exDetour = dHyp 1 p1.
Proof. reflexivity. Qed.

(* β-赘步：⊢p→p 的绕路证明（先 →I 再立即 →E） *)
Definition exBeta : der :=
  dIE p0 p0 (dII 0 p0 p0 (dHyp 0 p0)) (dHyp 1 p0).

Example exBeta_wf : wf exBeta = true.
Proof. reflexivity. Qed.
Example exBeta_steps : dtrace 5 exBeta = [(1,1); (0,0)].
Proof. reflexivity. Qed.
Example exBeta_nf : dnorm 5 exBeta = dHyp 1 p0.
Proof. reflexivity. Qed.

(* 复杂度 2 的级联：β 先造出低一级的 ∧-赘步，再 ∧-变换收掉——
   书引理 2.3/2.4 的「复杂度下降」机制现场 *)
Definition exCascade : der :=
  dIE (fand p0 p1) p0
    (dII 1 (fand p0 p1) p0 (dAEL p0 p1 (dHyp 1 (fand p0 p1))))
    (dAI (dHyp 2 p0) (dHyp 3 p1)).

Example exCascade_wf : wf exCascade = true.
Proof. reflexivity. Qed.
(* 轨迹 (2,1) → (1,1) → (0,0)：k 严格降 *)
Example exCascade_steps :
  dtrace 5 exCascade = [(2,1); (1,1); (0,0)].
Proof. reflexivity. Qed.

(* ∨-置换：∨E 的结论立即被 ∧E——书引理 2.6 的排列变换 *)
Definition exPerm : der :=
  dAEL p0 p1
    (dOE p0 (fand p0 p1) (fand p0 p1)
      (dHyp 9 (forr p0 (fand p0 p1)))
      (dAI (dHyp 1 p0) (dHyp 2 p1))
      (dHyp 3 (fand p0 p1))).

Example exPerm_wf : wf exPerm = true.
Proof. reflexivity. Qed.
(* 轨迹 (1,1)→(1,1)→(0,0)：置换步不降 k（重排），紧随的 ∧-变换才降——
   书「排列变换把消去规则上移，切割高度不变大，再用 ∧-变换消除」 *)
Example exPerm_steps :
  dtrace 5 exPerm = [(1,1); (1,1); (0,0)].
Proof. reflexivity. Qed.
(* 终态：置换+∧-变换后正规——但 ∨E（大前提是假设）与 box2 的 ∧E 留在
   原地：正规推导仍可以有「对假设的消去」（轨迹的消去段），只是不再有
   引入后立即消去的赘步 *)
Example exPerm_nf :
  dnorm 5 exPerm =
  dOE p0 (fand p0 p1) p0
    (dHyp 9 (forr p0 (fand p0 p1)))
    (dHyp 1 p0)
    (dAEL p0 p1 (dHyp 3 (fand p0 p1))).
Proof. reflexivity. Qed.
Example exPerm_nf_no_detour : chD (dnorm 5 exPerm) = (0, 0).
Proof. reflexivity. Qed.

(* 子公式性质（推论 2.3）：正规推导的全部公式 ⊆ SF({前提,结论})
   exCascade 归到底后公式只剩 p0——在 {p0,p1} ∪ SF((p0∧p1)→p0) 内 *)
Definition cascadeCtx : list fform :=
  sub p0 ++ sub p1 ++ sub (fimp (fand p0 p1) p0).

Example exCascade_subf :
  forallb (fun a => existsb (fun c => feqb a c) cascadeCtx)
          (allFmls (dnorm 5 exCascade)) = true.
Proof. reflexivity. Qed.
(* 同一对 exPerm：正规终态的公式 {p∨(p∧q), p, q, p∧q} 全在
   SF({p∨(p∧q)} ∪ {p0}) 内 *)
Example exPerm_subf :
  forallb (fun a => existsb (fun c => feqb a c)
              (sub (forr p0 (fand p0 p1)) ++ sub p0 ++ sub p1))
          (allFmls (dnorm 5 exPerm)) = true.
Proof. reflexivity. Qed.

(* 账本 *)
Print Assumptions exCascade_steps.
Print Assumptions exPerm_steps.
Print Assumptions exDetour_nf.
