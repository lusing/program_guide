// MiniLang v0.2 —— 第 13 章：AST → LLVM IR（表达式 / if / for）
//
// 新增：
//   * 每个 AST 节点长出 codegen() 方法
//   * if 用 phi 合流、for 用 phi 循环（复刻第 4 章 phi.ll 的手写结构）
//   * 内置函数 print(x) 降级为 printf("%f\n", x)
//   * extern 生成 declare；def 生成 define；顶层表达式编成 __anonN 函数，
//     最后合成 main 依次调用
//
// 构建：
//   g++ minilang.cpp -o minilang $(llvm-config --cxxflags --ldflags \
//        --link-shared --libs core support)
// 使用：
//   ./minilang --ir in.mini out.ll && lli out.ll      # 编 IR 并执行
//   ./minilang --ast in.mini                           # 只看 AST（调试前端）

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/raw_ostream.h"

#include <cctype>
#include <cstdio>
#include <fstream>
#include <iostream>
#include <map>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

using namespace llvm;

// ---------------------------------------------------------------- 词法
// （与 v0.1 相同：tok 流 + 载荷）

enum class Tok {
  Eof = -1, Def = -2, Extern = -3, If = -4, Then = -5,
  Else = -6, For = -7, In = -8, Ident = -9, Number = -10,
};

static std::string IdentifierStr;
static double NumVal;

static int getTok(std::istream &In) {
  static int Last = ' ';
  while (isspace(Last))
    Last = In.get();

  if (isalpha(Last) || Last == '_') {
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
  if (isdigit(Last) || Last == '.') {
    std::string NumStr;
    do {
      NumStr += (char)Last;
      Last = In.get();
    } while (isdigit(Last) || Last == '.');
    NumVal = strtod(NumStr.c_str(), nullptr);
    return (int)Tok::Number;
  }
  if (Last == '#') {
    do
      Last = In.get();
    while (Last != EOF && Last != '\n' && Last != '\r');
    if (Last != EOF)
      return getTok(In);
  }
  int This = Last;
  Last = In.get();
  return This;
}

// ---------------------------------------------------------------- 代码生成设施

static std::unique_ptr<LLVMContext> TheContext;
static std::unique_ptr<IRBuilder<>> Builder;
static std::unique_ptr<Module> TheModule;
static std::map<std::string, Value *> NamedValues; // 当前函数内的可见名字
static bool GenError = false;

static Value *logErrorV(const char *Msg) {
  std::cerr << "codegen error: " << Msg << "\n";
  GenError = true;
  return nullptr;
}

// ---------------------------------------------------------------- AST + codegen

struct ExprAST {
  virtual ~ExprAST() = default;
  virtual void dump(std::ostream &O) const = 0;
  virtual Value *codegen() = 0;
};

struct NumberExprAST : ExprAST {
  double Val;
  NumberExprAST(double V) : Val(V) {}
  void dump(std::ostream &O) const override { O << Val; }
  Value *codegen() override {
    return ConstantFP::get(Type::getDoubleTy(*TheContext), Val);
  }
};

struct VariableExprAST : ExprAST {
  std::string Name;
  VariableExprAST(std::string N) : Name(std::move(N)) {}
  void dump(std::ostream &O) const override { O << Name; }
  Value *codegen() override {
    auto It = NamedValues.find(Name);
    if (It == NamedValues.end())
      return logErrorV("unknown variable name");
    return It->second;
  }
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
  Value *codegen() override {
    Value *L = LHS->codegen();
    Value *R = RHS->codegen();
    if (!L || !R)
      return nullptr;
    if (Op == '<') { // 比较结果经 fcmp(i1) 转 double（MiniLang 万物皆 double）
      Value *C = Builder->CreateFCmpOLT(L, R, "cmptmp");
      return Builder->CreateUIToFP(C, Type::getDoubleTy(*TheContext), "booltmp");
    }
    switch (Op) {
    case '+': return Builder->CreateFAdd(L, R, "addtmp");
    case '-': return Builder->CreateFSub(L, R, "subtmp");
    case '*': return Builder->CreateFMul(L, R, "multmp");
    case '/': return Builder->CreateFDiv(L, R, "divtmp");
    default:  return logErrorV("invalid binary operator");
    }
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
  Value *codegen() override {
    // 内置函数：print(x) → printf("%f\n", x)
    // （宿主进程里有 libc 的 printf，lli/JIT 都能解析——第 11 章 ProcessSymbols）
    if (Callee == "print") {
      if (Args.size() != 1)
        return logErrorV("print takes exactly one argument");
      Value *X = Args[0]->codegen();
      if (!X)
        return nullptr;
      auto *Fmt = ConstantDataArray::getString(*TheContext, "%f\n");
      auto *GV = new GlobalVariable(*TheModule, Fmt->getType(), true,
                                    GlobalValue::PrivateLinkage, Fmt, ".fmt.print");
      auto *PtrTy = PointerType::get(*TheContext, 0);
      FunctionType *PFT = FunctionType::get(Type::getInt32Ty(*TheContext), {PtrTy}, true);
      FunctionCallee Printf = TheModule->getOrInsertFunction("printf", PFT);
      Builder->CreateCall(PFT, Printf.getCallee(), {GV, X}, "prtmp");
      return X; // print 的值 = 被打印的值（printf 的 i32 不外泄，万物皆 double）
    }
    Function *CalleeF = TheModule->getFunction(Callee);
    if (!CalleeF)
      return logErrorV("unknown function referenced");
    if (Args.size() != CalleeF->arg_size())
      return logErrorV("incorrect number of arguments");
    std::vector<Value *> ArgV;
    for (auto &A : Args) {
      Value *V = A->codegen();
      if (!V)
        return nullptr;
      ArgV.push_back(V);
    }
    return Builder->CreateCall(CalleeF, ArgV, "calltmp");
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
  Value *codegen() override {
    Value *CondV = Cond->codegen();
    if (!CondV)
      return nullptr;
    // double 当布尔：CondV != 0.0
    CondV = Builder->CreateFCmpONE(
        CondV, ConstantFP::get(Type::getDoubleTy(*TheContext), 0.0), "ifcond");

    Function *F = Builder->GetInsertBlock()->getParent();
    // 三个块创建时就挂进函数（22 里 getBasicBlockList() 是私有 API，
    // 老教程"先造块后 push_back"的写法编不过）
    BasicBlock *ThenBB = BasicBlock::Create(*TheContext, "then", F);
    BasicBlock *ElseBB = BasicBlock::Create(*TheContext, "else", F);
    BasicBlock *MergeBB = BasicBlock::Create(*TheContext, "ifcont", F);

    Builder->CreateCondBr(CondV, ThenBB, ElseBB);

    Builder->SetInsertPoint(ThenBB);
    Value *ThenV = Then->codegen();
    if (!ThenV)
      return nullptr;
    Builder->CreateBr(MergeBB);
    ThenBB = Builder->GetInsertBlock(); // then 体里可能生成了新块，phi 要用"真末块"

    Builder->SetInsertPoint(ElseBB);
    Value *ElseV = Else->codegen();
    if (!ElseV)
      return nullptr;
    Builder->CreateBr(MergeBB);
    ElseBB = Builder->GetInsertBlock();

    Builder->SetInsertPoint(MergeBB);
    PHINode *PN = Builder->CreatePHI(Type::getDoubleTy(*TheContext), 2, "iftmp");
    PN->addIncoming(ThenV, ThenBB);   // 从 then 来 → 取 ThenV
    PN->addIncoming(ElseV, ElseBB);   // 从 else 来 → 取 ElseV（第 4 章的 phi！）
    return PN;
  }
};

// for i = start, end, step in body —— phi 版（守卫在前的 while 形态，同第 4 章 phi.ll）
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
  Value *codegen() override {
    Value *StartV = Start->codegen();
    if (!StartV)
      return nullptr;

    Function *F = Builder->GetInsertBlock()->getParent();
    BasicBlock *PreheaderBB = Builder->GetInsertBlock();
    BasicBlock *LoopBB = BasicBlock::Create(*TheContext, "loop.head", F);
    Builder->CreateBr(LoopBB);
    Builder->SetInsertPoint(LoopBB);

    // 两个 phi：循环变量 i、累积的"最后一圈 body 值"（一圈不进则 0.0）
    PHINode *Var = Builder->CreatePHI(Type::getDoubleTy(*TheContext), 2, VarName);
    Var->addIncoming(StartV, PreheaderBB);
    PHINode *Result = Builder->CreatePHI(Type::getDoubleTy(*TheContext), 2, "for.result");
    Result->addIncoming(ConstantFP::get(Type::getDoubleTy(*TheContext), 0.0),
                        PreheaderBB);

    // 循环体内：i 指向 phi（临时遮蔽外层同名值）
    Value *OldVal = nullptr;
    auto It = NamedValues.find(VarName);
    if (It != NamedValues.end())
      OldVal = It->second;
    NamedValues[VarName] = Var;

    // end 每圈在循环头重估（可以引用 i 之外的变量）
    Value *EndV = End->codegen();
    if (!EndV)
      return nullptr;
    Value *EndCond = Builder->CreateFCmpOLE(Var, EndV, "loopcond"); // i <= end ?
    Function *TheFn = Builder->GetInsertBlock()->getParent();
    BasicBlock *BodyBB = BasicBlock::Create(*TheContext, "loop.body", TheFn);
    BasicBlock *ExitBB = BasicBlock::Create(*TheContext, "loop.exit", TheFn);
    Builder->CreateCondBr(EndCond, BodyBB, ExitBB);

    Builder->SetInsertPoint(BodyBB);
    Value *BodyV = Body->codegen();
    if (!BodyV)
      return nullptr;
    Value *StepV = Step ? Step->codegen()
                        : ConstantFP::get(Type::getDoubleTy(*TheContext), 1.0);
    Value *NextVar = Builder->CreateFAdd(Var, StepV, "nextvar");

    BasicBlock *BodyEndBB = Builder->GetInsertBlock(); // body 可能开了新块
    Builder->CreateBr(LoopBB);
    Var->addIncoming(NextVar, BodyEndBB);   // 下一圈的 i
    Result->addIncoming(BodyV, BodyEndBB);  // 下一圈的"上一次结果"

    // 恢复被遮蔽的外层变量
    if (OldVal)
      NamedValues[VarName] = OldVal;
    else
      NamedValues.erase(VarName);

    Builder->SetInsertPoint(ExitBB);
    return Result; // 整个 for 的值 = 最后一圈 body 值（0 圈则 0.0）
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
  Function *codegen() {
    // MiniLang 万物皆 double：double @name(double, double, ...)
    std::vector<Type *> Doubles(Args.size(), Type::getDoubleTy(*TheContext));
    FunctionType *FT =
        FunctionType::get(Type::getDoubleTy(*TheContext), Doubles, false);
    Function *F = Function::Create(FT, Function::ExternalLinkage, Name, TheModule.get());
    unsigned Idx = 0;
    for (auto &Arg : F->args())
      Arg.setName(Args[Idx++]);
    return F;
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
  Function *codegen() {
    // 重复定义：已有人体 → 报错；只有声明 → 认领并补体
    Function *F = TheModule->getFunction(Proto->Name);
    if (F && !F->isDeclaration()) {
      logErrorV("function cannot be redefined");
      return nullptr;
    }
    if (!F)
      F = Proto->codegen();
    if (!F)
      return nullptr;

    BasicBlock *BB = BasicBlock::Create(*TheContext, "entry", F);
    Builder->SetInsertPoint(BB);

    NamedValues.clear();
    for (auto &Arg : F->args())
      NamedValues[std::string(Arg.getName())] = &Arg;

    if (Value *RetVal = Body->codegen()) {
      Builder->CreateRet(RetVal);
      if (verifyFunction(*F, &errs())) {
        errs() << "function verify failed: " << Proto->Name << "\n";
        F->eraseFromParent();
        GenError = true;
        return nullptr;
      }
      return F;
    }
    F->eraseFromParent(); // 出错回滚：把半成品函数从模块里抹掉
    return nullptr;
  }
};

// ---------------------------------------------------------------- 解析（与 v0.1 相同）

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
  advance();
  auto V = parseExpression();
  if (!V)
    return nullptr;
  if (CurTok != ')')
    return logErrorE("expected ')'");
  advance();
  return V;
}

static std::unique_ptr<ExprAST> parseIdent() {
  std::string IdName = IdentifierStr;
  advance();
  if (CurTok != '(')
    return std::make_unique<VariableExprAST>(IdName);
  advance();
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
  advance();
  return std::make_unique<CallExprAST>(IdName, std::move(Args));
}

static std::unique_ptr<ExprAST> parseIf() {
  advance();
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
  advance();
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

static std::unique_ptr<ExprAST> parseBinOpRHS(int MinPrec,
                                              std::unique_ptr<ExprAST> LHS) {
  while (true) {
    int Prec = getTokPrecedence();
    if (Prec < MinPrec)
      return LHS;
    int BinOp = CurTok;
    advance();
    auto RHS = parsePrimary();
    if (!RHS)
      return nullptr;
    int NextPrec = getTokPrecedence();
    if (Prec < NextPrec) {
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
  advance();
  return std::make_unique<PrototypeAST>(std::move(Name), std::move(ArgNames));
}

static std::unique_ptr<FunctionAST> parseDefinition() {
  advance();
  auto Proto = parsePrototype();
  if (!Proto)
    return nullptr;
  auto Body = parseExpression();
  if (!Body)
    return nullptr;
  return std::make_unique<FunctionAST>(std::move(Proto), std::move(Body));
}

static std::unique_ptr<FunctionAST> parseExtern() {
  advance();
  return std::make_unique<FunctionAST>(parsePrototype(), nullptr);
}

static std::unique_ptr<FunctionAST> parseTopLevel() {
  static int N = 0;
  auto E = parseExpression();
  if (!E)
    return nullptr;
  auto Proto = std::make_unique<PrototypeAST>("__anon" + std::to_string(N++),
                                              std::vector<std::string>());
  return std::make_unique<FunctionAST>(std::move(Proto), std::move(E));
}

// ---------------------------------------------------------------- 驱动

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

static int runAst(const char *Path) {
  std::string Src = slurp(Path);
  std::istringstream In(Src);
  Input = &In;
  advance();
  while (true) {
    switch (CurTok) {
    case (int)Tok::Eof:
      std::cout << "==== ast ok ====\n";
      return 0;
    case ';':
      advance();
      break;
    case (int)Tok::Def: {
      auto F = parseDefinition();
      if (!F) return 1;
      F->dump(std::cout); std::cout << "\n";
      break;
    }
    case (int)Tok::Extern: {
      auto F = parseExtern();
      if (!F) return 1;
      F->Proto->dump(std::cout); std::cout << "\n";
      break;
    }
    default: {
      auto F = parseTopLevel();
      if (!F) return 1;
      F->Body->dump(std::cout); std::cout << "\n";
      break;
    }
    }
  }
}

static int runIr(const char *InPath, const char *OutPath) {
  TheContext = std::make_unique<LLVMContext>();
  Builder = std::make_unique<IRBuilder<>>(*TheContext);
  TheModule = std::make_unique<Module>("minilang", *TheContext);

  std::string Src = slurp(InPath);
  std::istringstream In(Src);
  Input = &In;
  advance();

  std::vector<Function *> AnonFns; // 顶层表达式按序执行
  while (true) {
    switch (CurTok) {
    case (int)Tok::Eof:
      goto Done;
    case ';':
      advance();
      break;
    case (int)Tok::Def: {
      auto F = parseDefinition();
      if (!F) return 1;
      if (!F->codegen()) return 1;
      break;
    }
    case (int)Tok::Extern: {
      auto F = parseExtern();
      if (!F) return 1;
      if (!F->Proto->codegen()) return 1; // 只发 declare
      break;
    }
    default: {
      auto F = parseTopLevel();
      if (!F) return 1;
      if (Function *Fn = F->codegen())
        AnonFns.push_back(Fn);
      else
        return 1;
    }
    }
  }
Done:
  if (GenError)
    return 1;

  // 合成 main：依次调用每个顶层表达式（保证顺序与副作用）
  FunctionType *MainT = FunctionType::get(Type::getInt32Ty(*TheContext), false);
  Function *Main = Function::Create(MainT, Function::ExternalLinkage, "main",
                                    TheModule.get());
  BasicBlock *BB = BasicBlock::Create(*TheContext, "entry", Main);
  Builder->SetInsertPoint(BB);
  for (Function *Fn : AnonFns)
    Builder->CreateCall(Fn);
  Builder->CreateRet(ConstantInt::get(Type::getInt32Ty(*TheContext), 0));

  if (verifyModule(*TheModule, &errs())) {
    errs() << "module verify failed\n";
    return 1;
  }
  std::error_code EC;
  raw_fd_ostream Out(OutPath, EC);
  if (EC) {
    errs() << "cannot write " << OutPath << ": " << EC.message() << "\n";
    return 1;
  }
  TheModule->print(Out, nullptr);
  outs() << "wrote " << OutPath << "\n";
  outs() << "==== 13 ok ====\n";
  return 0;
}

int main(int argc, char **argv) {
  if (argc == 3 && std::string(argv[1]) == "--ast")
    return runAst(argv[2]);
  if (argc == 4 && std::string(argv[1]) == "--ir")
    return runIr(argv[2], argv[3]);
  std::cerr << "usage: minilang --ast <file.mini>\n"
               "       minilang --ir <in.mini> <out.ll>\n";
  return 2;
}







