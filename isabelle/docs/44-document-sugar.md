# 44 · 文档生成与 LaTeX sugar

对应示例：`../examples/T44_document_sugar.thy`

## 44.1 一句话概括

sugar 手册讲"把理论排版成论文"的通道：`section`/`text` 是文档
命令，`@{thm ...}` 一族**文档反引号**在理论处理期就被检查与展开
（拼错名字构建失败——本章实测对象），排版期再变成 LaTeX。
本教程不开 LaTeX 输出（验证走标记区间），但反引号的**检查**
一直在工作。

## 44.2 五件套（全部过构建检查）

```isabelle
text ‹定理：@{thm append_Nil2}
  display 风格：@{thm [display] map_append}
  项：@{term "map f (xs @ ys)"}
  类型：@{typ "'a list ⇒ 'a list"}
  常量名：@{const map}
  现场小定理：@{lemma "length (map f xs) = length xs" by simp}›
```

## 44.3 markup

`@{bold ‹…›}`、`@{italic ‹…›}`、markdown 风格列表与嵌套、
两个空格结尾换行。标题层级 `section/subsection/subsubsection`；
编号与目录由 LaTeX 侧模板决定，理论侧只给结构。

## 44.4 thm 反引号参数

`[display]`（独占行）、`[margin = 50]`（换行宽度）、
`[no_vars]`（自由变量打成 ?x 形式）。参数影响生成的 LaTeX，
不影响构建检查。

## 44.5 会话文档构建（文档节）

ROOT 加 `document [pdf]` + `document_files`；
`isabelle build -D . -o document=pdf`——需要本机 LaTeX
（教程验证链不含，故不实际产 PDF）。中间产物在会话目录的
`document/` 下，可以只取 .tex 不编译。

## 44.6 坑位清单（实测）

1. **拼错名字构建必死**：`@{thm append_Nil99}` 报 Undefined fact
   ——文档反引号是编译期检查，别当纯文本。
2. `@{thm [display] ...}` 参数表后要有空格再接名；连写解析失败。
3. `@{lemma ... by ...}` 的方法必须真能证，与普通 lemma 同罪。
4. `text` 块里 `@{` 就是反引号起点——写 `@` 相关内容要小心，
   反引号字符串里**放不了 `\<open>` 类转义**（第 41 章同款）。
5. 中文进 LaTeX 需模板配 xeCJK；ASCII 转义在 .thy 层安全。

## 44.7 与其他章的接口

- 第 1 章验证方式：本章是"理论即文档"哲学的完成态。
- 第 41 章反引号：ML 侧与文档侧同源不同物。
- 第 43 章系统工具：文档构建的命令行入口。
