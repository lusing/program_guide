// MiniLang v0.1 —— 第 12 章：前端（词法 + 递归下降解析 + AST 打印）
//
// 语法（本章）：
//   top    ::= def proto body | extern proto | 表达式
//   proto  ::= id '(' id* ')'
//   expr   ::= 二元表达式（优先级爬升，表驱动）
//   primary ::= 数字 | id | id '(' args ')' | '(' expr ')' | if | for
//   if     ::= 'if' expr 'then' expr 'else' expr
//   for    ::= 'for' id '=' expr ',' expr (',' expr)? 'in' expr
//   '#' 引到行尾是注释
//
// 构建（本章无需 LLVM）：g++ minilang.cpp -o minilang
// 使用：./minilang --ast test.mini

#include <cctype>
#include <cstdio>
#include <fstream>
#include <cstdlib>
#include <iostream>
#include <map>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

// ---------------------------------------------------------------- 词法

enum class Tok {
  Eof = -1,
  Def = -2,
  Extern = -3,
  If = -4,
  Then = -5,
  Else = -6,
  For = -7,
  In = -8,
  Ident = -9,
  Number = -10,
};

static std::string IdentifierStr; // Ident 的载荷
static double NumVal;             // Number 的载荷

static int getTok(std::istream &In) {
  static int Last = ' ';
  // 跳过空白
  while (isspace(Last))
    Last = In.get();

  if (isalpha(Last) || Last == '_') { // 标识符 / 关键字（允许下划线！）
    IdentifierStr = (char)Last;
    while (isalnum((Last = In.get())) || Last == '_')
      IdentifierStr += (char)Last;
    if (IdentifierStr == "def")    return (int)Tok::Def;
    if (IdentifierStr == "extern") return (int)Tok::Extern;
    if (IdentifierStr == "if")     return (int)Tok::If;
    if (IdentifierStr == "then")   return (int)Tok::Then;
    if (IdentifierStr == "else")   return (int)Tok::Else;
    if (IdentifierStr == "for")    return (int)Tok::For;
    if (IdentifierStr == "in")     return (int)Tok::In;
    return (int)Tok::Ident;
  }
  if (isdigit(Last) || Last == '.') { // 数字（不支持科学计数法，够用）
    std::string NumStr;
    do {
      NumStr += (char)Last;
      Last = In.get();
    } while (isdigit(Last) || Last == '.');
    NumVal = strtod(NumStr.c_str(), nullptr);
    return (int)Tok::Number;
  }
  if (Last == '#') { // 注释到行尾
    do
      Last = In.get();
    while (Last != EOF && Last != '\n' && Last != '\r');
    if (Last != EOF)
      return getTok(In);
  }
  int This = Last;
  Last = In.get(); // 其余：单字符 token，原样返回 ASCII
  return This;
}

// ---------------------------------------------------------------- AST
// 经典 OOP 风格：一个表达式类型一个类。第 9 章的 IR 对象模型同款思路。

struct ExprAST {
  virtual ~ExprAST() = default;
  virtual void dump(std::ostream &O) const = 0; // S-表达式形式打印
};

struct NumberExprAST : ExprAST {
  double Val;
  NumberExprAST(double V) : Val(V) {}
  void dump(std::ostream &O) const override { O << Val; }
};

struct VariableExprAST : ExprAST {
  std::string Name;
  VariableExprAST(std::string N) : Name(std::move(N)) {}
  void dump(std::ostream &O) const override { O << Name; }
};

struct BinaryExprAST : ExprAST {
  char Op;
  std::unique_ptr<ExprAST> LHS, RHS;
  BinaryExprAST(char Op, std::unique_ptr<ExprAST> L, std::unique_ptr<ExprAST> R)
      : Op(Op), LHS(std::move(L)), RHS(std::move(R)) {}
  void dump(std::ostream &O) const override {
    O << "(binary " << Op << " ";
    LHS->dump(O);
    O << " ";
    RHS->dump(O);
    O << ")";
  }
};

struct CallExprAST : ExprAST {
  std::string Callee;
  std::vector<std::unique_ptr<ExprAST>> Args;
  CallExprAST(std::string C, std::vector<std::unique_ptr<ExprAST>> A)
      : Callee(std::move(C)), Args(std::move(A)) {}
  void dump(std::ostream &O) const override {
    O << "(call " << Callee;
    for (auto &A : Args) {
      O << " ";
      A->dump(O);
    }
    O << ")";
  }
};

struct IfExprAST : ExprAST {
  std::unique_ptr<ExprAST> Cond, Then, Else;
  IfExprAST(std::unique_ptr<ExprAST> C, std::unique_ptr<ExprAST> T,
            std::unique_ptr<ExprAST> E)
      : Cond(std::move(C)), Then(std::move(T)), Else(std::move(E)) {}
  void dump(std::ostream &O) const override {
    O << "(if ";
    Cond->dump(O);
    O << " ";
    Then->dump(O);
    O << " ";
    Else->dump(O);
    O << ")";
  }
};

// for i = start, end, step in body    —— step 可省（默认 1）
// 语义：i 从 start 依次加 step，直到 i > end（step>0 时）为止，每圈算一次 body；
// 整个 for 表达式的值 = 最后一圈的 body 值（一圈不进则为 0）
struct ForExprAST : ExprAST {
  std::string VarName;
  std::unique_ptr<ExprAST> Start, End, Step, Body;
  ForExprAST(std::string N, std::unique_ptr<ExprAST> S, std::unique_ptr<ExprAST> E,
             std::unique_ptr<ExprAST> St, std::unique_ptr<ExprAST> B)
      : VarName(std::move(N)), Start(std::move(S)), End(std::move(E)),
        Step(std::move(St)), Body(std::move(B)) {}
  void dump(std::ostream &O) const override {
    O << "(for " << VarName << " = ";
    Start->dump(O);
    O << ", ";
    End->dump(O);
    if (Step) {
      O << ", ";
      Step->dump(O);
    }
    O << " in ";
    Body->dump(O);
    O << ")";
  }
};

struct PrototypeAST {
  std::string Name;
  std::vector<std::string> Args;
  PrototypeAST(std::string N, std::vector<std::string> A)
      : Name(std::move(N)), Args(std::move(A)) {}
  void dump(std::ostream &O) const {
    O << "(" << Name;
    for (auto &A : Args)
      O << " " << A;
    O << ")";
  }
};

struct FunctionAST {
  std::unique_ptr<PrototypeAST> Proto;
  std::unique_ptr<ExprAST> Body;
  FunctionAST(std::unique_ptr<PrototypeAST> P, std::unique_ptr<ExprAST> B)
      : Proto(std::move(P)), Body(std::move(B)) {}
  void dump(std::ostream &O) const {
    O << "(def ";
    Proto->dump(O);
    O << " ";
    Body->dump(O);
    O << ")";
  }
};

// ---------------------------------------------------------------- 解析（递归下降）

static int CurTok;
static std::istream *Input;
static int advance() { return CurTok = getTok(*Input); }

static std::unique_ptr<ExprAST> parseExpression();

static std::unique_ptr<ExprAST> logErrorE(const char *Msg) {
  std::cerr << "parse error: " << Msg << " (tok=" << CurTok << ")\n";
  return nullptr;
}
static std::unique_ptr<PrototypeAST> logErrorP(const char *Msg) {
  std::cerr << "parse error: " << Msg << "\n";
  return nullptr;
}

static std::unique_ptr<ExprAST> parseNumber() {
  auto R = std::make_unique<NumberExprAST>(NumVal);
  advance();
  return R;
}

static std::unique_ptr<ExprAST> parseParen() {
  advance(); // 吃掉 '('
  auto V = parseExpression();
  if (!V)
    return nullptr;
  if (CurTok != ')')
    return logErrorE("expected ')'");
  advance(); // 吃掉 ')'
  return V;
}

static std::unique_ptr<ExprAST> parseIdent() {
  std::string IdName = IdentifierStr;
  advance();
  if (CurTok != '(') // 纯变量
    return std::make_unique<VariableExprAST>(IdName);
  advance(); // 吃掉 '('
  std::vector<std::unique_ptr<ExprAST>> Args;
  while (CurTok != ')') {
    if (auto Arg = parseExpression())
      Args.push_back(std::move(Arg));
    else
      return nullptr;
    if (CurTok == ')')
      break;
    if (CurTok != ',')
      return logErrorE("expected ',' or ')' in argument list");
    advance();
  }
  advance(); // 吃掉 ')'
  return std::make_unique<CallExprAST>(IdName, std::move(Args));
}

static std::unique_ptr<ExprAST> parseIf() {
  advance(); // 吃掉 'if'
  auto Cond = parseExpression();
  if (!Cond)
    return nullptr;
  if (CurTok != (int)Tok::Then)
    return logErrorE("expected 'then'");
  advance();
  auto Then = parseExpression();
  if (!Then)
    return nullptr;
  if (CurTok != (int)Tok::Else)
    return logErrorE("expected 'else'");
  advance();
  auto Else = parseExpression();
  if (!Else)
    return nullptr;
  return std::make_unique<IfExprAST>(std::move(Cond), std::move(Then),
                                     std::move(Else));
}

static std::unique_ptr<ExprAST> parseFor() {
  advance(); // 吃掉 'for'
  if (CurTok != (int)Tok::Ident)
    return logErrorE("expected identifier after 'for'");
  std::string VarName = IdentifierStr;
  advance();
  if (CurTok != '=')
    return logErrorE("expected '=' in 'for'");
  advance();
  auto Start = parseExpression();
  if (!Start)
    return nullptr;
  if (CurTok != ',')
    return logErrorE("expected ',' in 'for'");
  advance();
  auto End = parseExpression();
  if (!End)
    return nullptr;
  std::unique_ptr<ExprAST> Step;
  if (CurTok == ',') {
    advance();
    Step = parseExpression();
    if (!Step)
      return nullptr;
  }
  if (CurTok != (int)Tok::In)
    return logErrorE("expected 'in' in 'for'");
  advance();
  auto Body = parseExpression();
  if (!Body)
    return nullptr;
  return std::make_unique<ForExprAST>(VarName, std::move(Start), std::move(End),
                                      std::move(Step), std::move(Body));
}

static std::unique_ptr<ExprAST> parsePrimary() {
  switch (CurTok) {
  case (int)Tok::Ident:  return parseIdent();
  case (int)Tok::Number: return parseNumber();
  case '(':              return parseParen();
  case (int)Tok::If:     return parseIf();
  case (int)Tok::For:    return parseFor();
  default:               return logErrorE("unknown token when expecting expression");
  }
}

// 二元运算符优先级表（1 越大越紧）。第 16 章它会变成可扩展的
static std::map<char, int> BinopPrecedence = {
    {'<', 10}, {'+', 20}, {'-', 20}, {'*', 40}, {'/', 40},
};

static int getTokPrecedence() {
  if (!isascii(CurTok))
    return -1;
  auto It = BinopPrecedence.find((char)CurTok);
  if (It == BinopPrecedence.end())
    return -1;
  return It->second;
}

// 优先级爬升：parseExpression = primary (binop primary)*
static std::unique_ptr<ExprAST> parseBinOpRHS(int MinPrec,
                                              std::unique_ptr<ExprAST> LHS) {
  while (true) {
    int Prec = getTokPrecedence();
    if (Prec < MinPrec)
      return LHS;
    int BinOp = CurTok;
    advance(); // 吃掉运算符
    auto RHS = parsePrimary();
    if (!RHS)
      return nullptr;
    int NextPrec = getTokPrecedence();
    if (Prec < NextPrec) { // 右边还有更紧的运算符：先结合右边
      RHS = parseBinOpRHS(Prec + 1, std::move(RHS));
      if (!RHS)
        return nullptr;
    }
    LHS = std::make_unique<BinaryExprAST>((char)BinOp, std::move(LHS), std::move(RHS));
  }
}

static std::unique_ptr<ExprAST> parseExpression() {
  auto LHS = parsePrimary();
  if (!LHS)
    return nullptr;
  return parseBinOpRHS(0, std::move(LHS));
}

static std::unique_ptr<PrototypeAST> parsePrototype() {
  if (CurTok != (int)Tok::Ident)
    return logErrorP("expected function name in prototype");
  std::string Name = IdentifierStr;
  advance();
  if (CurTok != '(')
    return logErrorP("expected '(' in prototype");
  std::vector<std::string> ArgNames;
  while (advance() == (int)Tok::Ident)
    ArgNames.push_back(IdentifierStr);
  if (CurTok != ')')
    return logErrorP("expected ')' in prototype");
  advance(); // 吃掉 ')'
  return std::make_unique<PrototypeAST>(std::move(Name), std::move(ArgNames));
}

static std::unique_ptr<FunctionAST> parseDefinition() {
  advance(); // 吃掉 'def'
  auto Proto = parsePrototype();
  if (!Proto)
    return nullptr;
  auto Body = parseExpression();
  if (!Body)
    return nullptr;
  return std::make_unique<FunctionAST>(std::move(Proto), std::move(Body));
}

static std::unique_ptr<FunctionAST> parseExtern() {
  advance(); // 吃掉 'extern'
  return std::make_unique<FunctionAST>(parsePrototype(), nullptr);
}

static std::unique_ptr<FunctionAST> parseTopLevel() {
  // 顶层裸表达式 = 匿名函数 "__anon_N"
  static int N = 0;
  auto E = parseExpression();
  if (!E)
    return nullptr;
  auto Proto = std::make_unique<PrototypeAST>("__anon" + std::to_string(N++),
                                              std::vector<std::string>());
  return std::make_unique<FunctionAST>(std::move(Proto), std::move(E));
}

// ---------------------------------------------------------------- 驱动

// 读文件全部内容
static std::string slurp(const char *Path) {
  std::ifstream F(Path);
  if (!F) {
    std::cerr << "cannot open " << Path << "\n";
    exit(2);
  }
  std::ostringstream SS;
  SS << F.rdbuf();
  return SS.str();
}

int main(int argc, char **argv) {
  if (argc < 3 || std::string(argv[1]) != "--ast") {
    std::cerr << "usage: minilang --ast <file.mini>\n";
    return 2;
  }
  std::string Src = slurp(argv[2]);
  std::istringstream In(Src);
  Input = &In;
  advance(); // 预读第一个 token

  while (true) {
    switch (CurTok) {
    case (int)Tok::Eof:
      std::cout << "==== 12 ok ====\n";
      return 0;
    case ';': // 顶层分号，跳过
      advance();
      break;
    case (int)Tok::Def: {
      auto F = parseDefinition();
      if (!F)
        return 1;
      F->dump(std::cout);
      std::cout << "\n";
      break;
    }
    case (int)Tok::Extern: {
      auto F = parseExtern();
      if (!F)
        return 1;
      F->Proto->dump(std::cout);
      std::cout << "\n";
      break;
    }
    default: {
      auto F = parseTopLevel();
      if (!F)
        return 1;
      F->Body->dump(std::cout);
      std::cout << "\n";
      break;
    }
    }
  }
}
