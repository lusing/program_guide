#!/bin/bash
# s12：构建目录里到底生成了什么 —— module map、.o、swiftmodule 三份清单。
#
# 主线 §1/§21 要数「这一次链接到底吃了哪些输入」，那些数字的出处就是这个目录。
# 这里不猜，直接列：
#   1. 每个 target 都有一个 <T>.build/ 与一份 module.modulemap —— **Swift target 也有**，
#      但主线只能用 Clang target 那一份（另一份的 umbrella 指向 <T>-Swift.h，
#      再递一遍会和 Modules/<T>.swiftmodule 抢同一个模块名）；
#   2. .o 的分层（<T>.build/<file>.swift.o 与 <T>.build/<file>.c.o）；
#   3. Modules/ 里除 .swiftmodule 还多了什么（abi.json / swiftdoc / swiftsourceinfo），
#      以及 -emit-module 那一层为什么不能只靠 .o。
set -u

D="$SPMDBG"
if [ ! -d "$D" ]; then
    printf '（先跑一次非 sNN 探针把包产物准备好，或单独执行 prepare）\n'
    exit 1
fi

echo '=== 1) 中间目录的第一层：谁有 .build、谁有 module.modulemap'
for d in "$D"/*.build; do
    [ -d "$d" ] || continue
    base="$(basename "$d" .build)"
    printf '%-24s modulemap=%s  swiftmodule=%s  .o=%s\n' "$base" \
        "$([ -f "$d/module.modulemap" ] && echo 有 || echo 没有)" \
        "$([ -f "$D/Modules/$base.swiftmodule" ] && echo 有 || echo 没有)" \
        "$(ls "$d"/*.o 2>/dev/null | wc -l | tr -d ' ')"
done

echo
echo '--- 那两份 module.modulemap 各写了什么（umbrella 的路径是关键）'
for d in "$D"/*.build; do
    [ -f "$d/module.modulemap" ] || continue
    printf '### %s\n' "$(basename "$d")"
    cat "$d/module.modulemap" | sed 's/^/    /'
done

echo
echo '=== 2) .o 的分层：源码文件名 → 目标文件名'
find "$D" -name '*.o' | sed -e "s|$D/||" -e 's/^/    /' | sort

echo
echo '=== 3) Modules/ 里一个模块其实有四份文件'
ls "$D/Modules" | sed 's/^/    /'

echo
echo '--- .swiftmodule 里存的是什么（一句话：接口，不是代码）'
head -c 64 "$D/Modules/WeatherKit.swiftmodule" | sed -e 's/[^[:print:]]/./g' -e 's/^/    /'
echo
