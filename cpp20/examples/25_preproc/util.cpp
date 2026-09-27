#include "util.h"

// ── 链接性：谁能看见这些名字？ ─────────────────────────────
int visits = 0;                 // 定义（外部链接）：别的翻译单元经 extern 声明可用

static int checksum(int v) {    // static 函数：内部链接，只属于本翻译单元
    return v * 31 + 7;
}

namespace {                     // 匿名命名空间：现代 C++ 里比 static 更地道的“内部链接”
    int local_bonus = 5;
}

int shared_hits() {
    return checksum(visits) + local_bonus;
}

namespace app {
    int bump() { return ++visits; }
}
