#pragma once
// 模板方法的 CRTP 形态：剧本仍是基类的 run()，步骤调用是静态分派（无虚表、可内联）。
// "钩子默认实现"靠名字隐藏：派生类不定义 hook() 时落到基类默认版本。
#include <string>

namespace dp {

template <class D>
class GameCRTP {
public:
    [[nodiscard]] std::string run() const {
        const D& self = static_cast<const D&>(*this);   // 静态下转：编译期确定 D
        std::string out = self.initialize();
        for (int i = 1; i <= 3; ++i) out += self.take_turn(i);
        out += self.hook();
        out += self.end();
        return out;
    }

protected:
    GameCRTP() = default;

    // 静态钩子默认实现：派生类没写 hook() 时，self.hook() 名字查找落到这里
    [[nodiscard]] std::string hook() const { return ""; }
};

struct ChessCRTP final : GameCRTP<ChessCRTP> {
    [[nodiscard]] std::string initialize() const { return "init chess;"; }
    [[nodiscard]] std::string take_turn(int i) const {
        return "turn " + std::to_string(i) + ";";
    }
    [[nodiscard]] std::string end() const { return "end;"; }
    [[nodiscard]] std::string hook() const { return "check;"; }   // 隐藏基类默认
};

struct GoCRTP final : GameCRTP<GoCRTP> {
    [[nodiscard]] std::string initialize() const { return "init go;"; }
    [[nodiscard]] std::string take_turn(int i) const {
        return "turn " + std::to_string(i) + ";";
    }
    [[nodiscard]] std::string end() const { return "end;"; }
    // hook() 不写：吃基类默认空实现——与虚函数版 Go 同构
};

}  // namespace dp
