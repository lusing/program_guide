#pragma once
// 接口隔离：胖接口拆成客户端需要的小接口。
#include <string>
#include <string_view>

namespace dp {

// 坏版本：一体机接口。OldPrinter 被迫实现 fax/scan（正文展示，不参与断言）。
// 好版本：按能力拆分。
struct Printable {
    virtual ~Printable() = default;
    virtual std::string print(std::string_view doc) = 0;
};

struct Faxable {
    virtual ~Faxable() = default;
    virtual std::string fax(std::string_view doc) = 0;
};

// 老打印机只实现它真正有的能力，编译器不再强迫它假装能传真。
class OldPrinter final : public Printable {
public:
    std::string print(std::string_view doc) override {
        return std::string("print(") + std::string(doc) + ")";
    }
};

class MultiMachine final : public Printable, public Faxable {
public:
    std::string print(std::string_view doc) override {
        return std::string("print(") + std::string(doc) + ")";
    }
    std::string fax(std::string_view doc) override {
        return std::string("fax(") + std::string(doc) + ")";
    }
};

}  // namespace dp
