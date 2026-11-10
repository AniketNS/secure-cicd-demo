#!/usr/bin/env bash
# Writes a readable Trivy report (counts, findings, every package scanned)
# to the GitHub job summary. Usage: trivy-summary.sh <trivy.json> "<title>"
set -euo pipefail

JSON="$1"
TITLE="$2"
OUT="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

[ -f "$JSON" ] || { echo "## $TITLE" >> "$OUT"; echo "No report was produced." >> "$OUT"; exit 0; }

packages=$(jq '[.Results[]?.Packages[]?] | length' "$JSON")
vulns=$(jq '[.Results[]?.Vulnerabilities[]?] | length' "$JSON")
secrets=$(jq '[.Results[]?.Secrets[]?] | length' "$JSON")
misconfigs=$(jq '[.Results[]?.Misconfigurations[]?] | length' "$JSON")

{
  echo "## $TITLE"
  echo
  echo "| Packages scanned | HIGH/CRITICAL vulnerabilities | Secrets | Misconfigurations |"
  echo "|---:|---:|---:|---:|"
  echo "| $packages | $vulns | $secrets | $misconfigs |"
  echo

  if [ "$vulns" -gt 0 ]; then
    echo "### Vulnerabilities"
    echo
    echo "| Package | Installed | Vulnerability | Severity | Fixed in |"
    echo "|---|---|---|---|---|"
    jq -r '.Results[]?.Vulnerabilities[]? | "| \(.PkgName) | \(.InstalledVersion) | \(.VulnerabilityID) | \(.Severity) | \(.FixedVersion // "-") |"' "$JSON"
    echo
  fi

  echo "<details><summary>All $packages packages scanned</summary>"
  echo
  echo "| Target | Package | Version |"
  echo "|---|---|---|"
  jq -r '.Results[]? | .Target as $t | .Packages[]? | "| \($t) | \(.Name) | \(.Version) |"' "$JSON" | sort -u
  echo
  echo "</details>"
} >> "$OUT"
