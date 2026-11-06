#!/usr/bin/env bash
# Check a page, wait for the result, and (after fixing and deploying) verify the fix with the BACKLNK REST API.
# Usage: BACKLNK_API_KEY=bk_... ./rest-api.sh https://example.com/
# Needs curl and jq.
set -euo pipefail

: "${BACKLNK_API_KEY:?Set BACKLNK_API_KEY to your free key from https://backlnk.com/developers}"
URL="${1:?Pass the public URL to check}"
API="https://backlnk.com/api/v1"
AUTH=(-H "Authorization: Bearer ${BACKLNK_API_KEY}")

wait_for() {
  local id="$1" state
  for _ in $(seq 1 60); do
    state=$(curl -sS "${AUTH[@]}" "${API}/audits/${id}" | jq -r '.state')
    case "$state" in Completed|Partial|Failed|Cancelled|Expired) echo "$state"; return ;; esac
    sleep 3
  done
  echo "Running"
}

# 1. Start the checks (one audit per check).
ids=$(curl -sS -X POST "${API}/audits" "${AUTH[@]}" -H "Content-Type: application/json" \
  -d "{\"url\":\"${URL}\",\"checks\":[\"meta-tags\",\"page-structure\"]}" | jq -r '.audits[].id')

# 2. Read each report: issues and warnings, most important first.
for id in $ids; do
  echo "== ${id}: $(wait_for "$id")"
  curl -sS "${AUTH[@]}" "${API}/audits/${id}?detail=actions" | jq '{check, summary, findings: [.findings[] | {status, severity, title, recommendation}]}'
done

# 3. After you fixed and deployed the page, re-check and compare with the first run:
#    curl -sS -X POST "${API}/audits/AUDIT_ID/verify" "${AUTH[@]}"
#    then GET /audits/NEW_ID: its "comparison" lists what is fixed, new, still open and not re-checked.
