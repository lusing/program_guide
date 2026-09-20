// MiniLang v1.0 —— 第 24 章收官：统一 CLI + putch + 全模式回归
//
// 用法（动词式 CLI，旧旗标仍兼容）：
//   minilang run  <file.mini>     JIT 逐项执行（-O2 优化层）
//   minilang run0 <file.mini>     JIT 不优化（对照）
//   minilang ir   <in> <out.ll>
//   minilang obj  <in> <out.o>
//   minilang ast  <file.mini>
//   minilang stats <file.mini>
// 内置：print(x) → printf("%f\n")；putch(x) → putchar((int)x)（ASCII 图形的钥匙）
//
// 新增：
//   * --obj in.mini out.o：整程序 IR → TargetMachine 直出 COFF 目标文件
//   * 链接交给 clang 驱动：clang out.o -o out.exe（crt/libc/链接器它全包）
//   print 已降级为 printf，所以不需要任何运行时库——exe 自包含
//
// 新增：
//   * --stats in.mini：整文件编成一个 Module，跑自带的 ml-stats pass
//     （逐函数打印 指令数/块数/alloca 数），经 registerPipelineParsingCallback
//     挂进 -passes= 语言——与第 6/7 章的插件机制同款，只是不离开本进程
//
// 新增：
//   * while cond do body —— 值 = 最后一圈 body 值（0 圈为 0.0）
//   * && 与 || 是语言级短路运算符（右操作数可能根本不求值），
//     用控制流 + phi 实现，不能走"普通二元函数"路线
//
// 新增：
//   * --jit   每个模块进 JIT 前先过 buildPerModuleDefaultPipeline(O2)
//   * --jit0  不优化（对照）
//   前端 alloca 满天飞 → mem2reg 还原 phi → 内联/常量折叠全线开工，
//   fib(32) 实测提速一个数量级（见 docs/17-minilang-opt.md 的计时对比）
//
// 新增：
//   * def binary| 5 (lhs rhs) ...   定义二元运算符，可带优先级（缺省 30）
//   * def unary! (x) ...            定义一元运算符
//   * 实现方式纯粹是命名约定：binary| / unary! 就是普通函数，
//     前缀变成运算符语义由解析器/代码生成器协商完成
//
// 新增：
//   * var a = expr, b = expr in body —— 局部变量（栈槽）
//   * x = expr 赋值表达式（右结合），值 = 右侧表达式的值
//   * 函数参数、for 循环变量全部改走 alloca+load/store（前端统一策略，
//     phi 交给 mem2reg 还原——第 17 章实证这个分工）
//
// 新增（在 v0.2 之上）：
//   * --jit 模式：ORC LLJIT 逐项执行
//     - 每个 def/extern/顶层表达式一个独立 Module（增量编译的最小单元）
//     - ResourceTracker 记账：重定义 def 时先撤销旧定义再装新的
//     - 顶层表达式的值自动回显（=> 55）
//   * extern sin(x) 等声明由 ProcessSymbols 解析（第 11 章机制）
//
// 构建：
//   g++ minilang.cpp -o minilang $(llvm-config --cxxflags --ldflags \
//        --link-shared --libs core support orcjit executionengine)
// 使用：
//   ./minilang --jit in.mini          # JIT 逐项执行
//   ./minilang --ir in.mini out.ll    # 同 v0.2
//   ./minilang --ast in.mini

#include "llvm/ExecutionEngine/Orc/LLJIT.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Transforms/Scalar.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/TargetParser/Host.h"
#include "llvm/TargetParser/Triple.h" // 22：lookupTarget/createTargetMachine 收 Triple 对象
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
  Else = -6, For = -7, In = -8, Ident = -9, Number = -10, Var = -11,
  Unary = -12, Binary = -13, While = -14, Do = -15,
  And = 200, Or = 201, // 双字符运算符（超出 ASCII，专用编码）
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
    if (IdentifierStr == "var")    return (int)Tok::Var;
    if (IdentifierStr == "unary")  return (int)Tok::Unary;
    if (IdentifierStr == "binary") return (int)Tok::Binary;
    if (IdentifierStr == "while")  return (int)Tok::While;
    if (IdentifierStr == "do")     return (int)Tok::Do;
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
  // 双字符运算符：&& 与 ||（putback 回退第一个字符）
  if (Last == '&' || Last == '|') {
    int Pair = In.get();
    if (Pair == Last) {
      int Kind = Last;
      Last = ' ';
      return Kind == '&' ? (int)Tok::And : (int)Tok::Or;
    }
    In.putback(Pair);
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
static std::map<std::string, size_t> KnownFnArity; // 已见过的函数元数（参数个数）
// 注意不能存 FunctionType*——类型属于特定 Context，跨 Context 复用会类型错乱
static bool GenError = false;

// 在函数入口块开头插 alloca（先集中后分散：循环里也能安全申请栈槽）
static AllocaInst *CreateEntryBlockAlloca(Function *F, const std::string &Name) {
  BasicBlock &Entry = F->getEntryBlock();
  IRBuilder<> TmpB(&Entry, Entry.begin());
  return TmpB.CreateAlloca(Type::getDoubleTy(*TheContext), nullptr, Name);
}

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
    // v0.4 起局部值统一是栈槽：读 = load
    return Builder->CreateLoad(Type::getDoubleTy(*TheContext), It->second,
                               Name.c_str());
  }
};

struct BinaryExprAST : ExprAST {
  int Op; // ASCII 运算符字符，或 Tok::And/Tok::Or（200/201）
  std::unique_ptr<ExprAST> LHS, RHS;
  BinaryExprAST(int Op, std::unique_ptr<ExprAST> L, std::unique_ptr<ExprAST> R)
      : Op(Op), LHS(std::move(L)), RHS(std::move(R)) {}
  void dump(std::ostream &O) const override {
    if (Op == (int)Tok::And)      O << "(and ";
    else if (Op == (int)Tok::Or)  O << "(or ";
    else                          O << "(binary " << (char)Op << " ";
    LHS->dump(O);
    O << " ";
    RHS->dump(O);
    O << ")";
  }
  Value *codegen() override {
    // 赋值表达式：左侧必须是变量名（栈槽），值 = 右侧的值
    if (Op == '=') {
      auto *LHSE = dynamic_cast<VariableExprAST *>(LHS.get());
      if (!LHSE)
        return logErrorV("destination of '=' must be a variable");
      Value *Val = RHS->codegen();
      if (!Val)
        return nullptr;
      auto It = NamedValues.find(LHSE->Name);
      if (It == NamedValues.end())
        return logErrorV("unknown variable name");
      Builder->CreateStore(Val, It->second);
      return Val;
    }
    // 短路逻辑：L && R = 若 L 为假结果 0（R 不求值），否则取 R 的真值
    if (Op == (int)Tok::And || Op == (int)Tok::Or) {
      Value *L = LHS->codegen();
      if (!L)
        return nullptr;
      Value *LBool = Builder->CreateFCmpONE(
          L, ConstantFP::get(Type::getDoubleTy(*TheContext), 0.0), "lbool");
      Function *F = Builder->GetInsertBlock()->getParent();
      BasicBlock *LShortBB = // 短路块：&& 假短路 / || 真短路
          BasicBlock::Create(*TheContext, Op == (int)Tok::And ? "and.short" : "or.short", F);
      BasicBlock *RHSBB =
          BasicBlock::Create(*TheContext, "rhs", F);
      BasicBlock *MergeBB =
          BasicBlock::Create(*TheContext, "logic.end", F);
      BasicBlock *LBB = Builder->GetInsertBlock();
      if (Op == (int)Tok::And)
        Builder->CreateCondBr(LBool, RHSBB, LShortBB);
      else
        Builder->CreateCondBr(LBool, LShortBB, RHSBB);

      Builder->SetInsertPoint(RHSBB);
      Value *RV = RHS->codegen();
      if (!RV)
        return nullptr;
      Value *RBool = Builder->CreateFCmpONE(
          RV, ConstantFP::get(Type::getDoubleTy(*TheContext), 0.0), "rbool");
      BasicBlock *RBB = Builder->GetInsertBlock();
      Builder->CreateBr(MergeBB);

      Builder->SetInsertPoint(LShortBB);
      Builder->CreateBr(MergeBB);

      Builder->SetInsertPoint(MergeBB);
      PHINode *BoolPN = Builder->CreatePHI(Type::getInt1Ty(*TheContext), 2, "boolphi");
      BoolPN->addIncoming(ConstantInt::get(Type::getInt1Ty(*TheContext),
                                           Op == (int)Tok::And ? 0 : 1),
                          LShortBB);
      BoolPN->addIncoming(RBool, RBB);
      return Builder->CreateUIToFP(BoolPN,
                                   Type::getDoubleTy(*TheContext), "booltmp");
    }
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
    default:
      break;
    }
    // 内置不认识 → 查用户自定义二元运算符（函数名 "binary"+op）
    std::string FnName = std::string("binary") + (char)Op;
    Function *F = TheModule->getFunction(FnName);
    if (!F) {
      auto It = KnownFnArity.find(FnName);
      if (It == KnownFnArity.end())
        return logErrorV("invalid binary operator");
      FunctionType *FT = FunctionType::get(
          Type::getDoubleTy(*TheContext),
          std::vector<Type *>(It->second, Type::getDoubleTy(*TheContext)), false);
      F = Function::Create(FT, Function::ExternalLinkage, FnName,
                           TheModule.get());
    }
    return Builder->CreateCall(F, {L, R}, "binop");
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
    // 内置函数：putch(x) → putchar((int)x)，返回 x（万物皆 double 约定）
    if (Callee == "putch") {
      if (Args.size() != 1)
        return logErrorV("putch takes exactly one argument");
      Value *X = Args[0]->codegen();
      if (!X)
        return nullptr;
      auto *PtrTy2 = PointerType::get(*TheContext, 0);
      (void)PtrTy2;
      FunctionType *PutCT = FunctionType::get(Type::getInt32Ty(*TheContext),
                                              {Type::getInt32Ty(*TheContext)}, false);
      FunctionCallee Putchar = TheModule->getOrInsertFunction("putchar", PutCT);
      Builder->CreateCall(PutCT, Putchar.getCallee(),
                          {Builder->CreateFPToSI(X, Type::getInt32Ty(*TheContext), "ch")},
                          "pc");
      return X;
    }
    Function *CalleeF = TheModule->getFunction(Callee);
    if (!CalleeF) {
      // JIT 模式下每个条目是独立 Module：本模块没有的定义，
      // 按签名表补一个 declare（链接期由 JITDylib/进程符号解析）
      auto It = KnownFnArity.find(Callee);
      if (It == KnownFnArity.end())
        return logErrorV("unknown function referenced");
      // 万物皆 double：按元数在【当前】Context 重建签名
      FunctionType *FT = FunctionType::get(
          Type::getDoubleTy(*TheContext),
          std::vector<Type *>(It->second, Type::getDoubleTy(*TheContext)), false);
      CalleeF = Function::Create(FT, Function::ExternalLinkage, Callee,
                                 TheModule.get());
    }
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

// while cond do body —— 值 = 最后一圈 body 值（0 圈为 0.0）
struct WhileExprAST : ExprAST {
  std::unique_ptr<ExprAST> Cond, Body;
  WhileExprAST(std::unique_ptr<ExprAST> C, std::unique_ptr<ExprAST> B)
      : Cond(std::move(C)), Body(std::move(B)) {}
  void dump(std::ostream &O) const override {
    O << "(while ";
    Cond->dump(O);
    O << " do ";
    Body->dump(O);
    O << ")";
  }
  Value *codegen() override {
    Value *StartV = ConstantFP::get(Type::getDoubleTy(*TheContext), 0.0);
    Function *F = Builder->GetInsertBlock()->getParent();
    BasicBlock *PreheaderBB = Builder->GetInsertBlock();
    BasicBlock *CondBB = BasicBlock::Create(*TheContext, "while.cond", F);
    Builder->CreateBr(CondBB);
    Builder->SetInsertPoint(CondBB);
    // 结果 phi 放循环头（支配出口）：初始 0.0，每圈被 body 值覆盖
    PHINode *PN = Builder->CreatePHI(Type::getDoubleTy(*TheContext), 2, "whileres");
    PN->addIncoming(StartV, PreheaderBB);
    Value *CondV = Cond->codegen();
    if (!CondV)
      return nullptr;
    CondV = Builder->CreateFCmpONE(
        CondV, ConstantFP::get(Type::getDoubleTy(*TheContext), 0.0), "whilecond");
    BasicBlock *BodyBB = BasicBlock::Create(*TheContext, "while.body", F);
    BasicBlock *ExitBB = BasicBlock::Create(*TheContext, "while.exit", F);
    Builder->CreateCondBr(CondV, BodyBB, ExitBB);

    Builder->SetInsertPoint(BodyBB);
    Value *BodyV = Body->codegen();
    if (!BodyV)
      return nullptr;
    BasicBlock *BodyEndBB = Builder->GetInsertBlock();
    Builder->CreateBr(CondBB);

    PN->addIncoming(BodyV, BodyEndBB); // 回边带来新值

    Builder->SetInsertPoint(ExitBB);
    return PN; // 出口时 phi 持有最后一圈的 body 值（或初始 0.0）
  }
};

// var a = expr, b = expr in body —— 一次性引入一组栈槽，作用域到 body 结束
struct VarExprAST : ExprAST {
  std::vector<std::pair<std::string, std::unique_ptr<ExprAST>>> VarNames;
  std::unique_ptr<ExprAST> Body;
  VarExprAST(std::vector<std::pair<std::string, std::unique_ptr<ExprAST>>> V,
             std::unique_ptr<ExprAST> B)
      : VarNames(std::move(V)), Body(std::move(B)) {}
  void dump(std::ostream &O) const override {
    O << "(var ";
    for (auto &[N, E] : VarNames) {
      O << N << " = ";
      E->dump(O);
      O << " ";
    }
    O << "in ";
    Body->dump(O);
    O << ")";
  }
  Value *codegen() override {
    std::vector<Value *> OldBindings; // v0.4：局部槽统一是 Value*（AllocaInst*）
    Function *F = Builder->GetInsertBlock()->getParent();
    for (auto &[ThisName, Init] : VarNames) {
      Value *InitVal = Init->codegen();
      if (!InitVal)
        return nullptr;
      AllocaInst *Alloca = CreateEntryBlockAlloca(F, ThisName);
      Builder->CreateStore(InitVal, Alloca);
      OldBindings.push_back(NamedValues.count(ThisName) ? NamedValues[ThisName] : nullptr);
      NamedValues[ThisName] = Alloca; // 遮蔽外层同名
    }
    Value *BodyVal = Body->codegen();
    if (!BodyVal)
      return nullptr;
    // 出作用域：恢复被遮蔽的外层绑定
    for (size_t I = 0, E = VarNames.size(); I != E; ++I)
      if (OldBindings[I])
        NamedValues[VarNames[I].first] = OldBindings[I];
      else
        NamedValues.erase(VarNames[I].first);
    return BodyVal;
  }
};

// 一元运算符表达式：实现按命名约定映射到函数 "unary"+op
struct UnaryExprAST : ExprAST {
  char Opcode;
  std::unique_ptr<ExprAST> Operand;
  UnaryExprAST(char Op, std::unique_ptr<ExprAST> O)
      : Opcode(Op), Operand(std::move(O)) {}
  void dump(std::ostream &O) const override {
    O << "(unary " << Opcode << " ";
    Operand->dump(O);
    O << ")";
  }
  Value *codegen() override {
    Value *OperandV = Operand->codegen();
    if (!OperandV)
      return nullptr;
    Function *F = TheModule->getFunction(std::string("unary") + Opcode);
    if (!F) {
      auto It = KnownFnArity.find(std::string("unary") + Opcode);
      if (It == KnownFnArity.end())
        return logErrorV("unknown unary operator");
      FunctionType *FT = FunctionType::get(
          Type::getDoubleTy(*TheContext),
          std::vector<Type *>(It->second, Type::getDoubleTy(*TheContext)), false);
      F = Function::Create(FT, Function::ExternalLinkage,
                           std::string("unary") + Opcode, TheModule.get());
    }
    return Builder->CreateCall(F, {OperandV}, "unop");
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
    // v0.4：循环变量走 alloca（和 var/参数统一），phi 的还原交给 mem2reg
    Function *F = Builder->GetInsertBlock()->getParent();
    AllocaInst *Alloca = CreateEntryBlockAlloca(F, VarName);

    Value *StartV = Start->codegen();
    if (!StartV)
      return nullptr;
    Builder->CreateStore(StartV, Alloca);

    Value *OldVal = NamedValues.count(VarName) ? NamedValues[VarName] : nullptr;
    NamedValues[VarName] = Alloca; // 循环体内遮蔽外层同名

    BasicBlock *PreheaderBB = Builder->GetInsertBlock();
    BasicBlock *LoopBB = BasicBlock::Create(*TheContext, "loop.head", F);
    Builder->CreateBr(LoopBB);
    Builder->SetInsertPoint(LoopBB);

    // for 的值（最后一圈 body 值；0 圈为 0.0）仍用 phi 合流——
    // 它不被赋值，手写 phi 依然是最直接的形态
    PHINode *Result = Builder->CreatePHI(Type::getDoubleTy(*TheContext), 2, "for.result");
    Result->addIncoming(ConstantFP::get(Type::getDoubleTy(*TheContext), 0.0),
                        PreheaderBB);

    // end 每圈在循环头重估
    Value *EndV = End->codegen();
    if (!EndV)
      return nullptr;
    Value *CurVar = Builder->CreateLoad(Type::getDoubleTy(*TheContext), Alloca,
                                        VarName.c_str());
    Value *EndCond = Builder->CreateFCmpOLE(CurVar, EndV, "loopcond");
    BasicBlock *BodyBB = BasicBlock::Create(*TheContext, "loop.body", F);
    BasicBlock *ExitBB = BasicBlock::Create(*TheContext, "loop.exit", F);
    Builder->CreateCondBr(EndCond, BodyBB, ExitBB);

    Builder->SetInsertPoint(BodyBB);
    Value *BodyV = Body->codegen();
    if (!BodyV)
      return nullptr;
    Value *StepV = Step ? Step->codegen()
                        : ConstantFP::get(Type::getDoubleTy(*TheContext), 1.0);
    Value *NextVar = Builder->CreateFAdd(
        Builder->CreateLoad(Type::getDoubleTy(*TheContext), Alloca), StepV,
        "nextvar");
    Builder->CreateStore(NextVar, Alloca); // i += step

    BasicBlock *BodyEndBB = Builder->GetInsertBlock();
    Builder->CreateBr(LoopBB);
    Result->addIncoming(BodyV, BodyEndBB);

    if (OldVal)
      NamedValues[VarName] = OldVal;
    else
      NamedValues.erase(VarName);

    Builder->SetInsertPoint(ExitBB);
    return Result;
  }
};

struct PrototypeAST {
  std::string Name;
  std::vector<std::string> Args;
  bool IsUnary = false;
  bool IsBinary = false;
  unsigned BinaryPrecedence = 30; // 用户二元运算符的缺省优先级
  PrototypeAST(std::string N, std::vector<std::string> A)
      : Name(std::move(N)), Args(std::move(A)) {}
  PrototypeAST(std::string N, std::vector<std::string> A, bool IsUnary,
               bool IsBinary, unsigned Prec)
      : Name(std::move(N)), Args(std::move(A)), IsUnary(IsUnary),
        IsBinary(IsBinary), BinaryPrecedence(Prec) {}
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
    KnownFnArity[Name] = Args.size(); // 记账：元数是跨模块调用的接口契约
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

    // v0.4：参数也入栈槽（可被赋值），与前端的统一 alloca 策略一致
    NamedValues.clear();
    for (auto &Arg : F->args()) {
      AllocaInst *Alloca = CreateEntryBlockAlloca(F, std::string(Arg.getName()));
      Builder->CreateStore(&Arg, Alloca);
      NamedValues[std::string(Arg.getName())] = Alloca;
    }

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

// var id = expr (',' id = expr)* 'in' expr
static std::unique_ptr<ExprAST> parsePrimary();

// while cond do body
static std::unique_ptr<ExprAST> parseWhile() {
  advance(); // 吃 'while'
  auto Cond = parseExpression();
  if (!Cond)
    return nullptr;
  if (CurTok != (int)Tok::Do)
    return logErrorE("expected 'do' in 'while'");
  advance();
  auto Body = parseExpression();
  if (!Body)
    return nullptr;
  return std::make_unique<WhileExprAST>(std::move(Cond), std::move(Body));
}

// 一元运算符：出现在"该有 primary"的位置且是运算符字符 → 一元
static std::unique_ptr<ExprAST> parseUnary() {
  if (!isascii(CurTok) || CurTok == '(' || CurTok == ')' || CurTok == ',')
    return parsePrimary(); // 正常的 primary 位置
  int Opc = CurTok;       // 运算符打头：吃掉后递归解析操作数（支持 !!x）
  advance();
  if (auto Operand = parseUnary())
    return std::make_unique<UnaryExprAST>((char)Opc, std::move(Operand));
  return nullptr;
}

static std::unique_ptr<ExprAST> parseVar() {
  advance(); // 吃 'var'
  std::vector<std::pair<std::string, std::unique_ptr<ExprAST>>> VarNames;
  while (true) {
    if (CurTok != (int)Tok::Ident)
      return logErrorE("expected identifier after 'var'");
    std::string Name = IdentifierStr;
    advance();
    if (CurTok != '=')
      return logErrorE("expected '=' after variable name");
    advance();
    auto Init = parseExpression();
    if (!Init)
      return nullptr;
    VarNames.emplace_back(Name, std::move(Init));
    if (CurTok != ',')
      break;
    advance();
  }
  if (CurTok != (int)Tok::In)
    return logErrorE("expected 'in' after 'var' bindings");
  advance();
  auto Body = parseExpression();
  if (!Body)
    return nullptr;
  return std::make_unique<VarExprAST>(std::move(VarNames), std::move(Body));
}

static std::unique_ptr<ExprAST> parsePrimary() {
  switch (CurTok) {
  case (int)Tok::Ident:  return parseIdent();
  case (int)Tok::Number: return parseNumber();
  case '(':              return parseParen();
  case (int)Tok::If:     return parseIf();
  case (int)Tok::For:    return parseFor();
  case (int)Tok::Var:    return parseVar();
  case (int)Tok::While:  return parseWhile();
  default:               return logErrorE("unknown token when expecting expression");
  }
}

static std::map<int, int> BinopPrecedence = {
    {(int)Tok::Or, 5},  // || 最松
    {(int)Tok::And, 10}, // && 比 || 紧（C 家族惯例）
    {'=', 2},           // 赋值：最低优先级（右结合在 parseBinOpRHS 里特判）
    {'<', 15}, {'+', 20}, {'-', 20}, {'*', 40}, {'/', 40},
};

static int getTokPrecedence() {
  if (!isascii(CurTok) && CurTok != (int)Tok::And && CurTok != (int)Tok::Or)
    return -1;
  auto It = BinopPrecedence.find(CurTok); // 注意不能 (char) 强转：200/201 会被符号扩展成负数
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
    // '=' 右结合：a = b = c 解析成 a = (b = c)，右侧直接取完整表达式
    std::unique_ptr<ExprAST> RHS;
    if (BinOp == '=')
      RHS = parseExpression();
    else
      RHS = parseUnary(); // RHS 位置也允许一元运算符打头（如 2 | -3）
    if (!RHS)
      return nullptr;
    int NextPrec = getTokPrecedence();
    if (Prec < NextPrec) {
      RHS = parseBinOpRHS(Prec + 1, std::move(RHS));
      if (!RHS)
        return nullptr;
    }
    LHS = std::make_unique<BinaryExprAST>(BinOp, std::move(LHS), std::move(RHS));
  }
}

// 一元运算符：出现在"该有 primary"的位置且是运算符字符 → 一元
static std::unique_ptr<ExprAST> parseUnary();

static std::unique_ptr<ExprAST> parseExpression() {
  auto LHS = parseUnary();
  if (!LHS)
    return nullptr;
  return parseBinOpRHS(0, std::move(LHS));
}

static std::unique_ptr<PrototypeAST> parsePrototype() {
  std::string FnName;
  unsigned Kind = 0;         // 0 普通标识符；1 一元；2 二元
  unsigned BinaryPrecedence = 30;
  switch (CurTok) {
  default:
    return logErrorP("expected function name in prototype");
  case (int)Tok::Ident:
    FnName = IdentifierStr;
    advance();
    break;
  case (int)Tok::Unary:
    advance();
    if (!isascii(CurTok))
      return logErrorP("expected operator after 'unary'");
    FnName = "unary";
    FnName += (char)CurTok;
    Kind = 1;
    advance();
    break;
  case (int)Tok::Binary:
    advance();
    if (!isascii(CurTok))
      return logErrorP("expected operator after 'binary'");
    FnName = "binary";
    FnName += (char)CurTok;
    Kind = 2;
    advance();
    if (CurTok == (int)Tok::Number) { // 可选：二元运算符优先级
      if (NumVal < 1 || NumVal > 100)
        return logErrorP("invalid precedence: must be 1..100");
      BinaryPrecedence = (unsigned)NumVal;
      advance();
    }
    break;
  }
  if (CurTok != '(')
    return logErrorP("expected '(' in prototype");
  // v0.7 修复：参数表支持逗号分隔（此前只认空格——潜伏到多参 def 才暴露）
  std::vector<std::string> ArgNames;
  while (true) {
    advance();
    if (CurTok == ')')
      break;
    if (CurTok == ',')
      continue;
    if (CurTok != (int)Tok::Ident)
      return logErrorP("expected identifier in argument list");
    ArgNames.push_back(IdentifierStr);
  }
  advance();
  if (Kind == 1 && ArgNames.size() != 1)
    return logErrorP("invalid number of operands for unary operator");
  if (Kind == 2 && ArgNames.size() != 2)
    return logErrorP("invalid number of operands for binary operator");
  return std::make_unique<PrototypeAST>(std::move(FnName), std::move(ArgNames),
                                        Kind == 1, Kind == 2, BinaryPrecedence);
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

// ---- 自定义统计 pass（第 7 章插件的进程内版）----
namespace mlstats {
struct FnStats : PassInfoMixin<FnStats> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    unsigned Blocks = 0, Insts = 0, Allocas = 0, Loads = 0, Stores = 0, Calls = 0;
    for (BasicBlock &BB : F) {
      Blocks++;
      for (Instruction &I : BB) {
        Insts++;
        if (isa<AllocaInst>(&I)) Allocas++;
        else if (isa<LoadInst>(&I)) Loads++;
        else if (isa<StoreInst>(&I)) Stores++;
        else if (isa<CallBase>(&I)) Calls++;
      }
    }
    outs() << "ml-stats: " << F.getName() << " bb=" << Blocks
           << " insts=" << Insts << " alloca=" << Allocas
           << " load=" << Loads << " store=" << Stores << " call=" << Calls << "\n";
    return PreservedAnalyses::all();
  }
  static bool isRequired() { return true; }
};
} // namespace mlstats

// 整文件 → 单 Module（与 --ir 相同的装配），再跑 ml-stats
static std::unique_ptr<Module> buildWholeProgram(const char *InPath, bool &Ok) {
  Ok = true;
  TheContext = std::make_unique<LLVMContext>();
  Builder = std::make_unique<IRBuilder<>>(*TheContext);
  TheModule = std::make_unique<Module>("minilang", *TheContext);
  std::string Src = slurp(InPath);
  std::istringstream In(Src);
  Input = &In;
  advance();
  std::vector<Function *> AnonFns;
  while (true) {
    switch (CurTok) {
    case (int)Tok::Eof:
      goto Done2;
    case ';':
      advance();
      break;
    case (int)Tok::Def: {
      auto F = parseDefinition();
      if (!F) { Ok = false; return nullptr; }
      if (!F->codegen()) { Ok = false; return nullptr; }
      break;
    }
    case (int)Tok::Extern: {
      auto F = parseExtern();
      if (!F) { Ok = false; return nullptr; }
      if (!F->Proto->codegen()) { Ok = false; return nullptr; }
      break;
    }
    default: {
      auto F = parseTopLevel();
      if (!F) { Ok = false; return nullptr; }
      if (Function *Fn = F->codegen())
        AnonFns.push_back(Fn);
      else { Ok = false; return nullptr; }
    }
    }
  }
Done2:
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
    Ok = false;
    return nullptr;
  }
  return std::move(TheModule);
}

static int runObj(const char *InPath, const char *OutPath) {
  bool Ok;
  auto M = buildWholeProgram(InPath, Ok);
  if (!Ok || !M)
    return 1;

  // 本机目标（JIT 章初始化的是"能编"；这里要"能查表建机"）
  InitializeNativeTarget();
  InitializeNativeTargetAsmPrinter();
  InitializeNativeTargetAsmParser();

  auto TargetTriple = sys::getDefaultTargetTriple(); // 22 起要 #include llvm/TargetParser/Host.h
  Triple TheTriple(TargetTriple); // 22：Module/TargetRegistry 都收 Triple 对象
  M->setTargetTriple(TheTriple);
  std::string Error;
  const Target *TheTarget = TargetRegistry::lookupTarget(TheTriple, Error);
  if (!TheTarget) {
    errs() << "target lookup failed: " << Error << "\n";
    return 1;
  }
  TargetOptions Opt;
  // PIC：MinGW 世界的默认约定（与 clang 一致，链接 .exe/.dll 都顺）
  auto *TM = TheTarget->createTargetMachine(TheTriple, "generic", "", Opt,
                                            Reloc::PIC_);
  M->setDataLayout(TM->createDataLayout());

  std::error_code EC;
  raw_fd_ostream Dest(OutPath, EC, sys::fs::OF_None);
  if (EC) {
    errs() << "cannot open " << OutPath << ": " << EC.message() << "\n";
    return 1;
  }
  legacy::PassManager CodeGenPM;
  if (TM->addPassesToEmitFile(CodeGenPM, Dest, nullptr,
                              CodeGenFileType::ObjectFile)) {
    errs() << "target cannot emit object file\n";
    return 1;
  }
  CodeGenPM.run(*M);
  Dest.flush();
  outs() << "wrote " << OutPath << " (triple " << TargetTriple << ")\n";
    return 0;
}

static int runStats(const char *InPath) {
  bool Ok;
  auto M = buildWholeProgram(InPath, Ok);
  if (!Ok || !M)
    return 1;

  // PassBuilder 三件套（与第 17 章优化层同款骨架），经管线解析挂自己的 pass
  LoopAnalysisManager LAM;
  FunctionAnalysisManager FAM;
  CGSCCAnalysisManager CGAM;
  ModuleAnalysisManager MAM;
  PassBuilder PB;
  PB.registerPipelineParsingCallback(
      [](StringRef Name, FunctionPassManager &FPM,
         ArrayRef<PassBuilder::PipelineElement>) {
        if (Name == "ml-stats") {
          FPM.addPass(mlstats::FnStats());
          return true;
        }
        return false;
      });
  PB.registerModuleAnalyses(MAM);
  PB.registerCGSCCAnalyses(CGAM);
  PB.registerFunctionAnalyses(FAM);
  PB.registerLoopAnalyses(LAM);
  PB.crossRegisterProxies(LAM, FAM, CGAM, MAM);

  // 两遍观察：原始形态 → mem2reg 后（前端 alloca 被 SSA 化的铁证）
  ModulePassManager RawMPM;
  if (auto E = PB.parsePassPipeline(RawMPM, "function(ml-stats)")) {
    errs() << "pipeline parse failed\n";
    return 1;
  }
  outs() << "== before mem2reg ==\n";
  RawMPM.run(*M, MAM);

  ModulePassManager MemMPM;
  if (auto E = PB.parsePassPipeline(MemMPM, "function(mem2reg,ml-stats)")) {
    errs() << "pipeline parse failed\n";
    return 1;
  }
  outs() << "== after mem2reg ==\n";
  MemMPM.run(*M, MAM);

  outs() << "==== 19 ok ====\n";
  return 0;
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
      if (F->Proto->IsBinary) // 用户二元运算符：登记优先级（此后解析即按它爬升）
        BinopPrecedence[F->Proto->Name.back()] = (int)F->Proto->BinaryPrecedence;
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
      if (F->Proto->IsBinary) // 用户二元运算符：登记优先级（此后解析即按它爬升）
        BinopPrecedence[F->Proto->Name.back()] = (int)F->Proto->BinaryPrecedence;
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

// ---------------------------------------------------------------- JIT 驱动

using namespace llvm::orc;

// 重定义记账：函数名 → 它所在模块的 ResourceTracker
// ORC 里"撤销一个定义"= remove(tracker)，符号随之消失、下次 lookup 走新定义
static std::map<std::string, ResourceTrackerSP> TrackedDefs;

static void resetCodegen() {
  // 每个顶层条目一个全新 Context+Module：增量编译的最小单元
  TheContext = std::make_unique<LLVMContext>();
  Builder = std::make_unique<IRBuilder<>>(*TheContext);
  TheModule = std::make_unique<Module>("minilang-item", *TheContext);
}

// 模块进 JIT 前的"预加工"：完整 -O2 管线（PassBuilder 组装，同 opt -O2 的中端）
static void optimizeModuleAtO2(ThreadSafeModule &TSM) {
  TSM.withModuleDo([](Module &M) {
    LoopAnalysisManager LAM;
    FunctionAnalysisManager FAM;
    CGSCCAnalysisManager CGAM;
    ModuleAnalysisManager MAM;
    PassBuilder PB;
    PB.registerModuleAnalyses(MAM);
    PB.registerCGSCCAnalyses(CGAM);
    PB.registerFunctionAnalyses(FAM);
    PB.registerLoopAnalyses(LAM);
    PB.crossRegisterProxies(LAM, FAM, CGAM, MAM);
    ModulePassManager MPM =
        PB.buildPerModuleDefaultPipeline(OptimizationLevel::O2);
    MPM.run(M, MAM);
  });
}

static int runJit(const char *InPath, bool Optimize) {
  InitializeNativeTarget();
  InitializeNativeTargetAsmPrinter();
  InitializeNativeTargetAsmParser();

  ExitOnError ExitOnErr;
  auto J = ExitOnErr(LLJITBuilder().create());

  // 挂优化层：每个模块 materialize 前先过一遍 IRTransformLayer
  if (Optimize)
    J->getIRTransformLayer().setTransform(
        [](ThreadSafeModule TSM, MaterializationResponsibility &) {
          optimizeModuleAtO2(TSM);
          return TSM;
        });

  std::string Src = slurp(InPath);
  std::istringstream In(Src);
  Input = &In;
  advance();

  while (true) {
    switch (CurTok) {
    case (int)Tok::Eof: {
      outs() << "==== 18 ok ====\n";
      outs().flush();
      // 关键：ResourceTrackerSP 不能比 ExecutionSession 活得久——
      // 全局 map 里的 SP 若不清掉，静态析构时 use-after-free（实测崩溃）
      TrackedDefs.clear();
      return 0;
    }
    case ';':
      advance();
      break;
    case (int)Tok::Extern: {
      auto F = parseExtern();
      if (!F) return 1;
      resetCodegen();
      if (!F->Proto->codegen()) return 1;
      ExitOnErr(J->addIRModule(ThreadSafeModule(std::move(TheModule),
                                                std::move(TheContext))));
      break;
    }
    case (int)Tok::Def: {
      auto F = parseDefinition();
      if (!F) return 1;
      if (F->Proto->IsBinary) // 用户二元运算符：登记优先级（此后解析即按它爬升）
        BinopPrecedence[F->Proto->Name.back()] = (int)F->Proto->BinaryPrecedence;
      // 重定义：先撤销旧定义（remove 后旧符号即刻失效）
      if (auto It = TrackedDefs.find(F->Proto->Name); It != TrackedDefs.end()) {
        ExitOnErr(It->second->remove());
        TrackedDefs.erase(It);
      }
      resetCodegen();
      if (!F->codegen()) return 1;
      auto RT = J->getMainJITDylib().createResourceTracker();
      ExitOnErr(J->addIRModule(RT, ThreadSafeModule(std::move(TheModule),
                                                    std::move(TheContext))));
      TrackedDefs[F->Proto->Name] = RT;
      break;
    }
    default: { // 顶层表达式：编好即查即调
      auto F = parseTopLevel();
      if (!F) return 1;
      resetCodegen();
      Function *Fn = F->codegen();
      if (!Fn) return 1;
      auto RT = J->getMainJITDylib().createResourceTracker();
      ExitOnErr(J->addIRModule(RT, ThreadSafeModule(std::move(TheModule),
                                                    std::move(TheContext))));
      auto Addr = ExitOnErr(J->lookup(Fn->getName()));
      double (*FP)() = Addr.toPtr<double (*)()>();
      outs() << "=> " << FP() << "\n"; // REPL 风格回显
      ExitOnErr(RT->remove());         // 用完即撤：不留垃圾符号
      break;
    }
    }
  }
}

int main(int argc, char **argv) {
  // 动词式 CLI；旧旗标（--jit 等）作为别名同样接受
  auto Mode = argc >= 2 ? std::string(argv[1]) : "";
  if ((Mode == "ast" || Mode == "--ast") && argc == 3)
    return runAst(argv[2]);
  if ((Mode == "obj" || Mode == "--obj") && argc == 4)
    return runObj(argv[2], argv[3]);
  if ((Mode == "stats" || Mode == "--stats") && argc == 3)
    return runStats(argv[2]);
  if ((Mode == "run" || Mode == "--jit") && argc == 3)
    return runJit(argv[2], /*Optimize=*/true);
  if ((Mode == "run0" || Mode == "--jit0") && argc == 3)
    return runJit(argv[2], /*Optimize=*/false);
  if ((Mode == "ir" || Mode == "--ir") && argc == 4)
    return runIr(argv[2], argv[3]);
  std::cerr << "usage: minilang run|run0|ast|stats <file.mini>\n"
               "       minilang ir <in.mini> <out.ll>\n"
               "       minilang obj <in.mini> <out.o>\n"
               "       （--jit/--jit0/--ir/--obj/--ast/--stats 旧旗标同样接受）\n";
  return 2;
}


































