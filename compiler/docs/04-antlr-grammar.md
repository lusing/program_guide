# 第 4 章　ANTLR 文法工程：把 TIP 文本变成 parse tree

## 4.1 程序文本为什么需要先被"解析"

第 3 章认识的 TIP 程序在磁盘上只是一串字符。静态分析无法直接对字符下结论——
它需要知道“这里是一个加法而不是两个标识符”，“这两条语句在同一个块里”。
把字符流识别为结构化对象的过程叫**解析（parsing）**，而解析的依据是**文法（grammar）**：
一组描述语言合法形状的规则。

本章用 ANTLR4（Another Tool for Language Recognition）为 TIP 写一份完整文法，
让 ANTLR 据此生成 C++ 的词法分析器 `TIPLexer` 与语法分析器 `TIPParser`。
我们的配套程序调用生成的分析器，成功时打印 parse tree，
语法错误时以确定格式输出诊断。文法规则名与 parser 入口从本章起冻结，
后续所有章节都复用这同一份前端。

## 4.2 ANTLR 文法的两类规则

打开 TIP.g4 会看到两种书写形式，这是 ANTLR 的基本分工。

- **语法规则（parser rule）以小写字母开头**，如 `program`、`stmt`、`expr`。
  它描述**记号（token）**之间的结构：一个程序由若干函数组成，一条语句可以是赋值或循环。
- **词法规则（lexer rule）以大写字母开头**，如 `IDENT`、`INT`、`WHILE`。
  它描述字符如何先被切成记号：哪些字符组成标识符，哪些是关键字。

解析分两段进行：`TIPLexer` 先把字符流切成记号流，
`TIPParser` 再按语法规则把记号流组织成 parse tree。
parse tree 的每个内部节点对应一条语法规则，叶子对应记号。

## 4.3 程序结构规则

文法最前面四条规则定义 TIP 的顶层形状。

```antlr
program    : function+ EOF ;
singleExpr : expr EOF ;
function   : IDENT LPAREN params? RPAREN LBRACE varDecls? stmt* RETURN expr SEMI RBRACE ;
params     : IDENT (COMMA IDENT)* ;
varDecls   : VAR IDENT (COMMA IDENT)* SEMI ;
```

几个记号的含义：`+` 表示一次或多次，`*` 零次或多次，`?` 零次或一次，
`EOF` 是文件结束。由此可以逐条读出语义约束：

- 一个程序由**一个或多个**函数组成，且后面必须紧跟文件结束——多余的字符就是语法错误；
- 函数名后是括号括起的可选参数表，然后是花括号函数体；
- 函数体内先有可选的 `var` 声明，然后是**零条或多条**语句，
  **最后必须**是一条 `return`。文法把第 3 章说的"返回必须在末尾"直接固化了；
- `params`、`varDecls` 用 `IDENT (COMMA IDENT)*` 表达"逗号分隔的名字表"，
  既不允许空逗号，也不允许漏逗号。

`singleExpr` 是为单个表达式准备的入口，后续章节做表达式小实验时会用到。

## 4.4 语句：用"标签备选"区分形状

语句规则是本章第一个关键设计：

```antlr
stmt       : lvalue ASSIGN expr SEMI                # assignStmt
           | OUTPUT expr SEMI                      # outputStmt
           | IF LPAREN expr RPAREN stmt (ELSE stmt)? # ifStmt
           | WHILE LPAREN expr RPAREN stmt         # whileStmt
           | LBRACE stmt* RBRACE                   # blockStmt
           ;
```

竖线 `|` 分隔同一条规则的多个**备选（alternative）**。每个备选后面以 `#` 给出一个**标签**，
如 `# assignStmt`。标签不是装饰——它让 ANTLR 在生成代码时为每个备选生成一个**独立的上下文子类**
（`AssignStmtContext`、`IfStmtContext`……）。于是判断"这条语句到底是哪一种"，
不需要在文本上检查记号，只要对上下文指针做一次 `dynamic_cast`。第 8 章构造 AST 时，
全部翻译逻辑都靠这些标签分派。

`lvalue` 规则同样使用标签：

```antlr
lvalue     : IDENT (DOT IDENT)?                    # directLvalue
           | STAR expr (DOT IDENT)?                # pointerLvalue
           ;
```

它精确对应第 3 章的赋值目标范围：直接变量（可带一个字段），
或解引用表达式（也可带字段，即 `(*p).f`）。

## 4.5 表达式：左递归、优先级与备选标签

表达式规则是整份文法最精巧的部分：

```antlr
expr       : expr LPAREN args? RPAREN              # callExpr
           | expr DOT IDENT                        # fieldExpr
           | STAR expr                             # derefExpr
           | AND IDENT                             # addrExpr
           | ALLOC expr                            # allocExpr
           | MINUS expr                            # negExpr
           | expr (STAR|DIV) expr                   # mulExpr
           | expr (PLUS|MINUS) expr                # addExpr
           | expr (GT|EQ) expr                     # cmpExpr
           | INT                                   # intExpr
           | IDENT                                 # varExpr
           | INPUT                                 # inputExpr
           | NULL                                  # nullExpr
           | LPAREN expr RPAREN                    # parenExpr
           | LBRACE field (COMMA field)* RBRACE    # recExpr
           ;
```

这里有三个值得逐一理解的设计决定。

### 4.5.1 ANTLR4 允许直接左递归

`expr` 的多个备选以 `expr ...` 开头，规则在自己的定义里引用自己——这叫**左递归**。
传统的 LL 文法不能处理左递归（会无限展开第一个记号），
ANTLR4 内置了对**直接左递归**的改写支持，所以可以按最自然的方式书写。

### 4.5.2 优先级由备选顺序决定

左递归备选出现在规则中的**先后顺序**就是运算的优先级顺序：
排在前面的结合更紧。调用、字段、一元运算排在最前，
然后是 `* /`、`+ -`，比较 `> ==` 最松。
写 `a + b * c` 时，解析器自动把 `b * c` 组在一起——
文法里没有引入多余的 "term/factor" 分层，优先级全部由顺序承担。
`a * b` 与 `*p` 共用同一个记号 `STAR`，
但一个出现在两个表达式之间（`mulExpr`），一个出现在表达式之前（`derefExpr`），
解析器靠位置区分，因此文法不需要第二个乘法词法记号。

### 4.5.3 每个备选同样有标签

表达式的 14 个备选各自带标签，第 8 章因此有 14 个上下文子类，
翻译时一一对应 AST 的 12 种节点（`parenExpr` 不产生节点、`negExpr` 被翻译成减法）。

## 4.6 词法规则：空白、注释与关键字顺序

文法最后一部分是词法。

```antlr
WS         : [ \t\r\n]+ -> skip ;
BLOCK_CMT  : '/*' .*? '*/' -> skip ;
LINE_CMT   : '//' ~[\r\n]* -> skip ;
```

`-> skip` 告诉 ANTLR：这些记号被识别后不交给语法分析器。
`.*?` 是非贪婪匹配，保证 `/* ... */` 不会跨过中间的结束符吞掉后面的代码。

关键字与操作符规则必须注意**顺序**：

```antlr
INPUT : 'input' ;  ...  IDENT : [a-zA-Z_][a-zA-Z0-9_]* ;
```

ANTLR 按规则书写顺序、在同长度匹配下优先选择靠前的规则。
`INPUT`、`WHILE` 等关键字规则排在 `IDENT` **之前**，
于是字符序列 `while` 被识别为关键字 `WHILE`，而不是标识符；
若把 `IDENT` 提前，所有关键字都会变成普通名字。
两个字符的 `==` 也必须让词法器在看到 `==` 时优先于单个 `=`——
ANTLR 的最长匹配原则自动处理这种前缀关系。

## 4.7 悬空 else 与解析的确定性

`if (E) stmt (ELSE stmt)?` 引出一个经典歧义：嵌套时
`if (a) if (b) ... else ...`，`else` 属于哪个 `if`？
ANTLR 与 C 系语言一致，采用"最近匹配"：`else` 绑定最内层尚未闭合的 `if`。
这是 ANTLR LL(*) 解析策略的确定性行为，不需要额外消歧规则。
本书所有 TIP 程序都只有唯一的解析结果——
确定性是"输出逐字节对账"能成立的前提。

## 4.8 错误监听器：为什么要替换默认行为

ANTLR 默认在遇到语法错误时把信息写到 `stderr`，格式随运行时版本而变，
而且解析会尝试错误恢复、继续报告连锁错误。教程需要完全可控的输出，
因此配套程序做了两件事：

1. 从 lexer 与 parser 上 `removeErrorListeners()`，移除默认监听器；
2. 挂上自定义的 `CollectErrorListener`，把每个错误收集成固定形状的字符串：
   `syntax error line L:C <msg>`。

解析完成后若收集到任何诊断，逐条打印并以退出码 2 结束；
没有诊断才打印 parse tree。退出码 2 专指语法层错误，
与第 10 章语义层的退出码 3 区分，自动化对账可以据此判断失败发生在哪一层。

## 4.9 读懂输出里的 parse tree

以 `ite.tip` 为例，成功输出是一行嵌套文本：

```text
(program (function ite ... return (expr f) ; }) <EOF>)
```

每个括号对对应 parse tree 上一个节点，名字是它所用的语法规则或记号原文。
沿嵌套向内读：`program` 下有一个 `function`，名字记号是 `ite`；
函数体内能看到 `varDecls`、两条 `stmt`，其中第二条 `stmt` 的第一个记号是 `while`，
它的条件是 `(expr (expr n) > (expr 0))`，循环体是花括号里两条赋值。
记号原文（`{`、`;`、`return`）也作为叶子出现——parse tree 保留了全部语法细节。
正因为细节太多、形状随记号摇摆，第 8 章才要在它上面再构造一层精简的 AST。

## 4.10 工程注意点

- **文法是接口，先冻结再写消费者**：规则名、备选标签一旦被 AST 构建器引用就不再改动，
  因此本章文法经过完整解析验证后才进入第 8 章。
- **不要在文法里做语义判断**："变量是否声明""函数参数个数对不对"属于语义层，
  文法只管形状。把语义问题塞进文法会让错误信息和解析结构都变复杂。
- **诊断输出只依赖源码内容**：错误信息里不允许出现文件绝对路径等环境信息，
  这样同一份错误诊断在任何机器上都逐字节一致。

## 4.11 本章代码

### 文法

```antlr
// file: TIP.g4
grammar TIP;

program    : function+ EOF ;
singleExpr : expr EOF ;
function   : IDENT LPAREN params? RPAREN LBRACE varDecls? stmt* RETURN expr SEMI RBRACE ;
params     : IDENT (COMMA IDENT)* ;
varDecls   : VAR IDENT (COMMA IDENT)* SEMI ;

stmt       : lvalue ASSIGN expr SEMI                # assignStmt
           | OUTPUT expr SEMI                      # outputStmt
           | IF LPAREN expr RPAREN stmt (ELSE stmt)? # ifStmt
           | WHILE LPAREN expr RPAREN stmt         # whileStmt
           | LBRACE stmt* RBRACE                   # blockStmt
           ;
lvalue     : IDENT (DOT IDENT)?                    # directLvalue
           | STAR expr (DOT IDENT)?                # pointerLvalue
           ;

expr       : expr LPAREN args? RPAREN              # callExpr
           | expr DOT IDENT                        # fieldExpr
           | STAR expr                             # derefExpr
           | AND IDENT                             # addrExpr
           | ALLOC expr                            # allocExpr
           | MINUS expr                            # negExpr
           | expr (STAR|DIV) expr                   # mulExpr
           | expr (PLUS|MINUS) expr                # addExpr
           | expr (GT|EQ) expr                     # cmpExpr
           | INT                                   # intExpr
           | IDENT                                 # varExpr
           | INPUT                                 # inputExpr
           | NULL                                  # nullExpr
           | LPAREN expr RPAREN                    # parenExpr
           | LBRACE field (COMMA field)* RBRACE    # recExpr
           ;
field      : IDENT COLON expr ;
args       : expr (COMMA expr)* ;

WS         : [ \t\r\n]+ -> skip ;
BLOCK_CMT  : '/*' .*? '*/' -> skip ;
LINE_CMT   : '//' ~[\r\n]* -> skip ;
INPUT      : 'input' ;
OUTPUT     : 'output' ;
IF         : 'if' ;
ELSE       : 'else' ;
WHILE      : 'while' ;
VAR        : 'var' ;
RETURN     : 'return' ;
ALLOC      : 'alloc' ;
NULL       : 'null' ;
IDENT      : [a-zA-Z_][a-zA-Z0-9_]* ;
INT        : [0-9]+ ;
ASSIGN     : '=' ;
EQ         : '==' ;
GT         : '>' ;
PLUS       : '+' ;
MINUS      : '-' ;
STAR       : '*' ;
AND        : '&' ;
DIV        : '/' ;
LPAREN     : '(' ; RPAREN : ')' ;
LBRACE     : '{' ; RBRACE : '}' ;
SEMI       : ';' ; COMMA : ',' ; DOT : '.' ; COLON : ':' ;
```

### 配套程序

```cpp
// file: src/main.cpp
// 第 4 章配套程序：读入 TIP 源文件，用 ANTLR 生成的 Lexer/Parser 解析，
// 成功则打印 parse tree；语法错则收集诊断后以退出码 2 退出。
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

// 取代 ANTLR 默认往 stderr 写错误的监听器：把诊断收进字符串向量，
// 输出格式由我们自己决定，保证跨机器逐字节一致。
class CollectErrorListener : public antlr4::BaseErrorListener {
public:
    std::vector<std::string> messages;

    void syntaxError(antlr4::Recognizer *, antlr4::Token *, size_t line,
                     size_t column, const std::string &msg,
                     std::exception_ptr) override {
        messages.push_back("syntax error line " + std::to_string(line) + ":" +
                           std::to_string(column) + " " + msg);
    }
};

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "usage: tipa --check FILE\n";
        return 1;
    }

    std::ifstream src(argv[2]);
    if (!src) {
        std::cerr << "cannot open " << argv[2] << '\n';
        return 1;
    }

    antlr4::ANTLRInputStream input(src);
    TIPLexer lexer(&input);
    antlr4::CommonTokenStream tokens(&lexer);
    TIPParser parser(&tokens);

    CollectErrorListener errors;
    lexer.removeErrorListeners();
    parser.removeErrorListeners();
    lexer.addErrorListener(&errors);
    parser.addErrorListener(&errors);

    TIPParser::ProgramContext *tree = parser.program();
    if (!errors.messages.empty()) {
        for (const std::string &m : errors.messages) std::cout << m << '\n';
        return 2;
    }

    // toStringTree: 用规则名把 parse tree 打印成嵌套的一行文本。
    std::cout << antlr4::tree::Trees::toStringTree(tree, &parser) << '\n';
    return 0;
}
```

## 4.12 真实输出

### 正常程序

```text
; expected: expected/output.txt
== ite.tip ==
(program (function ite ( (params n) ) { (varDecls var f ;) (stmt (lvalue f) = (expr 1) ;) (stmt while ( (expr (expr n) > (expr 0)) ) (stmt { (stmt (lvalue f) = (expr (expr f) * (expr n)) ;) (stmt (lvalue n) = (expr (expr n) - (expr 1)) ;) })) return (expr f) ; }) <EOF>)
== twice.tip ==
(program (function twice ( (params f , x) ) { return (expr (expr f) ( (args (expr (expr f) ( (args (expr x)) ))) )) ; }) (function inc ( (params y) ) { return (expr (expr y) + (expr 1)) ; }) (function main ( (params z) ) { return (expr (expr twice) ( (args (expr inc) , (expr z)) )) ; }) <EOF>)
```

### 语法错误

```text
; expected: expected/errors/badsyntax.txt
syntax error line 2:13 mismatched input ';' expecting {'input', 'alloc', 'null', IDENT, INT, '-', '*', '&', '(', '{'}
```

## 4.13 小结

本章把 TIP 的语法形状完整写进了一份 ANTLR 文法：顶层结构靠顺序与量词符号表达，
语句和表达式的形状区分靠标签备选，表达式优先级靠左递归备选的排列，
输出的确定性靠自定义错误监听器保证。生成的 parse tree 保留了记号、括号、分号等全部语法细节，
忠实但臃肿。下一章将在它之上构造抽象语法树——
分析算法真正的工作平面。
