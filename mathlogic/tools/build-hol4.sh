#!/usr/bin/env bash
# HOL4 + Poly/ML 后台构建脚本（WSL Ubuntu-26.04）
# 源：G:\github\lang\polyml（本地克隆）+ G:\github\misc\HOL（develop）
set -ex
cd "$HOME"

# ---- 1. Poly/ML ----
if [ ! -x "$HOME/polyml/bin/poly" ]; then
  if [ ! -d polyml-src ]; then
    git clone --depth 1 -c core.autocrlf=false -c core.eol=lf \
      /mnt/g/github/lang/polyml polyml-src
  fi
  cd polyml-src
  ./configure --prefix="$HOME/polyml"
  make -j"$(nproc)"
  make install
  cd "$HOME"
fi
export PATH="$HOME/polyml/bin:$PATH"
poly -v || true

# ---- 2. HOL4（LF 规范化克隆）----
if [ ! -d hol4-src ]; then
  git clone --depth 1 -b develop -c core.autocrlf=false -c core.eol=lf \
    /mnt/g/github/misc/HOL hol4-src
fi
cd hol4-src
find . -type f \( -name '*.sml' -o -name '*.sig' -o -name '*.ML' \
  -o -name '*.grm' -o -name '*.lex' -o -name '*.hol' -o -name '*.txt' \
  -o -name '*.awk' -o -name '*.sh' -o -name '*.py' -o -name '*.src' \
  -o -name '*.ml' -o -name '*.mly' -o -name '*.unicode' \) \
  -exec sed -i 's/\r$//' {} + || true

# ---- 3. 配置 + 全量构建 ----
poly < tools/smart-configure.sml
time bin/build -F
echo BUILD_OK
