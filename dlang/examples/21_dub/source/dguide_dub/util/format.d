// 子包目录 util/：更深一层也没问题
module dguide_dub.util.format;

import std.conv, std.format;

string formatMoney(double amount) {
    return format("%.2f 元", amount);
}

unittest {
    assert(formatMoney(1.5) == "1.50 元");
}
