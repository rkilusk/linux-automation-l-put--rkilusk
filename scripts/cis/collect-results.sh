#!/usr/bin/env bash
set -euo pipefail

RUN_ID="${GITHUB_RUN_ID:-local-$(date +%Y%m%d-%H%M%S)}"
DEST_DIR="${REPORT_DIR:-ansible/reports/${RUN_ID}}"
WORKSPACE="${GITHUB_WORKSPACE:-$PWD}"

mkdir -p "${DEST_DIR}"

COPIED=0

# If Ansible already fetched reports into run-scoped destination, keep as-is.
if find "${DEST_DIR}" -type f \( -name '*_pre_scan_*.json' -o -name '*_post_scan_*.json' -o -name '*_scan_*.json' \) -print -quit 2>/dev/null | grep -q .; then
  COPIED=1
fi

# Fallback: collect audit scan files from /opt if role stored outputs on managed-node style paths.
if [[ "${COPIED}" -eq 0 ]]; then
  mapfile -t DISCOVERED_SCAN_FILES < <(
    find "${WORKSPACE}" /opt /var/tmp /tmp \
      -type f \
      \( -name '*_pre_scan_*.json' -o -name '*_post_scan_*.json' -o -name '*_scan_*.json' \) \
      2>/dev/null || true
  )

  if [[ "${#DISCOVERED_SCAN_FILES[@]}" -gt 0 ]]; then
    for file in "${DISCOVERED_SCAN_FILES[@]}"; do
      cp "${file}" "${DEST_DIR}/"
    done
    COPIED=1
  fi
fi

if [[ "${COPIED}" -eq 0 ]]; then
  cat > "${DEST_DIR}/TODO-REPORT-SOURCE.txt" <<'EOF'
No known upstream CIS report directory was found.
Update scripts/cis/collect-results.sh after validating actual role output paths.
EOF
fi

echo "CIS reports staged in ${DEST_DIR}"
