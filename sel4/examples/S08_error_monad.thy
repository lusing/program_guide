theory S08_error_monad
  imports Main "HOL-Library.Monad_Syntax"
begin

section \<open>8.1 第二道门槛：错误单子\<close>

text \<open>
  内核操作失败要给用户返回一个错误码。用户看到的错误在
  @{verbatim "seL4/libsel4/include/sel4/errors.h"} 里：

  @{verbatim "seL4_NoError / seL4_InvalidArgument / seL4_InvalidCapability /"}
  @{verbatim "seL4_IllegalOperation / seL4_RangeError / seL4_AlignmentError /"}
  @{verbatim "seL4_FailedLookup / seL4_TruncatedMessage / seL4_DeleteFirst /"}
  @{verbatim "seL4_RevokeFirst / seL4_NotEnoughMemory"}

  规范侧对应的类型是 @{verbatim "l4v/spec/abstract/ExceptionTypes_A.thy"} 里的
  @{verbatim "syscall_error"}，而"可能出错的计算"用
  \emph{错误单子} @{verbatim "se_monad"} 表达。它在
  @{verbatim "Nondet_Monad.thy"} 里就是非确定单子的结果类型换成
  @{verbatim "'e + 'a"}（第 247–282 行）：

  @{verbatim "returnOk"}, @{verbatim "throwError"}, @{verbatim "bindE"},
  @{verbatim "liftE"}, @{verbatim "whenE"}, @{verbatim "unlessE"}, @{verbatim "lift"}.

  注意 @{verbatim "doE ... odE"} 与 @{verbatim "do ... od"} 是两套记号：
  前者里的绑定是 @{verbatim "bindE"}，遇到 @{verbatim "Inl"}（错误）就短路。
\<close>

ML \<open>writeln "==== 08 开始 ===="\<close>

type_synonym ('s,'e,'a) se = "'s \<Rightarrow> ((('e + 'a) \<times> 's) set \<times> bool)"

definition returnOk :: "'a \<Rightarrow> ('s,'e,'a) se" where
  "returnOk v \<equiv> \<lambda>s. ({(Inr v, s)}, False)"

definition throwError :: "'e \<Rightarrow> ('s,'e,'a) se" where
  "throwError e \<equiv> \<lambda>s. ({(Inl e, s)}, False)"

definition bindE :: "('s,'e,'a) se \<Rightarrow> ('a \<Rightarrow> ('s,'e,'b) se) \<Rightarrow> ('s,'e,'b) se" where
  "bindE m f \<equiv> \<lambda>s. (
     \<Union>p \<in> fst (m s). (case p of
                          (Inl e, s') \<Rightarrow> {(Inl e, s')}
                        | (Inr v, s') \<Rightarrow> fst (f v s')),
     snd (m s) \<or> (\<exists>p \<in> fst (m s). case p of
                          (Inl e, s') \<Rightarrow> False
                        | (Inr v, s') \<Rightarrow> snd (f v s')))"

adhoc_overloading bind == bindE

definition liftE :: "'s \<Rightarrow> ('s,'e,'a) se \<Rightarrow> ('s,'e,'a) se" where
  "liftE dummy m \<equiv> m"

text \<open>
  @{verbatim "liftE"} 在 l4v 里是"把一个不会出错的计算放进可能出错的上下文"。
  模型里它是恒等式——真正的 @{verbatim "liftE"} 要做 @{verbatim "Inr"} 包装：
  @{verbatim "liftE m = bind m (returnOk)"}。这里用一个更接近真实的版本：
\<close>

definition lift_nondet :: "('s \<Rightarrow> ('a \<times> 's) set \<times> bool) \<Rightarrow> ('s,'e,'a) se" where
  "lift_nondet m \<equiv> \<lambda>s. ((\<lambda>(a, s'). (Inr a, s')) ` fst (m s), snd (m s))"

definition whenE :: "bool \<Rightarrow> ('s,'e,unit) se \<Rightarrow> ('s,'e,unit) se" where
  "whenE P m \<equiv> if P then m else returnOk ()"

definition unlessE :: "bool \<Rightarrow> ('s,'e,unit) se \<Rightarrow> ('s,'e,unit) se" where
  "unlessE P m \<equiv> if P then returnOk () else m"

subsection \<open>8.2 短路：错误就是左值\<close>

lemma bindE_returnOk_left: "bindE (returnOk v) f = f v"
  by (rule ext) (auto simp: bindE_def returnOk_def split: prod.splits)

lemma bindE_throw_left: "bindE (throwError e) f = throwError e"
  by (rule ext) (auto simp: bindE_def throwError_def)

lemma bindE_case_returnOk_fst:
  "(case r of Inl e \<Rightarrow> {(Inl e, s')} | Inr v \<Rightarrow> fst (returnOk v s')) = {(r, s')}"
  by (auto simp: returnOk_def split: sum.split)

lemma bindE_case_returnOk_snd:
  "(case r of Inl e \<Rightarrow> False | Inr v \<Rightarrow> snd (returnOk v s')) = False"
  by (auto simp: returnOk_def split: sum.split)

lemma bindE_returnOk_right: "bindE m returnOk = m"
proof (rule ext)
  fix s
  show "bindE m returnOk s = m s"
  proof (rule prod_eqI)
    show "fst (bindE m returnOk s) = fst (m s)"
      by (auto simp: bindE_def bindE_case_returnOk_fst)
    show "snd (bindE m returnOk s) = snd (m s)"
      by (auto simp: bindE_def bindE_case_returnOk_snd)
  qed
qed

text \<open>
  @{thm bindE_throw_left} 就是 @{verbatim "doE"} 记号的语义：
  \emph{一旦出错，后面全部跳过}。C 代码里对应的写法是
  @{verbatim "if (err) return err;"} 的一长串，而规范里靠单子自动完成。
  第 18 章讲 C 精化时，会看到这两者是怎么被对应起来的。
\<close>

subsection \<open>8.3 一个真实的 decode 片段\<close>

text \<open>
  @{verbatim "l4v/spec/abstract/Decode_A.thy"} 第 49 行的
  @{verbatim "decode_cnode_invocation"} 开头是这样：

  @{verbatim "unlessE (gen_invocation_type label \<in> set [CNodeRevoke .e. CNodeSaveCaller]) $"}
  @{verbatim "  throwError IllegalOperation;"}
  @{verbatim "whenE (length args < 2) (throwError TruncatedMessage);"}

  即"标签不在合法区间就报 IllegalOperation，参数不够就报 TruncatedMessage"。
  模型照抄一遍：
\<close>

datatype syscall_error = IllegalOperation | TruncatedMessage | InvalidCapability | DeleteFirst

datatype gen_label = CNodeRevoke | CNodeDelete | CNodeCopy | CNodeMint | CNodeMove | OtherLabel

definition valid_cnode_labels :: "gen_label set" where
  "valid_cnode_labels \<equiv> {CNodeRevoke, CNodeDelete, CNodeCopy, CNodeMint, CNodeMove}"

definition decode_head :: "gen_label \<Rightarrow> nat list \<Rightarrow> (nat,syscall_error,nat) se" where
  "decode_head label args \<equiv> do {
     unlessE (label \<in> valid_cnode_labels) (throwError IllegalOperation);
     whenE (length args < 2) (throwError TruncatedMessage);
     returnOk (args ! 0)
   }"

lemma decode_bad_label:
  "label \<notin> valid_cnode_labels \<Longrightarrow> decode_head label args = throwError IllegalOperation"
  by (simp add: decode_head_def unlessE_def whenE_def bindE_throw_left)

lemma decode_short_args:
  "CNodeCopy \<in> valid_cnode_labels \<Longrightarrow> length args < 2 \<Longrightarrow>
   decode_head CNodeCopy args = throwError TruncatedMessage"
  by (simp add: decode_head_def unlessE_def whenE_def
                bindE_returnOk_left bindE_throw_left)

lemma decode_ok:
  "length args \<ge> 2 \<Longrightarrow> decode_head CNodeMint args = returnOk (args ! 0)"
  by (simp add: decode_head_def unlessE_def whenE_def valid_cnode_labels_def
                bindE_returnOk_left)

text \<open>
  这三条就是"解码"的全部形态：\emph{先查合法性，再把用户字切成内部结构}。
  注意错误是\emph{短路}的——标签非法时，参数够不够根本不会被检查。
  真实内核里这个顺序决定了用户看到哪个错误码，所以证明里必须精确到这一步。
\<close>

subsection \<open>8.4 错误不会污染状态\<close>

text \<open>
  throwError 之后状态保持原样：这一点让"失败的系统调用不会改变内核状态"
  成为可证的命题。
\<close>

lemma throw_keeps_state:
  "(r, s') \<in> fst (throwError e s) \<Longrightarrow> s' = s"
  by (auto simp: throwError_def)

lemma no_error_means_success:
  "(r, s') \<in> fst (returnOk v s) \<Longrightarrow> r = Inr v \<and> s' = s"
  by (auto simp: returnOk_def)

subsection \<open>8.5 把错误提升成故障（fault）\<close>

text \<open>
  系统调用里还有一类"不是错误，是故障"的情况：地址越界、能力查找失败等，
  会被包装成 @{verbatim "fault"} 递给线程的 fault handler，
  见 @{verbatim "seL4/src/api/faults.c"} 与
  @{verbatim "l4v/spec/abstract/ExceptionTypes_A.thy"}。
  第 9 章讲 @{verbatim "call_kernel"} 的三阶段时，会看到 fault 与 error
  分处在两个不同的阶段。
\<close>

datatype fault = CapFault | VMFault | UnknownFault

datatype 'a with_fault = Ok 'a | Faulted fault

definition to_fault :: "syscall_error \<Rightarrow> fault" where
  "to_fault e \<equiv> case e of IllegalOperation \<Rightarrow> CapFault | _ \<Rightarrow> UnknownFault"

lemma illegal_is_cap_fault: "to_fault IllegalOperation = CapFault"
  by (simp add: to_fault_def)

ML \<open>
  writeln (@{make_string} @{thm bindE_throw_left});
  writeln (@{make_string} @{thm decode_bad_label})
\<close>

ML \<open>writeln "==== 08 结束 ===="\<close>

end
