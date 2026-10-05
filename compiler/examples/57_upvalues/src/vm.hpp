// file: src/vm.hpp
// 第 54 章：栈式虚拟机——FETCH-DECODE-EXECUTE 大循环 + 调用帧（匠书 §15/§24）。
// 第 55 章的编译器与第 57 章的上值扩展复用本类（本地副本 + 追加指令）。
#ifndef TIP_VM_HPP
#define TIP_VM_HPP

#include <map>
#include <ostream>
#include <string>
#include <vector>

#include "chunk.hpp"

namespace tip {

// 调用帧（§24.1）：ip 与 frameBase 捕捉"一个函数调用"的全部现场。
// base 是本帧局部槽在值栈上的起点：实参在调用前已被压栈，
// 被调函数的槽 0..arity-1 恰与实参重合（匠书的巧妙省拷贝）。
struct Frame {
    ObjFn *fn = nullptr;
    ObjClosure *closure = nullptr;  // 57 章：上值经闭包解析（脚本帧也有壳）
    size_t ip = 0;    // 指令指针（chunk 内字节偏移）
    size_t base = 0;  // 帧基（值栈下标）
};

struct VmError {
    std::string msg;
};

class VM {
  public:
    explicit VM(std::ostream &out) : out_(&out) {}

    std::map<std::string, Value> globals;  // 迟绑定名表（函数注册处）

    // 运行一个函数体（脚本也是函数）。抛 VmError 报运行期错误。
    Value run(const std::shared_ptr<ObjFn> &fn);

    void setTrace(bool on) { trace_ = on; }  // 开：记录每指令后栈深

    // —— 供断言的结构账（第 55/57 章对照用）——
    int maxFrames() const { return maxFrames_; }     // 帧深峰值
    int maxStack() const { return maxStack_; }       // 栈深峰值
    const std::vector<int> &depthTrace() const { return depthTrace_; }  // 每指令后栈深
    // —— 57 章上值账 ——
    int openUpvalueCount() const { return int(openUpvalues_.size()); }
    int boxesCreated() const { return boxesCreated_; }  // 堆盒子数（对照 13 章环境节点）

  private:
    uint8_t readByte();                // 取操作数并推进 ip
    uint16_t readU16();
    Value pop();
    void push(Value v);
    Value &peek(int down);
    // 上值三函数（§25.3）
    std::shared_ptr<ObjUpvalue> captureUpvalue(Value *slot);
    void closeUpvalues(size_t lastValidIndex);  // 关闭指向 lastValid..栈顶 的上值

    std::vector<Value> stack_;
    std::vector<Frame> frames_;
    std::vector<std::shared_ptr<ObjUpvalue>> openUpvalues_;  // 按栈址降序
    int boxesCreated_ = 0;
    std::ostream *out_;
    int maxFrames_ = 0;
    int maxStack_ = 0;
    std::vector<int> depthTrace_;
    bool trace_ = false;
};

}  // namespace tip

#endif  // TIP_VM_HPP
