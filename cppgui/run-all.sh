#!/usr/bin/env bash
# run-all.sh —— cppgui 教程非 Windows 验证入口（macOS / Linux）
#
# 与 build.ps1 判定对齐：构建 exit 0 + --selftest exit 0（60s 超时）+
# stdout（或 sidecar build/selftest-<name>.txt）含 "==== NN"与"结束 ===="标记。
# 本教程主线在 Windows/MSVC 实测；本脚本对缺失的框架依赖【声明式跳过】
# （打印缺失项后该部分不参与验证），不假装通过、也不算失败。
set -u
cd "$(dirname "$0")"

pass=0; fail=0; skipped_parts=()
missing_frameworks=()

command -v cmake >/dev/null 2>&1 || { echo "[env] 缺 cmake——无法验证"; exit 1; }

WX_DIR="${CPPGUI_WX_DIR:-G:/github/cpp/wxWidgets}"
IMGUI_DIR="${CPPGUI_IMGUI_DIR:-G:/github/cpp/imgui}"
FTXUI_DIR="${CPPGUI_FTXUI_DIR:-G:/github/cpp/FTXUI}"
TVISION_DIR="${CPPGUI_TVISION_DIR:-G:/github/cpp/tvision}"

cmake_args=(-DCMAKE_BUILD_TYPE=Release -DCPPGUI_ENABLE_WX=OFF -DCPPGUI_ENABLE_IMGUI=OFF -DCPPGUI_ENABLE_FTXUI=OFF -DCPPGUI_ENABLE_TVISION=OFF)

# imgui：源码可直接编入（win32/dx11 后端仅 Windows；SDL2 变体需 SDL2）
if [ -d "$IMGUI_DIR" ]; then
  if [ "$(uname -s)" = "Windows_NT" ] || [ "${CPPGUI_IMGUI_SDL2:-0}" = "1" ]; then
    cmake_args+=(-DCPPGUI_ENABLE_IMGUI=ON -DCPPGUI_IMGUI_DIR="$IMGUI_DIR")
  else
    missing_frameworks+=("imgui（非 Windows 需 CPPGUI_IMGUI_SDL2=1 且装 SDL2 后才可验 08 变体）")
  fi
else
  missing_frameworks+=("imgui：$IMGUI_DIR 不存在")
fi
[ -d "$FTXUI_DIR" ]   && cmake_args+=(-DCPPGUI_ENABLE_FTXUI=ON   -DCPPGUI_FTXUI_DIR="$FTXUI_DIR")   || missing_frameworks+=("FTXUI：$FTXUI_DIR 不存在")
[ -d "$TVISION_DIR" ] && cmake_args+=(-DCPPGUI_ENABLE_TVISION=ON -DCPPGUI_TVISION_DIR="$TVISION_DIR") || missing_frameworks+=("tvision：$TVISION_DIR 不存在")
# wx：需先有预构建前缀 build/dep-wx（本脚本不自建；无则跳过）
# config 安装在 lib/cmake/wxWidgets-<主>.<次>/ 带版本子目录，用通配检查
ls build/dep-wx/lib/cmake/wxWidgets*/wxWidgetsConfig.cmake >/dev/null 2>&1 && cmake_args+=(-DCPPGUI_ENABLE_WX=ON -DCPPGUI_WX_DIR="$WX_DIR") || missing_frameworks+=("wx：build/dep-wx 预构建不存在（tools/build-wx.ps1 产物）")

if [ ${#missing_frameworks[@]} -gt 0 ]; then
  echo "[声明式跳过] 以下部分不参与本次验证："
  for m in "${missing_frameworks[@]}"; do echo "  - $m"; done
fi

BUILD=build-run
cmake -S . -B "$BUILD" "${cmake_args[@]}" || { echo "[fail] cmake 配置失败"; exit 1; }
cmake --build "$BUILD" -j "$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)" || { echo "[fail] 构建失败"; exit 1; }

for src in examples/*.cpp; do
  name="$(basename "$src" .cpp)"
  exe="$BUILD/bin/$name"
  [ -f "$exe" ] || { echo "  [跳过] ${name}（该部分未启用）"; continue; }
  sidecar="$BUILD/selftest-$name.txt"; rm -f "$sidecar"
  # 在 $BUILD 内执行：tvision 系示例的 sidecar 用相对路径写入进程 CWD，
  # 统一让所有产物（.out/.err/sidecar）落 $BUILD，判定路径才能对齐。
  if (cd "$BUILD" && timeout 60 "bin/$name" --selftest >"$name.out" 2>"$name.err"); then
    if grep -q '==== [0-9]' "$BUILD/$name.out" && grep -q '结束 ====' "$BUILD/$name.out" \
       || { [ -f "$sidecar" ] && grep -q '==== [0-9]' "$sidecar" && grep -q '结束 ====' "$sidecar"; }; then
      if [ -s "$BUILD/$name.err" ]; then echo "  [失败] ${name}：stderr 非空"; fail=$((fail+1)); continue; fi
      echo "  [通过] $name"; pass=$((pass+1))
    else
      echo "  [失败] ${name}：未见结束标记"; fail=$((fail+1))
    fi
  else
    echo "  [失败] ${name}：退出码非 0 或超时"; fail=$((fail+1))
  fi
done

echo "======================================"
echo " 通过 $pass  失败 $fail"
echo "======================================"
[ "$fail" -eq 0 ]
