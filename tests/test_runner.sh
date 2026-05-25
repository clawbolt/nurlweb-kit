#!/usr/bin/env bash
# nurlweb-kit/tests/test_runner.sh — Compile + link + run test files
#
# Iterates over .nu test files, compiles with nurlc, links with
# runtime.o, runs the binary, and checks exit codes.
#
# Usage:
#   bash nurlweb-kit/tests/test_runner.sh [test_file.nu ...]
#
# Environment:
#   NURLC         — path to nurlc binary (default: ../../build/nurlc)
#   NURL_RUNTIME  — path to runtime.o (default: ../../stdlib/runtime.o)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(dirname "$SCRIPT_DIR")"

NURLC="${NURLC:-$(cd "$SCRIPT_DIR" && pwd)/../../build/nurlc}"
RUNTIME="${NURL_RUNTIME:-$(cd "$SCRIPT_DIR" && pwd)/../../stdlib/runtime.o}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

pass=0
fail=0
skip=0

pass_test() { echo -e "  ${GREEN}PASS${NC} $1"; pass=$((pass + 1)); }
fail_test() { echo -e "  ${RED}FAIL${NC} $1 — $2"; fail=$((fail + 1)); }
skip_test() { echo -e "  ${YELLOW}SKIP${NC} $1 — $2"; skip=$((skip + 1)); }

# ── Link helper ─────────────────────────────────────────────────────

link_test() {
    local ll_file="$1"
    local out_file="${ll_file%.ll}"
    clang -O2 "$ll_file" "$RUNTIME" -lm -lpthread \
        $(pkg-config --libs libcurl openssl sqlite3 zlib libzstd 2>/dev/null || echo "-lcurl -lssl -lcrypto -lsqlite3 -lz -lzstd") \
        -o "$out_file" 2>/dev/null
}

# ── Process test files ──────────────────────────────────────────────

test_files=("$@")
if [ ${#test_files[@]} -eq 0 ]; then
    # Default: all .nu files in tests/
    test_files=("$SCRIPT_DIR"/*.nu)
fi

for test_file in "${test_files[@]}"; do
    [ -f "$test_file" ] || continue
    test_name="$(basename "$test_file")"
    ll_file="${test_file%.nu}.ll"

    echo "Testing $test_name..."

    # Compile
    if ! "$NURLC" "$test_file" > "$ll_file" 2>/dev/null; then
        fail_test "$test_name" "compilation failed"
        rm -f "$ll_file"
        continue
    fi

    # Link
    if ! link_test "$ll_file" > /dev/null 2>&1; then
        fail_test "$test_name" "linking failed"
        rm -f "$ll_file"
        continue
    fi

    # Run
    out_file="${test_file%.nu}"
    if "$out_file" > /dev/null 2>&1; then
        pass_test "$test_name"
    else
        exit_code=$?
        fail_test "$test_name" "exit code $exit_code"
    fi

    # Cleanup
    rm -f "$ll_file" "$out_file"
done

# ── Summary ─────────────────────────────────────────────────────────

echo ""
echo "Results: $pass passed, $fail failed, $skip skipped"
[ "$fail" -eq 0 ] && echo "All tests passed!" || echo "Some tests failed."
exit $fail
