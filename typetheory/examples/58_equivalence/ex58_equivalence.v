(* ============================================================ *)
(* 37 等价论 —— Coq mini-HoTT 对照组（HoTT 书 ch.4）            *)
(*   前奏：零公理 paths 库（57 章同款）+ assoc/ap_pp 本章自证     *)
(*   同伦自然性 2.4.3/2.4.4 的 J 归纳版                          *)
(*   四定义 qinv/ishae/biinv/contrFib 与等价网络：               *)
(*     qinv→ishae（4.2.3 ε′-重构——与 cubical 侧同一条链）        *)
(*     ishae→biinv、biinv→qinv（2.4.10）、contrFib→biinv（4.4.3  *)
(*     数据版——相干 τ 由网络两跳白送）                           *)
(*   诚实清单：4.2.6（ishae→contrFib 的纤维合同性完整演算）       *)
(*   留 60 章（isProp 机械）回填——书 4.2.13 本就依赖 ch.3.11     *)
(* ============================================================ *)

Unset Automatic Proposition Inductives.

(* ---------- 前奏：零公理 paths 库 ---------- *)

Inductive paths {A : Type} (a : A) : A -> Type := idpath : paths a a.
Arguments paths {A} a b. Arguments idpath {A a}.

Notation "x == y" := (paths x y) (at level 70).

Definition concat {A : Type} {x y z : A} (p : x == y) (q : y == z)
  : x == z :=
  match p in paths _ y' return forall (q0 : y' == z), x == z with
  | idpath => fun q0 => q0
  end q.
Notation "p · q" := (concat p q) (at level 60, right associativity).

Definition inverse {A : Type} {x y : A} (p : x == y) : y == x :=
  match p in paths _ y' return y' == x with idpath => idpath end.
Notation "! p" := (inverse p) (at level 65).

Definition ap {A B : Type} (f : A -> B) {x y : A} (p : x == y)
  : f x == f y :=
  match p in paths _ y' return f x == f y' with idpath => idpath end.

(* ---- 群律（J 归纳；基座全为 idpath——concat 在 idpath 上计算） ---- *)

Definition concat_p1 {A : Type} {x y : A} (p : x == y)
  : p · idpath == p :=
  match p as p0 in paths _ y' return (p0 · (@idpath A y')) == p0 with
  | idpath => idpath
  end.

Definition concat_pV {A : Type} {x y : A} (p : x == y)
  : (p · ! p) == idpath :=
  match p as p0 in paths _ y' return (p0 · ! p0) == (@idpath A x) with
  | idpath => idpath
  end.

Definition concat_Vp {A : Type} {x y : A} (p : x == y)
  : ((! p) · p) == idpath :=
  match p as p0 in paths _ y' return ((! p0) · p0) == (@idpath A y') with
  | idpath => idpath
  end.

Definition concat_assoc {A : Type} {x y z w : A}
  (p : x == y) (q : y == z) (r : z == w)
  : p · (q · r) == (p · q) · r.
Proof. induction p; exact idpath. Qed.

Definition ap_pp {A B : Type} (f : A -> B) {x y z : A}
  (p : x == y) (q : y == z)
  : ap f (p · q) == ap f p · ap f q.
Proof. induction p; induction q; exact idpath. Qed.

Definition ap_inverse {A B : Type} (f : A -> B) {x y : A} (p : x == y)
  : ap f (! p) == ! (ap f p).
Proof. induction p; exact idpath. Qed.

(* ---------- 同伦自然性（书 2.4.3 / 系 2.4.4） ---------- *)

Definition ap_id {A : Type} {x y : A} (p : x == y)
  : ap (fun a => a) p == p.
Proof. induction p; exact idpath. Qed.

Definition ap_compose {A B C : Type} (g : B -> C) (f : A -> B) {x y : A}
  (p : x == y) : ap (fun z => g (f z)) p == ap g (ap f p).
Proof. induction p; exact idpath. Qed.

(* 引理 2.4.3：同伦自然性（基座两侧的 ap/ap·1 都被定义性吃掉） *)
Definition natH {A B : Type} {f g : A -> B} (H : forall x, f x == g x)
  {x y : A} (p : x == y)
  : H x · ap g p == ap f p · H y :=
  match p as p0 in paths _ y' return H x · ap g p0 == ap f p0 · H y' with
  | idpath => concat_p1 (H x)
  end.

(* 系 2.4.4：取消律链（八段，与 cubical 侧 hdistr 同构） *)
Definition hdistr {A : Type} {h : A -> A} (H : forall x, h x == x) (x : A)
  : H (h x) == ap h (H x) :=
  inverse (concat_p1 (H (h x)))
  · ap (fun k => H (h x) · k) (inverse (concat_pV (H x)))
  · concat_assoc (H (h x)) (H x) (! H x)
  · ap (fun k => (H (h x) · k) · ! H x) (inverse (ap_id (H x)))
  · ap (fun m => m · ! H x) (natH H (H x))
  · inverse (concat_assoc (ap h (H x)) (H x) (! H x))
  · ap (fun k => ap h (H x) · k) (concat_pV (H x))
  · concat_p1 (ap h (H x)).

(* ---------- 四定义 ---------- *)

Record QInv {A B : Type} (f : A -> B) := mkQInv {
  qg : B -> A;
  qa : forall y, f (qg y) == y;
  qb : forall x, qg (f x) == x }.

Record IshaE {A B : Type} (f : A -> B) := mkIshaE {
  ig : B -> A;
  ieta : forall x, ig (f x) == x;
  ieps : forall y, f (ig y) == y;
  itau : forall x, ap f (ieta x) == ieps (f x) }.

Record BiInv {A B : Type} (f : A -> B) := mkBiInv {
  bgl : B -> A;
  betal : forall x, bgl (f x) == x;
  bgr : B -> A;
  bepsr : forall y, f (bgr y) == y }.

Definition isContr (A : Type) := { c : A & forall y : A, c == y }.
Definition fib {A B : Type} (f : A -> B) (y : B) := { x : A & f x == y }.
Definition ContrFib {A B : Type} (f : A -> B) :=
  forall y : B, isContr (fib f y).

(* ---------- 等价网络 ---------- *)

(* ishae → biinv：忘却 τ *)
Definition ishae_to_biinv {A B : Type} {f : A -> B} (e : IshaE f) : BiInv f.
Proof. destruct e as [g eta eps tau]. exact (@mkBiInv _ _ _ g eta g eps). Qed.

(* biinv → qinv（书 2.4.10 方向二）：γ 缝合，term 一行 *)
Definition biinv_to_qinv {A B : Type} {f : A -> B} (b : BiInv f) : QInv f.
Proof.
  destruct b as [gl etal gr epsr].
  exact (@mkQInv _ _ _ gr epsr
    (fun x => (! etal (gr (f x))) · (ap gl (epsr (f x)) · etal x))).
Defined.

(* qinv → ishae（书 4.2.3）：ε′ 预制 + τ 三步链
   （与 cubical 侧 ex37 的 chain 完全同构，只换记号） *)
Definition qinv_to_ishae {A B : Type} {f : A -> B} (q : QInv f) : IshaE f.
Proof.
  destruct q as [g alpha beta].
  refine (@mkIshaE _ _ _ g beta
    (fun y => (! alpha (f (g y))) · (ap f (beta (g y)) · alpha y)) _).
  intros x.
  (* tau x 的四段链（lUnit 段被 Coq 定义性吃掉）：
     fb == (!α₂·α₂)·fb == !α₂·(α₂·fb)
        == !α₂·(ap (f∘g∘f) βx · α₁) == !α₂·(ap f βg · α₁) *)
  (* 段一：fb == (!α₂·α₂)·fb *)
  assert (s1 : ap f (beta x)
                == (inverse (alpha (f (g (f x)))) · alpha (f (g (f x))))
                   · ap f (beta x)).
  { exact (ap (fun k => k · ap f (beta x))
              (inverse (concat_Vp (alpha (f (g (f x))))))). }
  (* 段二：(!α₂·α₂)·fb == !α₂·(α₂·fb) *)
  assert (s2 : (inverse (alpha (f (g (f x)))) · alpha (f (g (f x))))
                 · ap f (beta x)
               == inverse (alpha (f (g (f x))))
                  · (alpha (f (g (f x))) · ap f (beta x))).
  { exact (inverse (concat_assoc _ _ _)). }
  (* 段三：α₂·fb == ap (f∘g∘f) βx · α₁ *)
  assert (s3 : alpha (f (g (f x))) · ap f (beta x)
               == ap (fun z => f (g (f z))) (beta x) · alpha (f x)).
  { exact (ap (fun k => alpha (f (g (f x))) · k) (inverse (ap_id _))
            · natH alpha (ap f (beta x))
            · ap (fun k => k · alpha (f x))
                 (inverse (ap_compose (fun b => f (g b)) f (beta x)))). }
  (* 段四：ap (f∘g∘f) βx == ap f βg *)
  assert (s4 : ap (fun z => f (g (f z))) (beta x)
               == ap f (beta (g (f x)))).
  { exact (ap_compose f (fun b => g (f b)) (beta x)
            · inverse (ap (fun k => ap f k) (hdistr beta x))). }
  (* ε′(f x) = !α₂·(ap f βg · α₁)：四段装配 *)
  exact (s1 · s2 · ap (fun k => _ · k) s3 · ap (fun k => _ · (k · _)) s4).
Defined.

(* contrFib → biinv（书 4.4.3 的数据版）：η 从纤维合同性取出 *)
Definition contrfib_to_biinv {A B : Type} {f : A -> B} (cf : ContrFib f)
  : BiInv f :=
  @mkBiInv _ _ _
    (fun y : B => projT1 (projT1 (cf y)))
    (fun x : A => ap (fun w => projT1 w)
                     (projT2 (cf (f x)) (existT _ x idpath)))
    (fun y : B => projT1 (projT1 (cf y)))
    (fun y : B => projT2 (projT1 (cf y))).

(* 相干 τ 白送：网络合成 contrFib → biinv → qinv → ishae *)
Definition contrfib_to_ishae {A B : Type} {f : A -> B} (cf : ContrFib f)
  : IshaE f :=
  qinv_to_ishae (biinv_to_qinv (contrfib_to_biinv cf)).

(* ---------- 样本与记账 ---------- *)

Definition idpath_ishae (A : Type) : IshaE (fun a : A => a) :=
  @mkIshaE _ _ _ (fun a => a) (fun _ => idpath) (fun _ => idpath)
                (fun _ => idpath).

Print Assumptions contrfib_to_ishae.
(* → 闭世界公理列表为空：整条网络零公理。 *)
