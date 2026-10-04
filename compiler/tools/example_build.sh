#!/usr/bin/env bash
# 用法: example_build.sh <examples/NN_slug 相对路径> <工程根>
set -euo pipefail
EX=$1; ROOT=$2; NAME=$(basename "$EX"); BUILD="$ROOT/build/$NAME"
# 系统默认 java 是 Java 8；ANTLR 工具需 JDK 17（与 bootstrap.sh 一致）。
export JAVA_HOME="${JAVA_HOME:-/g/scoop/apps/openjdk17/current}"
export PATH="$JAVA_HOME/bin:/ucrt64/bin:$PATH"
mkdir -p "$BUILD/gen" "$BUILD/obj/gen" "$BUILD/obj/own"

GEN_SRCS=()
if [ -f "$EX/TIP.g4" ]; then
  java -jar "$ROOT/build/antlr/antlr.jar" -Dlanguage=Cpp -visitor -no-listener \
       -o "$BUILD/gen" "$EX/TIP.g4"
  GEN_SRCS=("$BUILD/gen"/TIPLexer.cpp "$BUILD/gen"/TIPParser.cpp)
fi

# ANTLR4CPP_STATIC：消费静态库时头文件里的 ANTLR4CPP_PUBLIC 才不会变成 dllimport。
FLAGS=(-std=c++17 -Wall -Wextra -Werror -DANTLR4CPP_STATIC
       -I"$BUILD/gen" -I"$ROOT/build/antlr/include" \
       -I"$ROOT/build/antlr/include/antlr4-runtime")
LIBS=("$ROOT/build/antlr/lib/libantlr4-runtime-static.a")
if [ -f "$EX/llvm.need" ]; then
  mapfile -t LCXX < <(llvm-config --cxxflags | tr ' ' '\n' | grep -v '^-std=')
  mapfile -t LLIB < <(llvm-config --ldflags --link-shared \
       --libs core orcjit support native analysis passes --system-libs)
  FLAGS+=("${LCXX[@]}"); LIBS+=("${LLIB[@]}")
fi

OBJS=()
# 生成代码不满足 -Wextra/-Werror：单独加 -w 编译。
for f in "${GEN_SRCS[@]}"; do
  o="$BUILD/obj/gen/$(basename "$f" .cpp).o"
  g++ "${FLAGS[@]}" -w -c "$f" -o "$o"
  OBJS+=("$o")
done
# 教程自有代码保持严格警告。
for f in "$EX"/src/*.cpp; do
  o="$BUILD/obj/own/$(basename "$f" .cpp).o"
  g++ "${FLAGS[@]}" -c "$f" -o "$o"
  OBJS+=("$o")
done
g++ "${OBJS[@]}" "${LIBS[@]}" -o "$BUILD/tipa"
echo "[build $NAME OK]"
