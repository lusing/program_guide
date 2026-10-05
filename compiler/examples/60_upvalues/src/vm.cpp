// file: src/vm.cpp
#include "vm.hpp"

#include <algorithm>
#include <iostream>

#include <stdexcept>

namespace tip {

static constexpr int kStackMax = 256;   // 值栈上限（匠书 STACK_MAX）
static constexpr int kFramesMax = 64;   // 帧上限（栈溢出保护，§24.1）

void VM::push(Value v) {
    if (int(stack_.size()) >= kStackMax) throw VmError{"值栈溢出"};
    stack_.push_back(std::move(v));
    if (int(stack_.size()) > maxStack_) maxStack_ = int(stack_.size());
}

Value VM::pop() {
    if (stack_.empty()) throw VmError{"值栈下溢（指令序列有错）"};
    Value v = std::move(stack_.back());
    stack_.pop_back();
    return v;
}

Value &VM::peek(int down) {
    if (down >= int(stack_.size())) throw VmError{"值栈下溢（peek）"};
    return stack_[stack_.size() - 1 - size_t(down)];
}

uint8_t VM::readByte() {
    Frame &f = frames_.back();
    if (f.ip >= f.fn->code->code.size()) throw VmError{"指令指针越界"};
    return f.fn->code->code[f.ip++];
}

uint16_t VM::readU16() {
    uint16_t hi = readByte();
    uint16_t lo = readByte();
    return uint16_t(hi << 8 | lo);
}

Value VM::run(const std::shared_ptr<ObjFn> &fn) {
    stack_.clear();
    frames_.clear();
    maxFrames_ = maxStack_ = 0;
    depthTrace_.clear();
    openUpvalues_.clear();
    boxesCreated_ = 0;

    // 脚本帧：函数包一层无捕获闭包——帧协议对脚本与函数统一（57 章）
    auto shell = std::make_shared<ObjClosure>();
    shell->fn = fn;
    push(Value::ref(shell));
    frames_.push_back(Frame{fn.get(), shell.get(), 0, 0});
    maxFrames_ = 1;

    for (;;) {
        Frame &f = frames_.back();
        if (f.ip >= f.fn->code->code.size()) throw VmError{"代码耗尽未遇 RETURN"};
        Op op = static_cast<Op>(f.fn->code->code[f.ip++]);
        switch (op) {
            case Op::Constant: {
                uint8_t k = readByte();
                push(f.fn->code->consts[k]);
                break;
            }
            case Op::Add: case Op::Sub: case Op::Mul:
            case Op::Div: case Op::Gt: case Op::Eq: {
                Value b = pop(), a = pop();
                if (a.isObj() || b.isObj()) throw VmError{"算术遇非整数"};
                long long r = 0;
                switch (op) {
                    case Op::Add: r = a.i + b.i; break;
                    case Op::Sub: r = a.i - b.i; break;
                    case Op::Mul: r = a.i * b.i; break;
                    case Op::Div:
                        if (b.i == 0) throw VmError{"除零"};
                        r = a.i / b.i; break;
                    case Op::Gt: r = a.i > b.i ? 1 : 0; break;
                    default: r = a.i == b.i ? 1 : 0; break;
                }
                push(Value::num(r));
                break;
            }
            case Op::Negate: {
                Value a = pop();
                if (a.isObj()) throw VmError{"负号遇非整数"};
                push(Value::num(-a.i));
                break;
            }
            case Op::Print: {
                Value a = pop();
                *out_ << (a.isObj() ? showValue(a) : std::to_string(a.i)) << "\n";
                break;
            }
            case Op::Pop:
                pop();
                break;
            case Op::GetLocal: {
                uint8_t slot = readByte();
                push(stack_[frames_.back().base + slot]);
                break;
            }
            case Op::SetLocal: {
                uint8_t slot = readByte();
                stack_[frames_.back().base + slot] = peek(0);  // 不弹：赋值表达式有值
                break;
            }
            case Op::JumpIfFalse: {
                uint16_t off = readU16();
                Value c = pop();  // 条件被消费
                if (!c.isObj() && c.i == 0) frames_.back().ip += off;
                break;
            }
            case Op::Jump:
                frames_.back().ip += readU16();
                break;
            case Op::Loop:
                frames_.back().ip -= readU16();
                break;
            case Op::Call: {
                uint8_t argc = readByte();
                Value callee = peek(argc);  // 被调者在实参之下
                if (!callee.isObj()) throw VmError{"被调者不是函数"};
                if (auto *native = dynamic_cast<ObjNative *>(callee.obj.get())) {
                    // 原生旁路：C++ 直调，不建帧（§24.4）。
                    // 实参按入栈序取（左实参在前），随后连被调者一起让位给返回值。
                    if (int(argc) != native->arity)
                        throw VmError{"native 元数不符"};
                    std::vector<Value> args(stack_.end() - argc, stack_.end());
                    stack_.resize(stack_.size() - size_t(argc) - 1);
                    push(native->fn(std::move(args)));
                    break;
                }
                ObjClosure *clo = dynamic_cast<ObjClosure *>(callee.obj.get());
                if (!clo) throw VmError{"被调者不可调用"};
                if (int(argc) != clo->fn->arity)
                    throw VmError{"元数不符：" + clo->fn->name};
                if (int(frames_.size()) >= kFramesMax)
                    throw VmError{"帧栈溢出（递归过深）"};
                frames_.push_back(
                    Frame{clo->fn.get(), clo, 0, stack_.size() - size_t(argc) - 1});
                if (int(frames_.size()) > maxFrames_) maxFrames_ = int(frames_.size());
                break;
            }
            case Op::GetGlobal: {
                uint8_t k = readByte();
                // 迟绑定：名字到运行期才解析——前向引用因此合法
                auto it = globals.find(f.fn->code->names[k]);
                if (it == globals.end())
                    throw VmError{"未定义全局：" + f.fn->code->names[k]};
                push(it->second);
                break;
            }
            case Op::SetGlobal: {
                uint8_t k = readByte();
                globals[f.fn->code->names[k]] = peek(0);  // 不弹：赋值表达式有值
                break;
            }
            case Op::Not: {
                Value a = pop();
                push(Value::num(a.isObj() || a.i != 0 ? 0 : 1));
                break;
            }
            case Op::Ne: {
                Value b = pop(), a = pop();
                push(Value::num(a.i == b.i ? 0 : 1));
                break;
            }
            case Op::Ge: {
                Value b = pop(), a = pop();
                push(Value::num(a.i >= b.i ? 1 : 0));
                break;
            }
            case Op::Le: {
                Value b = pop(), a = pop();
                push(Value::num(a.i <= b.i ? 1 : 0));
                break;
            }
            case Op::Lt: {
                Value b = pop(), a = pop();
                push(Value::num(a.i < b.i ? 1 : 0));
                break;
            }
            case Op::CloseUpvalue: {
                // §25.5：栈顶那格要被弹了——指着它的上值全体搬家
                closeUpvalues(stack_.size() - 1);
                break;
            }
            case Op::GetUpvalue: {
                uint8_t k = readByte();
                push(*frames_.back().closure->ups[k]->location);
                break;
            }
            case Op::SetUpvalue: {
                uint8_t k = readByte();
                *frames_.back().closure->ups[k]->location = peek(0);  // 不弹：赋值有值
                break;
            }
            case Op::Closure: {
                uint8_t k = readByte();
                uint8_t n = readByte();
                auto clo = std::make_shared<ObjClosure>();
                clo->fn = std::dynamic_pointer_cast<ObjFn>(
                    frames_.back().fn->code->consts[k].obj);
                clo->ups.reserve(n);
                for (int i = 0; i < n; ++i) {
                    bool isLocal = readByte() != 0;
                    uint8_t idx = readByte();
                    if (isLocal)
                        // 捕外层栈槽：captureUpvalue 查开放表（同格共享）
                        clo->ups.push_back(captureUpvalue(&stack_[frames_.back().base + idx]));
                    else
                        // 穿层传递：与外层闭包共享同一个上值对象
                        clo->ups.push_back(frames_.back().closure->ups[idx]);
                }
                push(Value::ref(clo));
                break;
            }
            case Op::Return: {
                // 帧要拆了：先搬家——指着本帧槽位的上值全部关闭（§25.4）
                closeUpvalues(frames_.back().base);
                Value result = pop();
                size_t base = frames_.back().base;
                frames_.pop_back();
                if (frames_.empty()) return result;  // 脚本帧返回：run 结束
                stack_.resize(base);                 // 弹掉本帧全部槽位
                push(result);                        // 返回值落在被调者位置
                break;
            }
        }
        if (trace_) depthTrace_.push_back(int(stack_.size()));
#ifdef IPTRACE
        std::cerr << "ip" << frames_.back().ip << ":d" << stack_.size() << " ";
#endif
    }
}

// ---------- 上值三函数（§25.3） ----------
std::shared_ptr<ObjUpvalue> VM::captureUpvalue(Value *slot) {
    // 先查开放表：同一格被两个闭包捕获 → 共享同一个上值（一改俱改）
    for (const auto &u : openUpvalues_)
        if (u->location == slot) return u;
    auto u = std::make_shared<ObjUpvalue>();
    u->location = slot;  // 开放：指栈格
    ++boxesCreated_;
    // 按栈址降序插入（栈顶在前——close 时从前往后扫即从栈顶向下）
    auto it = openUpvalues_.begin();
    while (it != openUpvalues_.end() && (*it)->location > slot) ++it;
    openUpvalues_.insert(it, u);
    return u;
}

void VM::closeUpvalues(size_t lastValidIndex) {
    // 关闭所有 location 指向 stack_[lastValidIndex .. 栈顶] 的上值：
    // 值搬进盒子、location 改指自己家（"指针搬家"）。
    Value *firstValid = &stack_[lastValidIndex];
    for (auto &u : openUpvalues_) {
        if (u->location >= firstValid) {
            u->closed = *u->location;
            u->location = &u->closed;
        }
    }
    openUpvalues_.erase(
        std::remove_if(openUpvalues_.begin(), openUpvalues_.end(),
                       [](const std::shared_ptr<ObjUpvalue> &u) {
                           return u->location == &u->closed;
                       }),
        openUpvalues_.end());
}

}  // namespace tip
