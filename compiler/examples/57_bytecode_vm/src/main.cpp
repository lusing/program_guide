// file: src/main.cpp
// 第 57 章驱动（无参运行，简单程序对账协议）：
//   一、反汇编即文档：手编 chunk 的反汇编文本逐行对账；
//   二、栈式求值：-(3+4)*2 与手算对账；
//   三、每指令栈深账：depthTrace 与手推数组逐项对账；
//   四、调用帧：fact(5) 帧深峰值 = 脚本 + 6 层递归 = 7；fib(10) 同型；
//   五、原生函数旁路：input 桩（恒 0）经 Call 调用；
//   六、断言汇总。
#include <iostream>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

#include "chunk.hpp"
#include "vm.hpp"

namespace {

int g_failures = 0;

void check(const std::string &name, const std::string &got, const std::string &want) {
    bool ok = got == want;
    if (!ok) ++g_failures;
    std::cout << (ok ? "ok   " : "FAIL ") << name << " = " << got;
    if (!ok) std::cout << "（期望 " << want << "）";
    std::cout << "\n";
}

std::shared_ptr<tip::ObjFn> makeFn(std::string name, int arity) {
    auto f = std::make_shared<tip::ObjFn>();
    f->name = std::move(name);
    f->arity = arity;
    f->code = std::make_shared<tip::Chunk>();
    return f;
}

// 便捷发码小链
struct Emit {
    tip::Chunk *c;
    Emit &op(tip::Op o, int line) { c->write(o, line); return *this; }
    Emit &byte(uint8_t b, int line) { c->writeByte(b, line); return *this; }
    Emit &u16(uint16_t x, int line) { c->writeU16(x, line); return *this; }
    Emit &konst(const tip::Value &v, int line) {
        c->write(tip::Op::Constant, line);
        c->writeByte(uint8_t(c->addConstant(v)), line);
        return *this;
    }
};

}  // namespace

int main() {
    // ---------- 程序一：-(3+4)*2 ----------
    // 栈账（脚本帧槽 0 = 脚本函数自己，常驻）：
    //   C3 [f,3] C4 [f,3,4] ADD [f,7] NEG [f,-7] C2 [f,-7,2] MUL [f,-14]
    //   PRINT（打印并弹）[f] C0 [f,0] RETURN（弹 0 返回）
    auto expr = makeFn("expr", 0);
    {
        Emit e{expr->code.get()};
        e.konst(tip::Value::num(3), 1);     // 0000
        e.konst(tip::Value::num(4), 1);     // 0002
        e.op(tip::Op::Add, 1);              // 0004
        e.op(tip::Op::Negate, 1);           // 0005
        e.konst(tip::Value::num(2), 1);     // 0006
        e.op(tip::Op::Mul, 1);              // 0008
        e.op(tip::Op::Print, 1);            // 0009
        e.konst(tip::Value::num(0), 1);     // 0010（脚本返回值占位）
        e.op(tip::Op::Return, 1);           // 0012
    }

    std::cout << "== 一、反汇编即文档 ==\n";
    {
        std::ostringstream os;
        tip::disassembleChunk(*expr->code, "expr", os);
        std::cout << os.str();
        std::string want =
            "== expr ==\n"
            "0000   1 CONSTANT 0  ; 3\n"
            "0002    | CONSTANT 1  ; 4\n"
            "0004    | ADD\n"
            "0005    | NEGATE\n"
            "0006    | CONSTANT 2  ; 2\n"
            "0008    | MUL\n"
            "0009    | PRINT\n"
            "0010    | CONSTANT 3  ; 0\n"
            "0012    | RETURN\n";
        check("反汇编逐行", os.str(), want);
    }

    std::cout << "\n== 二、栈式求值 ==\n";
    {
        std::ostringstream os;
        tip::VM vm(os);
        tip::Value r = vm.run(expr);
        check("-(3+4)*2", os.str(), "-14\n");
        check("脚本返回值", std::to_string(r.i), "0");
    }

    std::cout << "\n== 三、每指令栈深账 ==\n";
    {
        std::ostringstream os;
        tip::VM vm(os);
        vm.setTrace(true);
        vm.run(expr);
        // 手推（每条指令执行"后"的栈深；脚本帧槽 0 常驻计 1）：
        std::vector<int> want{2, 3, 2, 2, 3, 2, 1, 2};
        std::vector<int> got = vm.depthTrace();
        std::string gs, ws;
        for (int d : got) gs += std::to_string(d) + " ";
        for (int d : want) ws += std::to_string(d) + " ";
        check("栈深轨迹", gs, ws);
    }

    std::cout << "\n== 四、调用帧 ==\n";
    // fact(n) = n==0 ? 1 : n*fact(n-1)
    // 帧内槽位：base+0 = 被调函数值（clox 占位），实参 n 在 base+1。
    // 布局（偏移以字节计；JumpIfFalse/Jump 的操作数 = 目标地址 - 下一指令地址）：
    //   0000 GetLocal 1        n
    //   0002 Constant 0        0
    //   0004 Eq                n==0
    //   0005 JumpIfFalse ->13  假：走递归支（13-8=5）
    //   0008 Constant 1        1
    //   0010 Jump ->25         汇合到 Return 前（25-13=12）
    //   0013 Constant fact     被调者
    //   0015 GetLocal 1        n
    //   0017 Constant 1        1
    //   0019 Sub               n-1
    //   0020 Call 1            fact(n-1)
    //   0022 GetLocal 1        n
    //   0024 Mul               n*fact(n-1)
    //   0025 Return            栈上恰一个结果
    auto fact = makeFn("fact", 1);
    {
        Emit e{fact->code.get()};
        e.op(tip::Op::GetLocal, 2), e.byte(1, 2);
        e.konst(tip::Value::num(0), 2);
        e.op(tip::Op::Eq, 2);
        e.op(tip::Op::JumpIfFalse, 2), e.u16(5, 2);
        e.konst(tip::Value::num(1), 3);
        e.op(tip::Op::Jump, 3), e.u16(12, 3);
        e.konst(tip::Value::ref(fact), 4);
        e.op(tip::Op::GetLocal, 4), e.byte(1, 4);
        e.konst(tip::Value::num(1), 4);
        e.op(tip::Op::Sub, 4);
        e.op(tip::Op::Call, 4), e.byte(1, 4);
        e.op(tip::Op::GetLocal, 5), e.byte(1, 5);
        e.op(tip::Op::Mul, 5);
        e.op(tip::Op::Return, 6);
    }
    {
        auto script = makeFn("script", 0);
        Emit e{script->code.get()};
        e.konst(tip::Value::ref(fact), 8);
        e.konst(tip::Value::num(5), 8);
        e.op(tip::Op::Call, 8), e.byte(1, 8);
        e.op(tip::Op::Print, 8);
        e.konst(tip::Value::num(0), 8);
        e.op(tip::Op::Return, 8);

        std::ostringstream os;
        tip::VM vm(os);
        tip::Value r = vm.run(script);
        check("fact(5)", os.str(), "120\n");
        check("帧深峰值（脚本 + 6 层递归）", std::to_string(vm.maxFrames()), "7");
        (void)r;
    }
    // fib(n) = n<2 ? n : fib(n-1)+fib(n-2)
    // 布局（Gt 弹栈序：a=先压者。要算 2>n，须先压 2 再压 n）：
    //   0000 Constant 2 / 0002 GetLocal 1 / 0004 Gt（2>n 即 n<2）
    //   0005 JumpIfFalse ->13（偏移 5）/ 0008 GetLocal 1（n）
    //   0010 Jump ->32（偏移 19，越过递归支直达 Return）
    //   0013.. 递归支：fib(n-1)、fib(n-2)、Add
    //   0031 Add / 0032 Return
    auto fib = makeFn("fib", 1);
    {
        Emit e{fib->code.get()};
        e.konst(tip::Value::num(2), 2);              // 0000
        e.op(tip::Op::GetLocal, 2), e.byte(1, 2);    // 0002
        e.op(tip::Op::Gt, 2);                        // 0004
        e.op(tip::Op::JumpIfFalse, 2), e.u16(5, 2);  // 0005 -> 0013
        e.op(tip::Op::GetLocal, 3), e.byte(1, 3);    // 0008（n 即结果）
        e.op(tip::Op::Jump, 3), e.u16(19, 3);        // 0010 -> 0032
        e.konst(tip::Value::ref(fib), 4);            // 0013
        e.op(tip::Op::GetLocal, 4), e.byte(1, 4);    // 0015
        e.konst(tip::Value::num(1), 4);              // 0017
        e.op(tip::Op::Sub, 4);                       // 0019
        e.op(tip::Op::Call, 4), e.byte(1, 4);        // 0020
        e.konst(tip::Value::ref(fib), 5);            // 0022
        e.op(tip::Op::GetLocal, 5), e.byte(1, 5);    // 0024
        e.konst(tip::Value::num(2), 5);              // 0026
        e.op(tip::Op::Sub, 5);                       // 0028
        e.op(tip::Op::Call, 5), e.byte(1, 5);        // 0029
        e.op(tip::Op::Add, 5);                       // 0031
        e.op(tip::Op::Return, 6);                    // 0032
    }
    {
        auto script = makeFn("script", 0);
        Emit e{script->code.get()};
        e.konst(tip::Value::ref(fib), 9);
        e.konst(tip::Value::num(10), 9);
        e.op(tip::Op::Call, 9), e.byte(1, 9);
        e.op(tip::Op::Print, 9);
        e.konst(tip::Value::num(0), 9);
        e.op(tip::Op::Return, 9);

        std::ostringstream os;
        tip::VM vm(os);
        vm.run(script);
        check("fib(10)", os.str(), "55\n");
    }

    std::cout << "\n== 五、原生函数旁路 ==\n";
    {
        auto input = std::make_shared<tip::ObjNative>();
        input->name = "input";
        input->arity = 0;
        input->fn = [](std::vector<tip::Value>) { return tip::Value::num(0); };
        // input() + 40 + 2（桩值 0，结果 42）
        auto script = makeFn("script", 0);
        Emit e{script->code.get()};
        e.konst(tip::Value::ref(input), 10);
        e.op(tip::Op::Call, 10), e.byte(0, 10);
        e.konst(tip::Value::num(40), 10);
        e.op(tip::Op::Add, 10);
        e.konst(tip::Value::num(2), 10);
        e.op(tip::Op::Add, 10);
        e.op(tip::Op::Print, 10);
        e.konst(tip::Value::num(0), 10);
        e.op(tip::Op::Return, 10);

        std::ostringstream os;
        tip::VM vm(os);
        vm.run(script);
        check("input()+40+2", os.str(), "42\n");
    }

    std::cout << "\n== 六、断言汇总 ==\n";
    if (g_failures == 0) {
        std::cout << "全部通过（7 项）\n";
        return 0;
    }
    std::cout << g_failures << " 项失败\n";
    return 1;
}
