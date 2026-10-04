#pragma once
// 迪米特法则：只和直接朋友说话。
#include <string>

namespace dp {

// 坏版本（正文展示）：customer.wallet().money() 一路摸到底。
// 好版本：Customer 把"付钱"封装成自己的行为，收银员只认识 Customer。
class Customer {
public:
    explicit Customer(int cash) : cash_(cash) {}

    // 直接朋友：自己。内部怎么扣钱，收银员不需要知道。
    bool pay(int amount) {
        if (cash_ < amount) return false;
        cash_ -= amount;
        return true;
    }
    [[nodiscard]] int cash() const { return cash_; }

private:
    int cash_;
};

class Checkout {
public:
    // 只与参数（直接朋友）交流，不摸 Customer 的钱包内部。
    bool scan(const Customer& c, int price) { return c.cash() >= price; }
};

}  // namespace dp
