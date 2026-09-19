#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

EXAMPLES_DIR="$PROJECT_ROOT/examples"
BUILD_DIR="$PROJECT_ROOT/build"
NESTED_PACKAGES=(19_testing 20_todo)

# ── 颜色 ──
if [[ -t 1 ]]; then
  CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'
else
  CYAN=''; GREEN=''; YELLOW=''; RED=''; NC=''
fi

info()  { printf "${CYAN}[%s]${NC} %s\n" "$1" "$2"; }
ok()    { printf "${GREEN}[Done]${NC} %s\n" "$1"; }
warn()  { printf "${YELLOW}[%s]${NC} %s\n" "$1" "$2"; }
fail()  { printf "${RED}[FAIL]${NC} %s\n" "$1" >&2; exit 1; }

run_dart() {
  local label="$1"; shift
  info "$label" "dart $*"
  dart "$@" || fail "命令失败：dart $*"
}

run_nested() {
  local name="$1"
  local dir="$EXAMPLES_DIR/$name"
  run_dart "PubGet" pub get --directory="$dir"
  info "Analyze" "dart analyze (in $name)"
  (cd "$dir" && dart analyze) || fail "analyze 失败：$name"
  info "Test" "dart test (in $name)"
  (cd "$dir" && dart test) || fail "test 失败：$name"
}

run_todo_demo() {
  mkdir -p "$BUILD_DIR"
  local demo="$BUILD_DIR/todo-demo.json"
  rm -f "$demo"
  local todo_dir="$EXAMPLES_DIR/20_todo"
  local cmds=(
    "add 买牛奶"
    "add 写周报"
    "add 修剪草坪"
    "list"
    "done 2"
    "list --all"
    "remove 3"
    "list --all"
  )
  for cmd in "${cmds[@]}"; do
    info "TodoDemo" "dart run bin/todo.dart -f $demo $cmd"
    (cd "$todo_dir" && dart run bin/todo.dart -f "$demo" $cmd) || fail "TodoDemo 失败：$cmd"
  done
}

usage() {
  cat <<'EOF'
用法:
  ./build.sh --all                       全量验证：analyze + 运行全部示例 + AOT + 嵌套包测试 + 根测试
  ./build.sh --file 06_collections.dart  运行单个示例
  ./build.sh --project 20_todo           验证嵌套包（19_testing 同理）
  ./build.sh --project 06_collections    运行单个单文件示例
  ./build.sh --test                      根包 analyze + test
  ./build.sh --clean                     清理 build 与 .dart_tool
EOF
}

# ── 参数解析 ──
MODE=""
TARGET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --all|-All)       MODE="all"; shift ;;
    --test|-Test)     MODE="test"; shift ;;
    --clean|-Clean)   MODE="clean"; shift ;;
    --file|-File)     MODE="file"; TARGET="${2:-}"; shift 2 ;;
    --project|-Project) MODE="project"; TARGET="${2:-}"; shift 2 ;;
    --help|-h)        usage; exit 0 ;;
    *)                warn "Arg" "未知参数：$1"; usage; exit 1 ;;
  esac
done

# ── Clean ──
if [[ "$MODE" == "clean" ]]; then
  for dir in "$PROJECT_ROOT" "${NESTED_PACKAGES[@]/#/$EXAMPLES_DIR/}"; do
    rm -rf "$dir/.dart_tool"
  done
  rm -rf "$BUILD_DIR"
  warn "Clean" "已清理 build 与 .dart_tool。"
  exit 0
fi

[[ -d "$EXAMPLES_DIR" ]] || fail "找不到 examples 目录: $EXAMPLES_DIR"

# ── 根包依赖 ──
run_dart "PubGet" pub get

# ── Test only ──
if [[ "$MODE" == "test" ]]; then
  run_dart "Analyze" analyze
  run_dart "Test" test
  ok "根包 analyze + test 通过。"
  exit 0
fi

# ── Single file ──
if [[ "$MODE" == "file" ]]; then
  [[ -n "$TARGET" ]] || fail "--file 需要文件名"
  [[ -f "$EXAMPLES_DIR/$TARGET" ]] || fail "找不到示例文件: $EXAMPLES_DIR/$TARGET"
  run_dart "Run" run "examples/$TARGET"
  exit 0
fi

# ── Project ──
if [[ "$MODE" == "project" ]]; then
  [[ -n "$TARGET" ]] || fail "--project 需要目录名"
  local_dir="$EXAMPLES_DIR/$TARGET"
  [[ -d "$local_dir" ]] || fail "找不到示例目录: $local_dir"
  if [[ -f "$local_dir/pubspec.yaml" ]]; then
    run_nested "$TARGET"
    [[ "$TARGET" == "20_todo" ]] && run_todo_demo
  else
    run_dart "Run" run "examples/$TARGET.dart"
  fi
  exit 0
fi

# ── All ──
if [[ "$MODE" == "all" ]]; then
  run_dart "Analyze" analyze

  files=($(ls "$EXAMPLES_DIR"/*.dart 2>/dev/null | sort))
  [[ ${#files[@]} -gt 0 ]] || fail "examples 目录下没有单文件示例。"
  for f in "${files[@]}"; do
    run_dart "Run" run "examples/$(basename "$f")"
  done

  mkdir -p "$BUILD_DIR"
  run_dart "AOT" compile exe examples/02_hello.dart -o build/02_hello

  for name in "${NESTED_PACKAGES[@]}"; do
    run_nested "$name"
  done
  run_todo_demo

  run_dart "Test" test
  ok "全部示例运行、AOT 编译、嵌套包测试、根测试通过。"
  exit 0
fi

usage
