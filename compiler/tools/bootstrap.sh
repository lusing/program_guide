#!/usr/bin/env bash
# 引导静态分析教程实验台：UCRT64 LLVM/GCC + ANTLR 工具 jar + ANTLR C++ runtime
set -euo pipefail
export JAVA_HOME='/g/scoop/apps/openjdk17/current'
# MSYS2 登录 shell 不含 scoop shims；显式加入 Maven 与 UCRT64 工具路径
export PATH="/ucrt64/bin:/g/scoop/apps/maven/current/bin:$PATH"
ROOT=/g/code/guide/compiler

# 1) UCRT64 编译器/LLVM/构建工具（pacman 已验证联网）
pacman -S --needed --noconfirm \
  mingw-w64-ucrt-x86_64-llvm mingw-w64-ucrt-x86_64-clang \
  mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-ninja

# 2) ANTLR 工具 jar（源码树 4.13.3-SNAPSHOT；只构建 tool 模块及其依赖）
# 幂等：jar 已存在则跳过 mvn（Windows 页面文件紧张时 JVM 可能无法预留 G1 堆）。
mkdir -p "$ROOT/build/antlr"
if [ ! -f "$ROOT/build/antlr/antlr.jar" ]; then
  export MAVEN_OPTS='-Xmx512m -XX:MaxMetaspaceSize=256m -XX:+UseSerialGC'
  cd /g/github/java/antlr4
  mvn -q -pl tool -am -DskipTests package
  cp tool/target/antlr4-4.13.3-SNAPSHOT-complete.jar "$ROOT/build/antlr/antlr.jar"
fi

# 3) ANTLR C++ runtime 静态库，安装到 build/antlr
# 用绝对路径：mvn 被幂等跳过时当前目录可能不是 ANTLR 源码树。
cd /g/github/java/antlr4/runtime/Cpp
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$ROOT/build/antlr" \
  -DCMAKE_INSTALL_INCLUDEDIR=include -DCMAKE_INSTALL_BINDIR=bin \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DWITH_DEMO=OFF -DANTLR_BUILD_CPP_TESTS=OFF
cmake --build build -j
cmake --install build

# 4) 验收
test -f "$ROOT/build/antlr/antlr.jar"
test -f "$ROOT/build/antlr/lib/libantlr4-runtime-static.a"
test -d "$ROOT/build/antlr/include/antlr4-runtime"
llvm-config --version
echo "[bootstrap OK]"
