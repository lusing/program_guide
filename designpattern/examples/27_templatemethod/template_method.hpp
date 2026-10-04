#pragma once
// 模板方法：父类固定算法骨架（run 的剧本），子类只填步骤——"别调用我们，我们会调用你"。
#include <string>

namespace dp {

// AbstractClass：run() 是模板方法——步骤顺序写死在父类，子类不可改剧本。
class Game {
public:
    virtual ~Game() = default;

    [[nodiscard]] std::string run() const {
        std::string out = initialize();
        for (int i = 1; i <= 3; ++i) out += take_turn(i);
        out += hook();                    // 钩子：默认空实现，子类可选择性插入
        out += end();
        return out;
    }

protected:
    [[nodiscard]] virtual std::string initialize() const = 0;
    [[nodiscard]] virtual std::string take_turn(int i) const = 0;
    [[nodiscard]] virtual std::string end() const = 0;
    [[nodiscard]] virtual std::string hook() const { return ""; }   // 钩子默认实现
};

// ConcreteClass：两盘棋各自填步骤，剧本一个字不能改。
struct Chess final : Game {
private:
    [[nodiscard]] std::string initialize() const override { return "init chess;"; }
    [[nodiscard]] std::string take_turn(int i) const override {
        return "turn " + std::to_string(i) + ";";
    }
    [[nodiscard]] std::string end() const override { return "end;"; }
    [[nodiscard]] std::string hook() const override { return "check;"; }   // 棋类加"将军"检查
};

struct Go final : Game {
private:
    [[nodiscard]] std::string initialize() const override { return "init go;"; }
    [[nodiscard]] std::string take_turn(int i) const override {
        return "turn " + std::to_string(i) + ";";
    }
    // end()/hook() 不给——Go 不必都写：end 必须实现，hook 吃默认空实现
    [[nodiscard]] std::string end() const override { return "end;"; }
};

}  // namespace dp
