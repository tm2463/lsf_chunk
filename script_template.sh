#!/usr/bin/env bash

set -uo pipefail

BATCH_FILE="${1:?Usage: $0 <batch_file>}"
OUTDIR="$(dirname "$BATCH_FILE")"
CPUS="${CPUS:-1}"

if [[ ! -f "$BATCH_FILE" ]]; then
    echo "ERROR: batch file not found: $BATCH_FILE" >&2
    exit 1
fi

process_item() {
    local item="$1"
    # ---- EXAMPLE: replace with your real command ----
    # my_tool --input "$item" --threads "$CPUS" --outdir "$OUTDIR"
    echo "Processing: $item"
}

n_total=0
n_fail=0
while IFS= read -r item || [[ -n "$item" ]]; do
    [[ -z "$item" ]] && continue
    n_total=$((n_total + 1))
    if ! process_item "$item"; then
        echo "WARNING: failed on item: $item" >&2
        n_fail=$((n_fail + 1))
    fi
done < "$BATCH_FILE"

echo "Done. total=${n_total} fail=${n_fail}"
(( n_fail > 0 )) && exit 1
exit 0
