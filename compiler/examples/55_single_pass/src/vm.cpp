// file: src/vm.cpp
#include "vm.hpp"

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

    // 脚本帧：把函数值压栈再建帧——槽 0 被被调函数自己占位（clox 同款，
    // 后续脚本级"局部槽 0 保留"贯穿第 55 章）
    push(Value::ref(fn));
    frames_.push_back(Frame{fn.get(), 0, 0});
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
                auto *target = dynamic_cast<ObjFn *>(callee.obj.get());
                if (!target) throw VmError{"被调者不可调用"};
                if (int(argc) != target->arity)
                    throw VmError{"元数不符：" + target->name};
                if (int(frames_.size()) >= kFramesMax)
                    throw VmError{"帧栈溢出（递归过深）"};
                frames_.push_back(Frame{target, 0, stack_.size() - argc - 1});
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
            case Op::CloseUpvalue:
                // 第 57 章启用（Op 枚举冻结位）：本章手编语料不出现
                throw VmError{"CLOSE_UPVALUE 未启用（第 57 章）"};
            case Op::Return: {
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
    }
}

}  // namespace tip
