#!/usr/bin/env bash
# HOL4 教程示例验证脚本（HOL4 Trindemossen 2 / Poly-ML 5.9.2，macOS 实测）
#
# 用法:
#   ./run-all.sh                      # 全量验证
#   ./run-all.sh 05                   # 只验证 05 章（其余跳过）
#   HOLBIN=/path/to/hol ./run-all.sh  # 覆盖 hol 可执行文件位置
#   ./run-all.sh clean                # 清理 build/ 下本脚本产生的子目录
#
# 注意：每章开头会 `rm -rf` 三个通道目录。某些沙箱/工具层对"单条命令删除
# 的文件数"有阈值（本机实测 50），全量跑时可能弹批量确认。遇到就把全量拆成
# `./run-all.sh NN` 分批跑 —— 判定逻辑完全一样，只是每批删得少。
#   TMO=60 ./run-all.sh               # 每个通道的看门狗秒数（默认 120）
#
# 为什么要有看门狗：`metis_tac` / `rw` 在被喂进一组方向不对称的定理时可能
# **不终止**（实测：用 RTC_TRANS 去证 `RTC R x y /\ R y z ==> RTC R x z`，
# 而 RTC_TRANS 的两个前提其实都是 RTC，metis 会一直转）。这时退出码判据
# 完全失效 —— 进程还在跑，只是永远跑不完。看门狗把它变成一个可诊断的失败。
#
# 通道（每条通道都在自己的空目录里跑，互不干扰）：
#   run1 / run2  ——  `hol run TutNNScript.sml` 两条独立进程
#   hm           ——  `Holmake TutNNTheory.uo`，输出从 .hol/logs/TutNNTheory 取
#
# 判定（每条通道 5 项 + 2 项跨通道比对，每章 3×? 见下）：
#   1. 退出码 0。                     —— `hol run` 与 Holmake 遇未捕获异常都退 1；
#                                        REPL 管道模式**不会**，所以必须用这两个入口。
#   2. stderr 为空。
#   3. 两个标记 `==== NN 开始 ====` / `==== NN 结束 ====` 都在。
#   4. 标记区间非空，且不含 [[:cntrl:]] 控制字符。
#      用 POSIX 字符类而不是 [^[:print:]]：后者的补集在 LC_ALL=C 下会把
#      CJK 的 UTF-8 高字节全判成"非可打印"。
#   5. 区间无溃逃痕迹（见 escape_trace 函数：必须是"横幅 + 后续行"的组合）。
#   6. run1 与 run2 的区间逐字节一致（运行间确定性）。
#   7. run1 与 hm 的区间逐字节一致（两条独立入口的一致性）。
#
# 为什么必须做第 5 项：HOL4 里 `prove` 失败会打印
#     Proof of ... failed. First unsolved sub-goal is ...
# 然后抛异常；在交互式 REPL 里（管道喂脚本）异常被打印后脚本**继续跑完**、
# 退出码仍是 0。`hol run` 与 Holmake 会退 1，所以第 1 项能兜住，但第 5 项
# 是唯一能抓住"捕获了异常却仍然打印失败横幅"的判据。
#
# 为什么两条通道的输出能逐字节一致：脚本开头关掉了两条只在一个入口出现的
# 系统提示（Theory.save_thm_reporting / Definition.storage_message），
# 否则 "Saved theorem ___" 只出现在 Holmake，而 "Definition has been
# stored under" 只出现在交互式通道。详见 docs/23-engineering.md。
set -uo pipefail
cd "$(dirname "$0")"

EXAMPLES=examples
OUT="$(pwd)/build"     # 绝对路径：通道在子目录里 cd 过，相对路径会写错地方

# --- 工具发现：不硬编码，缺工具直接报错退出 -----------------------------
if [[ -n "${HOLBIN:-}" ]]; then
  HOL="$HOLBIN"
else
  HOL=""
  for cand in \
    /Volumes/mac004/lang/hol4-build/bin/hol \
    /Volumes/mac004/lang/hol/bin/hol \
    "$HOME"/hol/bin/hol \
    /usr/local/bin/hol; do
    [[ -x "$cand" ]] && HOL="$cand" && break
  done
  [[ -z "$HOL" ]] && command -v hol >/dev/null 2>&1 && HOL="$(command -v hol)"
fi
if [[ ! -x "${HOL:-}" ]]; then
  echo "未找到 hol 可执行文件：请先构建 HOL4，或设 HOLBIN=/path/to/hol" >&2
  exit 1
fi
HOLMAKE="$(dirname "$HOL")/Holmake"
[[ -x "$HOLMAKE" ]] || { echo "未找到 Holmake（期望在 $(dirname "$HOL")）" >&2; exit 1; }

only="${1:-}"

if [[ "$only" = clean ]]; then
  for d in "$OUT"/[0-9]*; do
    [[ -d "$d" ]] && rm -rf "$d"
  done
  echo "已清理 $OUT/ 下各章子目录"
  exit 0
fi

mkdir -p "$OUT"

# --- 看门狗：优先 MacPorts 的 gtimeout，其次 GNU timeout，都没有就裸跑 -----
TMO="${TMO:-120}"
if [[ "$TMO" != 0 ]]; then
  if command -v gtimeout >/dev/null 2>&1; then
    watchdog() { gtimeout -s KILL "$TMO" "$@"; }
  elif command -v timeout >/dev/null 2>&1; then
    watchdog() { timeout -s KILL "$TMO" "$@"; }
  else
    watchdog() { "$@"; }
    echo "警告：系统里没有 timeout/gtimeout，本轮无看门狗保护" >&2
  fi
else
  watchdog() { "$@"; }
fi

# --- 区间抽取 -------------------------------------------------------------
# 从 begin 标记的**下一行**开始打印，到 end 标记为止（两个标记本身都不输出）。
#
# 匹配必须是**整行严格相等**（$0 == b / $0 == e），不能写 index($0, ...)。
# 原因（第 23 章实测踩到）：教程正文里会"提到"标记长什么样，比如
#     `==== 23 结束 ====` 之后有构建系统的话：
# 子串匹配会把它当成真的结束标记，于是区间被提前截断 —— 而"区间非空"、
# "两条通道一致"这些判据照样全绿，丢掉的那半章没人发现。
extract() { # $1=输入文件 $2=章号 $3=输出文件
  awk -v b="==== $2 开始 ====" -v e="==== $2 结束 ====" '
    $0 == e { exit }
    p { print }
    $0 == b { p = 1 }
  ' "$1" > "$3"
}

# --- 溃逃痕迹：组合判据，不是关键字列表 ----------------------------------
# 见文件头注释。每一种都是"横幅行 + 紧随其后的特征行"，或者是只在真正失败时
# 才会出现的完整横幅。
#
# **所有单行判据都必须锚定行首（^）**，并尽量带上"只有真错误才有"的上下文。
# 这是第 23 章实测踩出来的：那一章的正文在**讲解**这些横幅长什么样，把
# `Static Errors` / `Uncaught exception` / `: error:` 原样印在了输出里，
# 于是裸的子串判据把"讲解"当成了"痕迹" —— 三条通道全红，而脚本其实没毛病。
# 真实的错误行形状（实测）：
#     bad.sml:4: error: Pattern and expression have incompatible types.
#     Uncaught exception at ./basis/FinalPolyML.sml:492: Fail "Static Errors"
# 注意 `Exception raised at ...` **不算**痕迹：教程里好几处故意 handle 住异常
# 打印出来做演示（19.3 / 22.4 / 23.2），它们是预期输出。
escape_trace() { # $1=区间文件；有痕迹返回 0
  LC_ALL=C awk '
    /^Uncaught exception/                        { bad = 1 }
    /^Static Errors/                             { bad = 1 }
    /^poly:.*error/                              { bad = 1 }
    /^error in quse/                             { bad = 1 }
    /^[^[:space:]]+\.sml:[0-9]+.*: error:/       { bad = 1 }
    /^Proof of[[:space:]]*$/                     { inpf = 1 }
    inpf && /^failed\.[[:space:]]*$/             { bad = 1 }
    END { exit(bad ? 0 : 1) }
  ' "$1"
}

PASS=0; FAIL=0; FAILED=()

judge() { # $1=标签 $2=前缀 $3=章号
  local label="$1" pfx="$2" num="$3" ok=1 why="" rc
  rc="$(cat "$pfx.exit" 2>/dev/null || echo 1)"
  [[ "$rc" = 0 ]]           || { ok=0; why="${why:+$why; }退出码 $rc"; }
  [[ ! -s "$pfx.err" ]]     || { ok=0; why="${why:+$why; }stderr 非空"; }
  # 标记必须**各恰好出现一次**（整行严格相等）。只判"存在"不够：
  # 多打一次标记会让区间抽取停错地方，而"区间非空"照样通过。
  nb=$(grep -cxF "==== $num 开始 ====" "$pfx.out" 2>/dev/null || echo 0)
  ne=$(grep -cxF "==== $num 结束 ====" "$pfx.out" 2>/dev/null || echo 0)
  [[ "$nb" = 1 ]] || { ok=0; why="${why:+$why; }开始标记出现 ${nb} 次（应为 1）"; }
  [[ "$ne" = 1 ]] || { ok=0; why="${why:+$why; }结束标记出现 ${ne} 次（应为 1）"; }
  [[ -s "$pfx.sec" ]]        || { ok=0; why="${why:+$why; }区间为空"; }
  LC_ALL=C grep -q '[[:cntrl:]]' "$pfx.sec" 2>/dev/null \
                              && { ok=0; why="${why:+$why; }区间含控制字符"; }
  escape_trace "$pfx.sec"    && { ok=0; why="${why:+$why; }区间含溃逃痕迹"; }
  if [[ "$ok" = 1 ]]; then
    PASS=$((PASS + 1)); echo "    [OK]   $label"
  else
    FAIL=$((FAIL + 1)); FAILED+=("$label ($why)"); echo "    [!]    $label  ($why)"
  fi
}

compare() { # $1=文件A $2=文件B $3=标签
  if cmp -s "$1" "$2"; then
    PASS=$((PASS + 1)); echo "    [OK]   $3"
  else
    FAIL=$((FAIL + 1)); FAILED+=("$3 (区间不一致)"); echo "    [!]    $3  (区间不一致)"
  fi
}

echo "hol     = $HOL"
echo "Holmake = $HOLMAKE"
echo

for dir in "$EXAMPLES"/[0-9]*/; do
  dname=$(basename "$dir")
  num=${dname%%_*}
  src="$dir$dname.sml"
  [[ -f "$src" ]] || { echo "[skip] $dname：缺少 $dname.sml"; continue; }
  if [[ -n "$only" && "$only" != "$num" && "$only" != "$dname" ]]; then continue; fi
  echo "== [$num] $dname"

  base="$OUT/$dname"
  mkdir -p "$base"
  for ch in run1 run2 hm; do
    d="$base/$ch"
    rm -rf "$d"; mkdir -p "$d"
    cp "$src" "$d/Tut${num}Script.sml"
  done

  # 通道 1/2：hol run
  for ch in run1 run2; do
    d="$base/$ch"
    ( cd "$d" && watchdog "$HOL" run "Tut${num}Script.sml" \
        >"$base/$ch.out" 2>"$base/$ch.err" )
    # 137 = 被 KILL，即看门狗触发（真崩是 1）
    rc=$?; [[ "$rc" = 137 ]] && echo "（看门狗：${TMO}s 内没跑完，多半是某个 tactic 不终止）" \
        >> "$base/$ch.err"
    echo "$rc" > "$base/$ch.exit"
  done

  # 通道 3：Holmake；脚本输出落在 .hol/logs/TutNNTheory 里
  d="$base/hm"
  ( cd "$d" && watchdog "$HOLMAKE" "Tut${num}Theory.uo" \
      >"$base/hm.out" 2>"$base/hm.err" )
  rc=$?; [[ "$rc" = 137 ]] && echo "（看门狗：${TMO}s 内没跑完）" >> "$base/hm.err"
  echo "$rc" > "$base/hm.exit"
  if [[ -f "$d/.hol/logs/Tut${num}Theory" ]]; then
    cp "$d/.hol/logs/Tut${num}Theory" "$base/hm.out"
  else
    : > "$base/hm.out"
  fi

  for ch in run1 run2 hm; do
    extract "$base/$ch.out" "$num" "$base/$ch.sec"
    judge "$ch  $dname" "$base/$ch" "$num"
  done

  # 注意：bash 5.3 下 `$dname` 紧跟全角标点会把多字节吞进变量名（set -u 直接报错），
  # 所以这里一律写 ${dname}。
  compare "$base/run1.sec" "$base/run2.sec" "run1==run2  ${dname}（运行间确定性）"
  compare "$base/run1.sec" "$base/hm.sec"   "run1==hm    ${dname}（两条入口一致）"
  echo
done

echo "----------------------------------------"
echo "通过 ${PASS}，失败 ${FAIL}"
if [[ "$FAIL" -gt 0 ]]; then
  printf '失败项：\n'; printf '  - %s\n' "${FAILED[@]}"
  exit 1
fi
exit 0
