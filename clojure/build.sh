#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

# ---- 探测可用的 Java ----
# Clojure CLI 需要 Java 运行时；优先用系统 Java，避免 TRAE 内置的不可执行 java
if [[ -z "${JAVA_CMD:-}" ]]; then
    if [[ -x /usr/bin/java ]]; then
        export JAVA_CMD=/usr/bin/java
    elif command -v java &>/dev/null; then
        export JAVA_CMD="$(command -v java)"
    fi
fi

CLOJURE_CMD="${CLOJURE:-}"
if [[ -z "$CLOJURE_CMD" ]]; then
    if command -v clojure &>/dev/null; then
        CLOJURE_CMD="clojure"
    else
        echo "错误: 未找到 clojure CLI，请安装或设置 CLOJURE 环境变量。" >&2
        echo "  macOS:   brew install clojure/tools/clojure" >&2
        echo "  Linux:   curl -O https://github.com/clojure/brew-install/releases/latest/download/linux-install.sh" >&2
        echo "  自定义:  export CLOJURE=/path/to/clojure" >&2
        exit 1
    fi
fi

BUILD_DIR="$PROJECT_ROOT/build"
EXAMPLES_DIR="$PROJECT_ROOT/examples"

if [[ "${1:-}" == "--clean" ]]; then
    rm -rf "$BUILD_DIR"
    echo "[Clean] 已清理 build 目录。"
    exit 0
fi

mkdir -p "$BUILD_DIR"

# 收集所有 .clj 示例文件（按文件名排序）
mapfile -t CLOJURE_FILES < <(find "$EXAMPLES_DIR" -name '*.clj' | sort)

if [[ ${#CLOJURE_FILES[@]} -eq 0 ]]; then
    echo "错误: examples 目录下没有 .clj 示例文件。" >&2
    exit 1
fi

run_example() {
    local source_path="$1"
    local filename
    filename="$(basename "$source_path")"

    echo "[Run] $filename"

    # clojure -M 直接运行脚本，将 stdout 同时输出到终端和日志文件
    local logfile="$BUILD_DIR/${filename%.clj}.log"
    if JAVA_CMD="${JAVA_CMD:-}" "$CLOJURE_CMD" -M "$source_path" 2>&1 | tee "$logfile"; then
        # 检查是否出现结束标记
        if grep -q "==== .* jieshu ====" "$logfile"; then
            echo "[OK] $filename"
        else
            echo "[WARN] $filename - 未找到结束标记"
        fi
    else
        echo "[FAIL] $filename"
        return 1
    fi
}

if [[ "${1:-}" == "--all" ]]; then
    failed=0
    for f in "${CLOJURE_FILES[@]}"; do
        if ! run_example "$f"; then
            failed=$((failed + 1))
        fi
    done
    if [[ $failed -eq 0 ]]; then
        echo "[Done] 全部 ${#CLOJURE_FILES[@]} 个 Clojure 示例运行通过。"
    else
        echo "[Done] ${#CLOJURE_FILES[@]} 个示例中 $failed 个失败。"
        exit 1
    fi
    exit 0
elif [[ "${1:-}" == "--file" ]]; then
    if [[ -z "${2:-}" ]]; then
        echo "用法: $0 --file <name.clj>" >&2
        exit 1
    fi
    target="$EXAMPLES_DIR/$2"
    if [[ ! -f "$target" ]]; then
        echo "错误: 找不到示例文件: $target" >&2
        exit 1
    fi
    run_example "$target"
    exit 0
else
    echo "用法:"
    echo "  $0 --all              运行 examples 下全部 Clojure 示例"
    echo "  $0 --file <name.clj>  运行单个示例"
    echo "  $0 --clean            清理 build 目录"
    exit 0
fi
