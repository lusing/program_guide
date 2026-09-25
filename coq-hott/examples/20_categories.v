(** 示例 20：范畴论基础
    HoTT 里的 [PreCategory]：对象是类型，态射是集合，
    但"范畴的等价"不能用相等来谈。

    对应文档：docs/20-categories.md *)

Require Import HoTT.
(** 注意：范畴论不在 [HoTT.v] 的默认导出里，需要单独引入。 *)
(** 【坑】引入 [HoTT.Categories] 会覆盖 path_scope 里的 [/] 记号
    （范畴论用它表示商范畴），Rocq 会往 stderr 打一条
    [notation-overridden] 警告。本教程的验证要求 stderr 为空，
    所以这里显式关掉这一类警告。 *)
Set Warnings "-notation-overridden".
Require Import HoTT.Categories.
Local Open Scope path_scope.

Definition sec_20_BEGIN := tt.   Check sec_20_BEGIN.

(** * 20.1 [PreCategory] 的结构 *)

Definition sec_20_1_structure := tt.   Check sec_20_1_structure.

Print PreCategory.
Check object.
Check morphism.
Check identity.
Check Build_PreCategory'.

(** 一个预范畴由这些字段组成：对象类型、态射类型族 [morphism s d]、
    恒等态射、复合、结合律（正反两个方向都要）、左右单位律、
    以及"态射是集合"这一条。
    最后一条保证了范畴论里不会出现高阶同伦的麻烦。 *)

(** * 20.2 动手造一个：离散范畴

    对象是一个集合 [A]，态射 [a -> b] 就是 [a = b]。
    这是最简单的范畴，也是"类型即群胚"这一观点的直接体现。 *)

Definition sec_20_2_discrete := tt.   Check sec_20_2_discrete.

(** 用 Record 的具名字段语法写，字段顺序就不会搞错：*)
Definition discrete_category (A : Type) `{IsHSet A} : PreCategory :=
  {| object := A ;
     morphism := (fun a b : A => a = b) ;
     identity := (fun a : A => 1) ;
     compose := (fun (s d d' : A) (q : d = d') (p : s = d) => p @ q) ;
     associativity := (fun x1 x2 x3 x4 (m1 : x1 = x2) (m2 : x2 = x3) (m3 : x3 = x4)
                       => concat_p_pp m1 m2 m3) ;
     associativity_sym := (fun x1 x2 x3 x4 (m1 : x1 = x2) (m2 : x2 = x3) (m3 : x3 = x4)
                           => concat_pp_p m1 m2 m3) ;
     left_identity := (fun a b (f : a = b) => concat_p1 f) ;
     right_identity := (fun a b (f : a = b) => concat_1p f) ;
     identity_identity := (fun x : A => 1) ;
     trunc_morphism := (fun s d : A => _) |}.
Check discrete_category.

(** 试试它：*)
Compute (@morphism (discrete_category Bool) true false).
Check (@identity (discrete_category Bool) true).

(** * 20.3 函子 *)

Definition sec_20_3_functor := tt.   Check sec_20_3_functor.

Check Functor.
Check Build_Functor.
Check object_of.
Check morphism_of.

(** 函子是保持恒等与复合的映射。定义它与定义范畴一样，
    只是字段多了"保持恒等""保持复合"两条。 *)

(** * 20.4 为什么叫"预"范畴 *)

Definition sec_20_4_pre := tt.   Check sec_20_4_pre.

Check Category.
Print Category.

(** [PreCategory] 只要求态射是集合；[Category] 额外要求
    "对象类型与等价关系相容"（即对象层已经是一个 1-型），
    这样"范畴等价 = 范畴相等"才成立——这正是泛等精神在范畴论里的体现。 *)

(** * 20.5 范畴论里的"相等"一律换成"等价" *)

Definition sec_20_5_equivalence := tt.   Check sec_20_5_equivalence.

(** 在 HoTT 里说"两个范畴相同"是没意义的（[Type] 不是集合），
    要说"它们等价"。同理，两个对象的"同构"取代了"相等"。 *)
Check (fun (C : PreCategory) => @morphism C).

(** 这也是为什么本库把这套东西叫 [WildCat]（野范畴）可以并行发展：
    有时我们想保留高阶结构，那就用野范畴而不是预范畴。 *)
Check (fun (A : Type) => A).   (* WildCat 的对象就是类型，态射可以不是集合 *)

(** * 20.6 实际使用建议 *)

Definition sec_20_6_advice := tt.   Check sec_20_6_advice.

(** 范畴论模块相当庞大（代数、伴随、极限都在里面）。
    入门时只需记住三件事：
      1. [PreCategory] 的态射是集合，所以证态射相等可以用 [hset_path2]；
      2. 凡是教科书里写"相等"的地方，这里通常要换成"同构/等价"；
      3. 需要 [Univalence] 才能把范畴等价升级为范畴相等。 *)
Check hset_path2.

Definition sec_20_END := tt.   Check sec_20_END.
