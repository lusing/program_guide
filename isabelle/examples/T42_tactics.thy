theory T42_tactics
  imports Main
begin

section \<open>42.1 tactic：目标的函数\<close>

text \<open>implementation 手册中段讲 tactic 世界：一个 tactic 是
@{verbatim "thm list -> tactic"}，tactic 是 @{verbatim "thm list -> stateseq"}
——**目标列表进、目标列表出**（外加可能失败）。这层抽象小得惊人，
但第 8 章的每个方法（simp/blast/rule）都是它上面的组合子。
本章三步：用 @{verbatim "tactic"} 方法裸跑经典 tactic、看组合子、
再用 @{verbatim "method_setup"} 把自己的 tactic 包装成方法。\<close>

ML \<open>writeln "==== 42 开始 ===="\<close>

subsection \<open>42.2 经典 tactic 四件套\<close>

text \<open>@{verbatim "rule"} 背后是 @{verbatim "resolve_tac"}（对目标
**反向**应用规则），@{verbatim "erule"} 背后是 @{verbatim "eresolve_tac"}
（先正向消去前提）。2025-2 的 tactic 系**第一个参数是 context**
（实测老写法 @{verbatim "resolve_tac thms i"} 报类型错）。
用 @{verbatim "tactic"} 方法直接裸跑，与 @{verbatim "apply (rule ...)"}
等价：\<close>

lemma tac_conj: "P \<Longrightarrow> Q \<Longrightarrow> P \<and> Q"
  apply (tactic \<open>resolve_tac @{context} @{thms conjI} 1\<close>)
  apply assumption+
  done

text \<open>@{verbatim "assume_tac"}（@{verbatim "assumption"} 的内核）
直接从前提里找匹配。组合子版：@{verbatim "THEN"} 把两个 tactic 串联：\<close>

lemma tac_conj2: "P \<Longrightarrow> Q \<Longrightarrow> Q \<and> P"
  apply (tactic \<open>resolve_tac @{context} @{thms conjI} 1 THEN assume_tac @{context} 1\<close>)
  apply assumption
  done

subsection \<open>42.3 simp 的内核：simp_tac\<close>

text \<open>@{verbatim "simp"} 方法包装着 @{verbatim "simp_tac"}。
现代签名直接吃 @{verbatim "Proof.context"}（实测把
@{verbatim "Simplifier.simpset_of ctxt"} 喂给它反而类型错误）。
包一个"只做头目标"的简化 tactic：\<close>

ML \<open>
  fun my_simp_tac ctxt = simp_tac ctxt 1
\<close>

lemma simp_kernel: "1 + 1 = (2::nat)"
  apply (tactic \<open>my_simp_tac @{context}\<close>)
  done

subsection \<open>42.4 method_setup：把 tactic 注册成方法\<close>

text \<open>@{verbatim "method_setup"} 读一个 ML 解析器（这里
@{verbatim "Scan.succeed"}：不收参数），产出一个方法。
@{verbatim "SIMPLE_METHOD"} 把单目标 tactic 扩到所有目标：\<close>

method_setup my_simp =
  \<open>Scan.succeed (SIMPLE_METHOD o my_simp_tac)\<close>
  "第 42 章的教学方法：simp_tac 包装"

lemma by_mine: "map f [] = []"
  by my_simp

lemma by_mine2: "(1::nat) + 2 = 3 \<and> 2 + 1 = (3::nat)"
  by my_simp

subsection \<open>42.5 attribute_setup：自己的属性\<close>

text \<open>属性是"定理进、定理出"的函数通道。一个教学属性：
@{verbatim "[reversed]"}？不造轮子——实现一个**带副作用的**
@{verbatim "[note_me]"}：挂上它就往日志打一行（属性合法地拿到上下文）：\<close>

attribute_setup note_me =
  \<open>Scan.succeed (Thm.rule_attribute [] (fn _ => fn th =>
     (writeln "note_me: one more theorem"; th)))\<close>
  "把定理挂进日志，原样放行"

lemma noted: "[] @ xs = xs"
  by simp

declare noted [note_me]

subsection \<open>42.6 SUBGOAL 与 ALLGOALS：逐目标编程\<close>

text \<open>@{verbatim "SUBGOAL"} 给你"目标项 + 下标"级编程；
@{verbatim "ALLGOALS"} 把 tactic 铺到每个目标。一个按目标形状分派的
小 tactic——目标是合取就拆，否则 assumption：\<close>

ML \<open>
  fun smart_tac ctxt i =
    SUBGOAL (fn (t, j) =>
      case head_of (HOLogic.dest_Trueprop (Logic.strip_assums_concl t)) of
        Const (\<^const_name>\<open>HOL.conj\<close>, _) => resolve_tac ctxt @{thms conjI} j
      | _ => assume_tac ctxt j) i
\<close>

lemma smart_demo: "\<lbrakk>P; Q\<rbrakk> \<Longrightarrow> P \<and> Q"
  apply (tactic \<open>smart_tac @{context} 1\<close>)+
  done

subsection \<open>42.7 坑位清单（实测）\<close>

text \<open>1. @{verbatim "rtac/dtac/etac"} 这些短名在现代手册里是
   @{verbatim "resolve_tac/dresolve_tac/eresolve_tac"}——短名仍可用
   （兼容层），新代码写全名。
2. @{verbatim "THEN"} 与 @{verbatim "THEN'"}：前者接 tactic（目标号固定），
   后者接"tactic 生成器"（适配 ANYGOAL/目标号参数化）。用错类型
   ML 编译期就红。
3. @{verbatim "tactic"} 方法里的参数是 ML 代码（cartouche 括起），
   里面写的就是普通 ML；@{verbatim "@{thms conjI}"} 把规则列表
   编进 tactic——拼错名字编译失败（第 41 章的红利）。
4. @{verbatim "method_setup"} 的三段式：名字 = 解析器 + 文档串；
   忘了文档串直接语法错误。
5. @{verbatim "SIMPLE_METHOD"} vs @{verbatim "SIMPLE_METHOD'"}：
   前者单目标 tactic 复制到全部目标；后者要 tactic 生成器
   （收目标号）。包装 @{verbatim "simp_tac ctxt 1"} 用前者。
6. 属性里做 IO（writeln）合法但**影响确定性**：两遍运行日志一致
   才能进验证区间——@{verbatim "note_me"} 打印的是定理全文，
   确定所以安全。
7. @{verbatim "apply (tactic ...)"} 的 tactic 是"一次性"代码：
   想复用就 @{verbatim "method_setup"}（42.4）——这就是从脚本
   到工程的升级路径。
8. 目标下标从 1 开始（不是 0）；@{verbatim "ALLGOALS"}
   帮你免掉手写下标。\<close>

thm tac_conj by_mine noted

ML \<open>writeln "==== 42 结束 ===="\<close>

end
