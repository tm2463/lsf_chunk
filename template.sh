#!/usr/bin/env bash

set -uo pipefail

BATCH_FILE=${1}
OUTDIR="${OUTDIR:-.}"
CPUS="${CPUS:-1}"

if [[ ! -f "$BATCH_FILE" ]]; then
    echo "ERROR: batch file not found: $BATCH_FILE" >&2
    exit 1
fi

process_item() {
    local cols=("$@")

    echo "Processing: $item"

    # --- EXAMPLE: replace with your real command ---
    # sylph sketch -1 "${cols[1]}" -2 "${cols[2]}" -d "$OUTDIR" -t "$CPUS"

    return 0
}

n_total=0
n_fail=0
while IFS= read -r item || [[ -n "$item" ]]; do
    [[ -z "$item" ]] && continue
 
    IFS=',' read -r -a cols <<< "$item"
 
    n_total=$(( n_total + 1 ))
 
    if ! process_item "${cols[@]}"; then
        echo "WARNING: failed on item: $item" >&2
        n_fail=$(( n_fail + 1 ))
    fi
done < "$BATCH_FILE"
 
echo "Done. total=${n_total} fail=${n_fail}"
(( n_fail > 0 )) && exit 1
exit 0
