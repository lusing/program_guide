theory S15_retype
  imports Main
begin

section \<open>15.1 Untyped：内存的唯一来源\<close>

text \<open>
  seL4 里所有的内核对象都由 @{verbatim "Untyped"} 内存"改类型"而来
  （retype）。Untyped 能力长这样
  （@{verbatim "l4v/spec/abstract/Structures_A.thy"} 第 102 行）：

  @{verbatim "UntypedCap bool obj_ref nat nat"}

  四个字段依次是：是否设备内存、起始地址、\emph{大小位数}、
  以及 @{verbatim "freeIndex"}——已经用掉到哪里了。

  @{verbatim "freeIndex"} 是 retype 能做到"不重启就回收内存"的关键：
  它把一块 Untyped 分成若干等份，每次 retype 从当前指针往后取，
  取过的部分不允许再取。
\<close>

ML \<open>writeln "==== 15 开始 ===="\<close>

type_synonym obj_ref = nat

record untyped =
  ut_base  :: obj_ref
  ut_bits  :: nat        \<comment> \<open>大小 = 2^bits 字节\<close>
  ut_free  :: nat        \<comment> \<open>freeIndex\<close>

definition ut_size :: "untyped \<Rightarrow> nat" where
  "ut_size u \<equiv> 2 ^ ut_bits u"

definition ut_end :: "untyped \<Rightarrow> obj_ref" where
  "ut_end u \<equiv> ut_base u + ut_size u"

definition fully_used :: "untyped \<Rightarrow> bool" where
  "fully_used u \<equiv> ut_free u = ut_size u"

subsection \<open>15.2 分配：从 freeIndex 往后切\<close>

definition alloc_chunk :: "nat \<Rightarrow> untyped \<Rightarrow> (obj_ref \<times> untyped) option" where
  "alloc_chunk n u \<equiv>
     if n = 0 \<or> ut_free u + n > ut_size u then None
     else Some (ut_base u + ut_free u, u\<lparr> ut_free := ut_free u + n \<rparr>)"

lemma alloc_zero_rejected: "alloc_chunk 0 u = None"
  by (simp add: alloc_chunk_def)

lemma alloc_beyond_end_rejected:
  "ut_free u + n > ut_size u \<Longrightarrow> alloc_chunk n u = None"
  by (simp add: alloc_chunk_def)

lemma alloc_returns_free_pointer:
  "alloc_chunk n u = Some (p, u') \<Longrightarrow> p = ut_base u + ut_free u"
  by (auto simp: alloc_chunk_def split: if_splits)

lemma alloc_advances_free_index:
  "alloc_chunk n u = Some (p, u') \<Longrightarrow> ut_free u' = ut_free u + n"
  by (auto simp: alloc_chunk_def split: if_splits)

lemma alloc_never_moves_base:
  "alloc_chunk n u = Some (p, u') \<Longrightarrow> ut_base u' = ut_base u"
  by (auto simp: alloc_chunk_def split: if_splits)

text \<open>
  @{thm alloc_advances_free_index} 说明 freeIndex 只会\emph{往前}走。
  真实内核里 @{verbatim "resetChunkBits"} 允许把 freeIndex 往回退
  （@{verbatim "Retype_A.thy"} 第 167 行），但只有当被退的那一整块
  确实没有被使用过才行——这正是"对象回收"证明的核心。
\<close>

subsection \<open>15.3 分配出来的块互不重叠\<close>

text \<open>
  这是本章最重要的一条性质：同一个 Untyped 上先后分配的两块
  \emph{不会重叠}。它保证了"两个对象不会占同一块物理内存"。
\<close>

lemma chunks_do_not_overlap:
  "alloc_chunk n u = Some (p, u') \<Longrightarrow>
   alloc_chunk m u' = Some (q, u'') \<Longrightarrow>
   p + n \<le> q"
proof -
  assume h1: "alloc_chunk n u = Some (p, u')"
    and h2: "alloc_chunk m u' = Some (q, u'')"
  have p_def: "p = ut_base u + ut_free u"
    using h1 by (rule alloc_returns_free_pointer)
  have q_def: "q = ut_base u' + ut_free u'"
    using h2 by (rule alloc_returns_free_pointer)
  have free': "ut_free u' = ut_free u + n"
    using h1 by (rule alloc_advances_free_index)
  have base': "ut_base u' = ut_base u"
    using h1 by (rule alloc_never_moves_base)
  show "p + n \<le> q"
    by (simp add: p_def q_def free' base')
qed

lemma chunks_stay_inside:
  "alloc_chunk n u = Some (p, u') \<Longrightarrow> p + n \<le> ut_end u"
proof -
  assume h: "alloc_chunk n u = Some (p, u')"
  then have "ut_free u + n \<le> ut_size u"
    by (auto simp: alloc_chunk_def split: if_splits)
  then show "p + n \<le> ut_end u"
    by (auto simp: ut_end_def alloc_returns_free_pointer[OF h])
qed

subsection \<open>15.4 retype 之前必须没有子孙\<close>

text \<open>
  @{verbatim "CSpace_A.thy"} 第 106 行的 @{verbatim "derive_cap"} 对
  Untyped 能力要求 @{verbatim "ensure_no_children"}：
  一块 Untyped 只要派生出过子对象，就不能再被整体 retype 了。

  这条规则的作用是防止"父亲把儿子脚下的地毯抽走"。
\<close>

type_synonym cslot = nat

definition has_children :: "cslot set \<Rightarrow> bool" where
  "has_children ds \<equiv> ds \<noteq> {}"

definition ensure_no_children :: "cslot set \<Rightarrow> bool" where
  "ensure_no_children ds \<equiv> \<not> has_children ds"

lemma empty_means_no_children: "ensure_no_children {}"
  by (simp add: ensure_no_children_def has_children_def)

lemma child_blocks_retype: "\<not> ensure_no_children {s}"
  by (simp add: ensure_no_children_def has_children_def)

ML \<open>
  writeln (@{make_string} @{thm chunks_do_not_overlap});
  writeln (@{make_string} @{thm chunks_stay_inside})
\<close>

ML \<open>writeln "==== 15 结束 ===="\<close>

end
