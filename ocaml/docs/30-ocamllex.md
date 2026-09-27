# 30 · ocamllex：词法分析器生成器

对应示例：`examples/26_ocamllex/`（`ocamllex_expr.mll` + `main.ml`）

### 30.1 从手写到生成

第 21 章手写了词法器：一个字符一个字符地啃、一个状态一个
状态地维护。`ocamllex` 把正则部分自动化：你写“正则 → 动作”
的规则表，它生成一个快得多的表驱动词法器（本例 22 状态、
473 转移）。

### 30.2 .mll 文件的结构

```ocaml
{ (* header：原样拷进生成的 .ml *) }
let digit = ['0'-'9']        (* 命名正则片段 *)
rule token = parse
  | [' ' '\t' '\r']+      { token lexbuf }            (* 跳过 *)
  | '\n'                  { Lexing.new_line lexbuf; token lexbuf }
  | digit+ '.' digit* (('e'|'E') ('+'|'-')? digit+)? as lx
                          { FLOAT (float_of_string lx) }
  | digit+ as lx          { INT (int_of_string lx) }
  | ['a'-'z' 'A'-'Z'] ['a'-'z' 'A'-'Z' '0'-'9' '_']* as lx
                          { match lx with
                            | "let" -> LET | _ -> ID lx }
  | '+' { PLUS }
  | eof { EOF }
  | _ as c { error lexbuf (Printf.sprintf "unexpected %C" c) }
```

要点：

- `lexbuf` 是隐式参数，动作里调 `token lexbuf` 驱动下一轮；
- **最长匹配胜出**（maximal munch），同长才看声明顺序——
  所以 `3.14` 不会被整数规则截断；
- 换行动作里调 `Lexing.new_line`，`lex_curr_p.pos_lnum` 行号才准；
- `Lexing.from_string` / `from_channel` 造 lexbuf。

### 30.3 构建链与模块名陷阱

```bash
ocamllex ocamllex_expr.mll        # 生成 ocamllex_expr.ml
ocamlc -w -24 ocamllex_expr.ml main.ml -o 26_ocamllex.exe
```

**实测坑**：生成的模块名取自 `.mll` 文件名。本教程示例统一
`NN_名称.ml` 命名，而 `26_ocamllex.mll` 会生成非法模块名
（数字开头，引用它直接语法错）——所以 ocamllex 示例放在
`examples/26_ocamllex/` 子目录，用合法名 `ocamllex_expr.mll`，
`build.ps1` 内置了这条两段式构建链。

### 30.4 站在生成的词法器上写解析器

生成的 `token` 函数配上“一格 lookahead”（缓存 peek），
第 21 章的递归下降文法原样可用。示例 26 实现了带
`let` 绑定、`if-then-else`、四则/取余/幂（右结合）、
一元负号的表达式求值器，词法错误带行列定位：

```
lex error: line 2, col 5: unexpected character '$'
```

### 30.5 何时用 ocamllex

规则多、要行号定位、要性能时值得；几十行的玩具语言手写
词法器（第 21 章式）更直观。解析器生成器方面，社区标准是
menhir（`ocamlyacc` 的现代后继），本教程不展开。

### 30.6 本章小结

- .mll = header + 规则表；最长匹配；`Lexing.new_line` 记行号；
- 模块名来自文件名，避开数字开头；
- ocamllex 之后接手写递归下降是最实用的组合。

---

---
上一章：[29 · OCaml 5 并发：Domain 与 Effect](domains-effects.md) ｜ 下一章：[31 · 带标签的函数参数与可选参数](labeled-args.md) ｜ 返回：[README](../README.md)
