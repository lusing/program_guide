(** 示例 15：截断操作
    [Tr n A]、[merely]、截断递归、连通性与满射。

    对应文档：docs/15-truncations.md *)

Require Import HoTT.
Local Open Scope path_scope.

Definition sec_15_BEGIN := tt.   Check sec_15_BEGIN.

(** * 15.1 截断：把任意类型压成 n-型 *)

Definition sec_15_1_tr := tt.   Check sec_15_1_tr.

Check Tr.
Check tr.
Check Trunc_rec.
Check Trunc_rec_tr.

(** [Tr n A] 是 [A] 的"n-型化"：它保留 [A] 的 n-层以下的信息，
    把更高层的路径统统压平。[tr : A -> Tr n A] 是它的引入。 *)

(** 截断后的类型确实落在第 n 层（[In (Tr n)] 与 [IsTrunc n] 是同一件事的两面）：*)
Check istrunc_inO_tr.
Check inO_tr_istrunc.
Check trunc_iff_isequiv_truncation.

(** 若 [A] 本来就是 n-型，则 [tr : A -> Tr n A] 本身是等价：*)
Check isequiv_tr.
Check equiv_tr.
Check untrunc_istrunc.

(** * 15.2 [merely]：命题化的存在 *)

Definition sec_15_2_merely := tt.   Check sec_15_2_merely.

Check merely.
Check hexists.
Check hor.
Locate "\/".

(** [merely A] 是 [A] 的 (-1)-截断：它只记得"A 是否有居民"，
    忘了是哪一个居民。这是构造数学里"存在"的标准形式。 *)
Definition merely_of {A : Type} (a : A) : merely A := tr a.
Check merely_of.

(** [merely A] 是一个 [HProp]，所以它的两个居民自动相等：*)
Definition merely_unique {A : Type} (x y : merely A) : x = y
  := path_ishprop x y.
Check merely_unique.

(** * 15.3 截断递归：从 [Tr n A] 出去的唯一方式 *)

Definition sec_15_3_recursion := tt.   Check sec_15_3_recursion.

(** 要定义 [Tr n A -> X]，只要定义 [A -> X]，前提是 [X] 本身是 n-型。
    ——这正是"截断"这个词的全部含义：它把信息压到 n 层，
    所以只能被 n-型的目标接收。 *)
Check Trunc_rec.

(** 例子：从 [merely A] 出发只能得到 h-prop 级别的结论。 *)
Definition merely_to_hprop {A : Type} (P : Type) `{IsHProp P} (f : A -> P)
  : merely A -> P
  := Trunc_rec f.
Check merely_to_hprop.

(** 【坑】目标不是 n-型时，[Trunc_rec] 会要求你给出 [IsTrunc n X] 的实例，
    类型类搜索失败的错误信息往往很晦涩。 *)

(** * 15.4 处理"存在"的 tactic：[strip_truncations] *)

Definition sec_15_4_strip := tt.   Check sec_15_4_strip.

(** 证明目标是 h-prop 时，可以先把 [merely] 的居民"剥掉"当成真的居民用，
    剩下的目标由 [IsHProp] 保证唯一。库里的 tactic 叫 [strip_truncations]。 *)

Definition merely_inhabited_implies_ishprop {A P : Type} `{IsHProp P}
  : (A -> P) -> merely A -> P
  := fun f => Trunc_rec f.
Check merely_inhabited_implies_ishprop.

(** * 15.5 连通性与满射 *)

Definition sec_15_5_connected := tt.   Check sec_15_5_connected.

Check IsConnected.
Check IsSurjection.
Check BuildIsSurjection.
Check issurj_retr.

(** 满射 = "每个纤维都被 merely 地命中"：
    [IsSurjection f := IsConnMap (Tr (-1)) f]。 *)
Check (fun (A B : Type) (f : A -> B) => IsSurjection f).

(** 有单侧逆的映射一定是满射：*)
Check issurj_retr.

(** 连通的例子：圆是 0-连通的。 *)
Check isconnected_Circle.

(** * 15.6 满射 + 嵌入 = 等价 *)

Definition sec_15_6_surj_emb := tt.   Check sec_15_6_surj_emb.

Check isequiv_surj_emb.
Check isembedding_precompose_surjection_hset.

(** 这条分解是 HoTT 里"任何映射都能分解成满射接嵌入"的基础，
    在范畴论（第 20 章）与像分解里反复出现。 *)
Check image.
Check himage.

Definition sec_15_END := tt.   Check sec_15_END.
