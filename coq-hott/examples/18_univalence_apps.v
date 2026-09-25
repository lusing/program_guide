(** 示例 18：泛等的应用
    "等价的类型无法被类型论区分"——把结构沿等价搬过去。

    对应文档：docs/18-univalence-apps.md *)

Require Import HoTT.
Require Import HoTT.Axioms.Univalence.
Local Open Scope path_scope.

Definition sec_18_BEGIN := tt.   Check sec_18_BEGIN.

(** * 18.1 第一原则：性质沿等价保持 *)

Definition sec_18_1_invariance := tt.   Check sec_18_1_invariance.

(** 任何"对类型封闭的谓词" [P : Type -> Type]，
    若 [A ≃ B]，则由泛等得到 [A = B]，从而 [P A] 可以搬运到 [P B]。
    这就是教科书里说的"结构不变性"（structure identity principle）的雏形。 *)
Check univalent_transport.
Check univalent_transport_idequiv.
Check transport_path_universe.

(** 最直接的例子：截断层级。 *)
Check istrunc_equiv_istrunc.
Check istrunc_isequiv_istrunc.

Definition hset_preserved {A B : Type} (e : A <~> B) `{IsHSet A} : IsHSet B
  := istrunc_equiv_istrunc (n := 0) A e.
Check hset_preserved.

(** * 18.2 [ap] 在泛等路径上的行为 *)

Definition sec_18_2_ap_on_paths := tt.   Check sec_18_2_ap_on_paths.

(** 把 [ap (fun Z => Z * A)] 作用在 [path_universe f] 上，
    得到的正是"对乘积做等价函子"。这类引理在搬运代数结构时必不可少。 *)
Check ap_prod_l_path_universe.
Check ap_prod_r_path_universe.
Check ap_equiv_path_universe.

(** * 18.3 例子：把 [Bool] 的自等价搬到任何两元素类型上 *)

Definition sec_18_3_example := tt.   Check sec_18_3_example.

Definition negb_equiv : Bool <~> Bool
  := equiv_adjointify negb negb
       (fun b => match b with true => idpath | false => idpath end)
       (fun b => match b with true => idpath | false => idpath end).

(** 给定任意 [X] 与等价 [e : Bool <~> X]，把取反搬到 [X] 上：*)
Definition transported_negb (X : Type) (e : Bool <~> X) : X <~> X
  := (e oE negb_equiv) oE (equiv_inverse e).
Check transported_negb.

(** 它确实"就是"取反：在 [X = Bool] 时退化回去。 *)
Definition transported_negb_on_bool : Bool -> Bool
  := transported_negb Bool (equiv_idmap Bool).
Compute transported_negb_on_bool true.
Compute transported_negb_on_bool false.

(** * 18.4 结构不变性：以"单位元"为例 *)

Definition sec_18_4_sip := tt.   Check sec_18_4_sip.

(** 假设 [A] 上有一个二元运算与单位元，[e : A <~> B]，
    则在 [B] 上可以定义出对应的结构，并且 [e] 成为同构。
    下面用 [Bool] 上的 [andb] 演示搬运。 *)
Definition andb_transported (X : Type) (e : Bool <~> X) : X -> X -> X
  := fun x y => e (andb (e^-1 x) (e^-1 y)).
Check andb_transported.

(** 搬运后的运算保持原来的代数定律（这里只看一个具体值）：*)
Compute andb_transported Bool (equiv_idmap Bool) true false.

(** * 18.5 泛等给出的"相等"是真能用来重写的 *)

Definition sec_18_5_rewrite := tt.   Check sec_18_5_rewrite.

(** 若 [P : Type -> Type] 且 [e : A <~> B]，则
    [transport P (path_universe e) : P A -> P B] 就是搬运。
    对 [P := fun X => X] 就是 [e] 本身（[transport_path_universe]）。 *)
Definition transport_id_is_e {A B : Type} (e : A <~> B) (a : A)
  : transport (fun X : Type => X) (path_universe e) a = e a
  := transport_path_universe e a.
Check transport_id_is_e.

(** 对 [P := fun X => X -> X]（自映射的类型），搬运是共轭：*)
Check transport_arrow_toconst_path_universe.

(** * 18.6 泛等不是万能的：计算性问题 *)

Definition sec_18_6_caveat := tt.   Check sec_18_6_caveat.

(** 泛等是公理，[path_universe] 不可计算。
    因此 [transport (fun X => X) (path_universe e) a] 只能靠
    [transport_path_universe] 这条引理化开，[simpl] 对它无能为力。
    这也是为什么库里为同一个事实准备了那么多别名：*)
Check path_universe_transport_idmap.
Check transport_idmap_path_universe.
Check eta_path_universe.

Definition sec_18_END := tt.   Check sec_18_END.
