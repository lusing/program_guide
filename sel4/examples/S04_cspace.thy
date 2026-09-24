theory S04_cspace
  imports Main
begin

section \<open>4.1 CSpace：一张由 CNode 组成的图\<close>

text \<open>
  用户态引用能力用的是"路径"（一个机器字 @{verbatim "CPtr"}），内核内部用的是
  \emph{槽位指针} @{verbatim "cslot_ptr"}（真实定义
  @{verbatim "l4v/spec/abstract/Structures_A.thy"} 第 84–85 行）：

  @{verbatim "type_synonym cnode_index = bool list"}
  @{verbatim "type_synonym cslot_ptr = obj_ref * cnode_index"}

  即"哪个对象 + 对象内的第几号槽"。把用户给的路径翻译成槽位指针，就是
  @{verbatim "resolve_address_bits"}（@{verbatim "CSpace_A.thy"} 第 203 行），
  它是整个内核里唯一一处"用户字到内核指针"的转换。

  转换规则只有三条，都由 CNode 能力决定：
  \begin{itemize}
    \item @{verbatim "guard"}：路径开头的若干位必须与 guard 逐位相等，否则
          @{verbatim "GuardMismatch"}；
    \item @{verbatim "bits"}：guard 之后的 bits 位是本级 CNode 的索引；
    \item 剩下的位交给下一级 CNode（如果索引到的还是 CNode 能力）。
  \end{itemize}
\<close>

ML \<open>writeln "==== 04 开始 ===="\<close>

type_synonym obj_ref = nat
type_synonym cnode_index = "bool list"
type_synonym cslot_ptr = "obj_ref \<times> cnode_index"

datatype cap =
    NullCap
  | EndpointCap obj_ref
  | CNodeCap obj_ref nat "bool list"   \<comment> \<open>指针 / 翻译位数 / guard\<close>

subsection \<open>4.2 一级解析\<close>

text \<open>guard 不匹配就失败；匹配则切出 bits 位索引，其余留作下一级。\<close>

definition resolve_step :: "bool list \<Rightarrow> nat \<Rightarrow> bool list \<Rightarrow> (cnode_index \<times> bool list) option" where
  "resolve_step guard bits path \<equiv>
     if take (length guard) path = guard
     then Some (take bits (drop (length guard) path),
                drop bits (drop (length guard) path))
     else None"

lemma step_guard_mismatch:
  "take (length guard) path \<noteq> guard \<Longrightarrow> resolve_step guard bits path = None"
  by (simp add: resolve_step_def)

lemma step_index_is_prefix:
  "resolve_step guard bits path = Some (idx, rest) \<Longrightarrow>
   idx = take bits (drop (length guard) path)"
  by (auto simp: resolve_step_def split: if_splits)

lemma step_splits_path:
  "resolve_step guard bits path = Some (idx, rest) \<Longrightarrow> guard @ idx @ rest = path"
proof -
  assume h: "resolve_step guard bits path = Some (idx, rest)"
  from h have g: "take (length guard) path = guard"
    and i: "idx = take bits (drop (length guard) path)"
    and r: "rest = drop bits (drop (length guard) path)"
    by (auto simp: resolve_step_def split: if_splits)
  have "guard @ idx @ rest =
        take (length guard) path @ take bits (drop (length guard) path)
          @ drop bits (drop (length guard) path)"
    by (simp add: g i r)
  also have "\<dots> = take (length guard) path @ drop (length guard) path"
    by (simp only: append_take_drop_id append_assoc)
  also have "\<dots> = path"
    by (rule append_take_drop_id)
  finally show "guard @ idx @ rest = path" .
qed

text \<open>
  @{thm step_splits_path} 是"解析不会丢位"的形式化说法：guard、索引、剩余三段
  拼回去必须还是原来的路径。真实内核里对应的性质是：解析出的槽位与剩余位数
  之和守恒——@{verbatim "resolve_address_bits'"} 的终止性证明就靠它
  （@{verbatim "CSpace_A.thy"} 第 197 行的 @{verbatim "termination"} 用的
  是 @{verbatim "measure (\<lambda>(z,cap,cs). size cs)"}）。
\<close>

subsection \<open>4.3 多级解析\<close>

text \<open>
  CNode 里存的能力如果还是 CNode 能力，就继续往下走，直到路径用完。
  模型把 CNode 的内容直接写成"索引到可选能力"的函数。

  真实内核靠 @{verbatim "word_bits"} 天然限制了路径长度（一个 CPtr 只有
  那么多位），所以递归必然终止。模型显式带一份\emph{燃料}：跑不完就失败。
  这比"证明终止"更好懂，而且和真实约束等价。
\<close>

type_synonym cnode_contents = "cnode_index \<Rightarrow> cap option"

record cspace_state =
  cs_root  :: cslot_ptr
  cs_nodes :: "obj_ref \<Rightarrow> cnode_contents"

definition empty_cspace :: cspace_state where
  "empty_cspace \<equiv> \<lparr> cs_root = (0, []), cs_nodes = \<lambda>_. \<lambda>_. None \<rparr>"

fun resolve_fuel :: "nat \<Rightarrow> cspace_state \<Rightarrow> cap \<Rightarrow> bool list \<Rightarrow> cslot_ptr option" where
  "resolve_fuel 0 s cap path = None"
| "resolve_fuel (Suc n) s (CNodeCap ptr bits guard) path =
     (case resolve_step guard bits path of
        None \<Rightarrow> None
      | Some (idx, rest) \<Rightarrow>
          (case cs_nodes s ptr idx of
             None \<Rightarrow> None
           | Some cap' \<Rightarrow> if rest = [] then Some (ptr, idx)
                            else resolve_fuel n s cap' rest))"
| "resolve_fuel (Suc n) s NullCap path = None"
| "resolve_fuel (Suc n) s (EndpointCap _) path = None"

definition resolve :: "cspace_state \<Rightarrow> cap \<Rightarrow> bool list \<Rightarrow> cslot_ptr option" where
  "resolve s cap path \<equiv> resolve_fuel (Suc (length path)) s cap path"

text \<open>
  注意 @{verbatim "resolve_fuel (Suc n) s NullCap path = None"} 这一支：
  路径还没走完却遇到非 CNode 能力，就是 @{verbatim "DepthMismatch"} 那类
  错误的来源。真实定义（@{verbatim "CSpace_A.thy"} 第 251 行的
  @{verbatim "lookup_slot_for_cnode_op"}）会把它精确到"还剩几位"。
\<close>

lemma resolve_leaf_is_none: "resolve s NullCap path = None"
  by (simp add: resolve_def)

lemma resolve_endpoint_is_none: "resolve s (EndpointCap p) path = None"
  by (simp add: resolve_def)

lemma resolve_empty_path_at_cnode:
  "cs_nodes s ptr [] \<noteq> None \<Longrightarrow> resolve s (CNodeCap ptr bits []) [] = Some (ptr, [])"
  by (auto simp: resolve_def resolve_step_def split: option.splits)

subsection \<open>4.4 空路径解析到根槽位本身\<close>

text \<open>
  这是 @{verbatim "lookup_cap_and_slot"}（@{verbatim "CSpace_A.thy"} 第 216 行）
  在 depth = 0 时的行为：不需要查任何 CNode，直接返回根槽位。
\<close>

definition lookup_slot :: "cspace_state \<Rightarrow> cap \<Rightarrow> bool list \<Rightarrow> cslot_ptr option" where
  "lookup_slot s root path \<equiv> if path = [] then Some (cs_root s) else resolve s root path"

lemma empty_path_resolves_to_root: "lookup_slot s root [] = Some (cs_root s)"
  by (simp add: lookup_slot_def)

text \<open>深度为 0 的"我自己的 CSpace 根"就是这样取的：@{verbatim "tcb_ctable"} 里
  那张 CNode 能力所指向的槽。真实定义在 @{verbatim "CSpace_A.thy"} 第 208 行的
  @{verbatim "lookup_slot_for_thread"}。\<close>

subsection \<open>4.5 井形 CNode：槽位索引长度必须一致\<close>

text \<open>
  @{verbatim "Structures_A.thy"} 第 471 行的 @{verbatim "well_formed_cnode_n"}
  要求一个 CNode 的所有键长度都等于它的位数。少了这个约束，"同一个槽位"
  就会有两种写法，删除与撤销时会漏掉幽灵槽。
\<close>

definition well_formed_cnode_n :: "nat \<Rightarrow> cnode_contents \<Rightarrow> bool" where
  "well_formed_cnode_n n cn \<equiv> \<forall>idx. cn idx \<noteq> None \<longrightarrow> length idx = n"

lemma empty_cnode_is_well_formed: "well_formed_cnode_n n (\<lambda>_. None)"
  by (simp add: well_formed_cnode_n_def)

lemma well_formed_slot_length:
  "well_formed_cnode_n n cn \<Longrightarrow> cn idx = Some c \<Longrightarrow> length idx = n"
  by (auto simp: well_formed_cnode_n_def)

text \<open>
  真实内核里这条不变式是"证明义务"的一部分：每个改动 CNode 的操作都要证明
  它保持 @{verbatim "well_formed_cnode_n"}。第 17 章会看到这类不变式
  是怎么被组织起来的。
\<close>

ML \<open>
  writeln (@{make_string} @{thm step_splits_path});
  writeln (@{make_string} @{thm well_formed_slot_length})
\<close>

ML \<open>writeln "==== 04 结束 ===="\<close>

end
