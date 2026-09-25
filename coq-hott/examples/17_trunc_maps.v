(** 示例 17：截断映射与嵌入
    把"截断"这个概念搬到映射上：n-截断映射、嵌入、满射。

    对应文档：docs/17-trunc-maps.md *)

Require Import HoTT.
Local Open Scope path_scope.

Definition sec_17_BEGIN := tt.   Check sec_17_BEGIN.

(** * 17.1 [IsTruncMap]：所有纤维都是 n-型 *)

Definition sec_17_1_definition := tt.   Check sec_17_1_definition.

Print IsTruncMap.
Check (fun (n : trunc_index) (A B : Type) (f : A -> B) => IsTruncMap n f).

(** 三个最重要的特例：
      [IsTruncMap (-2) f]  = 所有纤维可缩 = [f] 是等价
      [IsTruncMap (-1) f]  = 所有纤维是命题 = [f] 是嵌入
      [IsConnMap (Tr (-1)) f] = 所有纤维 merely  inhabited = [f] 是满射 *)

Locate "IsEmbedding".
Locate "IsSurjection".

(** * 17.2 嵌入 *)

Definition sec_17_2_embedding := tt.   Check sec_17_2_embedding.

(** 嵌入的等价刻画：[f] 是嵌入 ⟺ [ap f : x = y -> f x = f y] 是等价。 *)
Check isembedding_sect_ap.
Check isequiv_ap.
Check equiv_ap.

(** 由"有左逆"可以得到嵌入：*)
Check isinj_embedding.
Check isinj_section.

(** 单射（作为函数）与嵌入（作为类型论概念）不是一回事：
    单射说的是 [f x = f y -> x = y]，嵌入要求的是这个映射本身是等价。 *)
Check (fun (A B : Type) (f : A -> B) => IsInjective f).

(** * 17.3 等价与截断映射的关系 *)

Definition sec_17_3_relation := tt.   Check sec_17_3_relation.

(** 纤维可缩 ⇒ 是等价（第 08 章手工证过一次）：*)
Check isequiv_contr_map.

(** 等价的纤维当然可缩：*)
Check contr_map_isequiv.

(** 等价保持截断层级（双向）：*)
Check istrunc_isequiv_istrunc.
Check istrunc_equiv_istrunc.

(** * 17.4 例子：投影是嵌入还是等价？ *)

Definition sec_17_4_examples := tt.   Check sec_17_4_examples.

(** 从 [{y : X & x = y}] 忘掉第二分量，是一个等价（第 08 章 [contr_basedpaths]）：*)
Check contr_basedpaths.
Check isequiv_pr1.

(** 从 [A * B] 投到 [A]，当 [B] 是命题时是嵌入：*)
Check equiv_ap_inv.

(** * 17.5 满射 + 嵌入 = 等价 *)

Definition sec_17_5_surj_emb := tt.   Check sec_17_5_surj_emb.

Check isequiv_surj_emb.
Check isembedding_precompose_surjection_hset.
Check issurj_retr.

(** 这是把任意映射分解成"满射 ∘ 嵌入"的因式分解定理的关键一步。 *)
Check image.
Check himage.

(** * 17.6 截断映射的复合与稳定性 *)

Definition sec_17_6_stability := tt.   Check sec_17_6_stability.

(** 截断映射在复合、拉回下稳定（第 19 章的余极限会用到）：*)
Check istruncmap_mapinO_tr.
Check mapinO_tr_istruncmap.

(** 与"是 n-型"的对应关系：*)
Check (fun (n : trunc_index) (A B : Type) (f : A -> B) => IsTruncMap n f).

Definition sec_17_END := tt.   Check sec_17_END.
