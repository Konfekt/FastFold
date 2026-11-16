#!/bin/sh
# Run the headless test suite in Vim and Neovim (whichever are installed).
# Override the binaries with VIM_BIN / NVIM_BIN.
set -u
cd "$(dirname "$0")" || exit 1
status=0
log=$(mktemp) || exit 1
trap 'rm -f "$log"' EXIT
for bin in "${VIM_BIN:-vim}" "${NVIM_BIN:-nvim}"; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "skip: $bin not found"
    continue
  fi
  echo "== $bin"
  : >"$log"
  rc=0
  for test in test_fastfold.vim test_lateload.vim; do
    FASTFOLD_TEST_OUT=$log "$bin" -Nu NONE -i NONE -es -S "$test" </dev/null || rc=1
  done
  cat "$log"
  [ "$rc" -eq 0 ] || status=1
done
exit "$status"
