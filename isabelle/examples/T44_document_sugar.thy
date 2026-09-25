theory T44_document_sugar
  imports Main
begin

section \<open>44.1 理论即文档：LaTeX sugar\<close>

text \<open>sugar 手册（sugar.pdf）讲"把理论排版成论文"的通道：
理论文件里的 @{verbatim section}/@{verbatim text} 是**文档命令**，
构建文档时进 LaTeX 流；@{verbatim "@{thm ...}"} 一族文档反引号在
**理论处理期**就被检查与展开（拼错名字构建直接失败——本章实测），
排版期再变成 @{verbatim "\\isa{...}"} 形式的 LaTeX。
本教程日常不开 LaTeX 输出（验证走标记区间），但反引号的**检查**
一直在工作。\<close>

ML \<open>writeln "==== 44 开始 ===="\<close>

subsection \<open>44.2 文档反引号五件套\<close>

text \<open>下面五条全部**经过构建检查**（展开失败 = 构建失败）：

  - 定理：@{thm append_Nil2}
  - 定理列表（display 风格）：@{thm [display] map_append}
  - 项：@{term "map f (xs @ ys)"}
  - 类型：@{typ "'a list \<Rightarrow> 'a list"}
  - 常量名：@{const map}
  - 现场小定理：@{lemma "length (map f xs) = length xs" by simp}\<close>

subsection \<open>44.3 markup：结构、强调与列表\<close>

text \<open>@{bold \<open>粗体\<close>}、@{verbatim "verbatim"}，
以及 markdown 风格的列表与引用（本段所在的 text 块本身就是一个样例）：

  - 咖啡
  - 茶
    - 茶里再嵌一层

以及 LaTeX 换行的两个空格结尾。\<close>

text \<open>标题层级：@{verbatim section}/@{verbatim subsection}/
@{verbatim subsubsection}；编号与目录由 LaTeX 侧（root.tex 模板）决定，
理论侧只给结构。\<close>

subsection \<open>44.4 thm 反引号的参数\<close>

text \<open>常用参数：@{verbatim "[display]"}（独占行）、
@{verbatim "[margin = 50]"}（换行宽度）、@{verbatim "[no_vars]"}
（把自由变量打成 @{verbatim ?x} 下标形式，排版更干净）——
@{thm [margin = 45] append_assoc}——参数影响的是**生成的 LaTeX**，
构建检查不受影响。\<close>

subsection \<open>44.5 会话文档的构建（文档节）\<close>

text \<open>要真出 PDF，三步：

  1. ROOT 里给会话加 @{verbatim "document [pdf]"} 或
     @{verbatim "document_files"}；
  2. 理论名声明 @{verbatim "theory T44"} 对应的
     @{verbatim "document/root.tex"}（发行版 @{verbatim "src/Doc"}
     有现成模板）；
  3. @{verbatim "isabelle build -D . -o document=pdf"}——需要本机
     LaTeX 环境（教程验证链不含，故本教程不实际产 PDF）。

反引号展开后的中间产物在 @{verbatim "build/"} 会话目录的
@{verbatim "document/"} 下，可以只取 @{verbatim ".tex"} 不编译。\<close>

subsection \<open>44.6 坑位清单（实测）\<close>

text \<open>1. **拼错名字构建必死**：@{verbatim "@{thm append_Nil99}"} 报
   @{verbatim "Undefined fact"}——文档反引号是编译期检查，
   别当纯文本。
2. @{verbatim "@{thm [display] ...}"} 的参数表后要有空格再接名；
   @{verbatim "[display]foo"} 连写解析失败。
3. @{verbatim "@{lemma ... by ...}"} 的证明方法必须真的能证；
   证不动 = 构建失败，与普通 lemma 同罪。
4. @{verbatim "text"} 块里的 @{verbatim "@"}+@{verbatim "{"} 就是
   反引号起点——写邮件地址都危险，用 @{verbatim "@{"} 的 verbatim
   形式自指要小心嵌套。
5. 中文进 LaTeX 需要模板配 xeCJK 一类；ASCII 转义
   （@{verbatim "\<forall>"}）在 .thy 层与排版层都安全。\<close>

thm append_Nil2 map_append

ML \<open>writeln "==== 44 结束 ===="\<close>

end
