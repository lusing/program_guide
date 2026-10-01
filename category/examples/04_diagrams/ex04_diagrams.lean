-- ex04 —— 图与交换图
-- 三书对位：《高级范畴论》1.2（图、图同态）/ Simmons 2.1
--
-- 图 = 点 + 边 + 两个端点函数；路 = 图上的自由范畴态射；
-- 「交换图」= 一组方程。抽象范畴里的图表推理只用三条定律。

/-- 图 -/
structure Graph where
  V : Type
  E : Type
  src : E → V
  tgt : E → V

/-- 图同态：点映射 + 边映射，保端点——两条「小交换图」方程 -/
structure GraphHom (G H : Graph) where
  vmap : G.V → H.V
  emap : G.E → H.E
  sq_src : ∀ e, vmap (G.src e) = H.src (emap e)
  sq_tgt : ∀ e, vmap (G.tgt e) = H.tgt (emap e)

/-- 路：图上的自由范畴态射 -/
inductive Path (G : Graph) : G.V → G.V → Type
  | pid (v : G.V) : Path G v v
  | pcat (e : G.E) (w : G.V) : Path G (G.tgt e) w → Path G (G.src e) w

/-- 复合：递归在第一条路 -/
def Path.cat {G : Graph} : {u v w : G.V} → Path G u v → Path G v w → Path G u w
  | _, _, _, .pid _, q => q
  | _, _, _, .pcat e _ p, q => .pcat e _ (p.cat q)

theorem path_idR {G : Graph} : ∀ {u v : G.V} (p : Path G u v), p.cat (.pid v) = p
  | _, _, .pid _ => rfl
  | _, _, .pcat e _ p => by simp only [Path.cat, path_idR p]

theorem path_assoc {G : Graph} : ∀ {u v w x : G.V} (p : Path G u v) (q : Path G v w) (r : Path G w x),
    (p.cat q).cat r = p.cat (q.cat r)
  | _, _, _, _, .pid _, _, _ => rfl
  | _, _, _, _, .pcat e _ p, q, r => by simp only [Path.cat, path_assoc p q r]

structure Category where
  Obj : Type u
  Hom : Obj → Obj → Type v
  idn : ∀ a, Hom a a
  comp : ∀ {a b c}, Hom a b → Hom b c → Hom a c
  idL : ∀ {a b} (f : Hom a b), comp (idn a) f = f
  idR : ∀ {a b} (f : Hom a b), comp f (idn b) = f
  assoc : ∀ {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d),
    comp (comp f g) h = comp f (comp g h)

/-- 任意图生成自由范畴 -/
def freeCat (G : Graph) : Category where
  Obj := G.V
  Hom := fun a b => Path G a b
  idn := fun v => .pid v
  comp := fun p q => p.cat q
  idL := fun _ => rfl
  idR := fun p => path_idR p
  assoc := fun p q r => path_assoc p q r

/-! 一个具体的小图：true --e--> false -/
def gArrow : Graph where
  V := Bool
  E := Unit
  src := fun _ => true
  tgt := fun _ => false

/-- true → false 的路只有一条：直接走边 -/
def pDirect : Path gArrow true false := Path.pcat (G := gArrow) (e := ()) (w := false) (Path.pid (G := gArrow) false)

def plen {G : Graph} : {u v : G.V} → Path G u v → Nat
  | _, _, .pid _ => 0
  | _, _, .pcat _ _ p => plen p + 1

example : plen pDirect = 1 := rfl

/-- 抽象定律版：只用三条定律推图 -/
theorem laws_only (C : Category.{u, v}) {a b c : C.Obj} (f : C.Hom a b) (g : C.Hom b c) :
    C.comp (C.comp f (C.idn b)) g = C.comp f g := by rw [C.idR f]

/-! 【TyCat 里的交换方块】 -/
def TyCat : Category.{1, 0} where
  Obj := Type 0
  Hom := fun A B => A → B
  idn := fun _ => fun x => x
  comp := fun f g => fun x => g (f x)
  idL := fun _ => rfl
  idR := fun _ => rfl
  assoc := fun _ _ _ => rfl

/-- 退化方格：恒等边——两边 βη 折叠成同一函数，rfl 白送 -/
example :
    TyCat.comp (fun x => x) (fun n => 2 * n)
        = TyCat.comp (fun n => 2 * n) (fun x => x) := rfl

/-- 真方格：succ;double = double;(+2)，逐点 2*(n+1) = 2n+2 -/
theorem square_commutes :
    TyCat.comp (fun n => n + 1) (fun n => 2 * n)
        = TyCat.comp (fun n => 2 * n) (fun n => n + 2) :=
  funext fun n => (by omega : 2 * (n + 1) = 2 * n + 2)

/-! 坑位速记：
1. `Path.cat` 双参数方程式：`.pid`/`.pcat` 点模式即递归结构；
   Lean 的 match 对索引族自动处理（Coq 要 revert+induction）。
2. `path_idR`/`path_assoc` 用「逐构造子方程 + rw」——pcat 分支的
   递归等式 Lean 4.25 下 iota 可解，不需要 WF 递归。
3. plen 写成 `+ 1` 而非 `Nat.suc`——与 Lean 加法第二参数折叠
   方向一致，`example ... = 1` 才能 rfl。
4. 交换图两层：退化 rfl 白送；一般 `funext n; omega`——
   「交换 = 逐点方程」的机器形态（omega 吃任意线性算术）。 -/
