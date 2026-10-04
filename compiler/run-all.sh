#!/usr/bin/env bash
set -euo pipefail
MSYS=/g/scoop/apps/msys2/current
if [ "${MSYSTEM:-}" != "UCRT64" ] && [ -z "${UCRT_INVOKED:-}" ]; then
  export UCRT_INVOKED=1
  exec "$MSYS/usr/bin/bash" -lc "cd '$(pwd)' && UCRT_INVOKED=1 ./run-all.sh $*"
fi
export PATH=/ucrt64/bin:$PATH
ROOT=$(cd "$(dirname "$0")" && pwd); cd "$ROOT"
PY=${PYTHON:-python}
FILTER="$*"
for d in examples/*/; do
  name=$(basename "$d")
  if [ -n "$FILTER" ] && ! echo "$name" | grep -E "$FILTER"; then continue; fi
  bash tools/example_build.sh "${d%/}" .
  "$PY" tools/check_example.py "${d%/}"
done
"$PY" tools/check_docs.py
