#!/usr/bin/env bash
# Release check: runs every check regardless of failures and prints a
# summary. Exit code is non-zero when any check fails.
# Requires: dart, flutter, pana (dart pub global activate pana).

PANA_THRESHOLD=${PANA_THRESHOLD:-10}

NAMES=()
STATUSES=()
DETAILS=()


announce() { printf "→ %s...\n" "$1"; }

record() { # name pass detail
  NAMES+=("$1"); STATUSES+=("$2"); DETAILS+=("$3")
}

PKG_VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
PKG_NAME=$(grep '^name:' pubspec.yaml | awk '{print $2}')
echo "== $PKG_NAME $PKG_VERSION release check =="

# --- git tree clean -----------------------------------------------------------
announce "git status"
DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$DIRTY" = "0" ]; then record "git tree clean" pass "no changes"
else record "git tree clean" fail "$DIRTY dirty/untracked files"; fi

# --- format -------------------------------------------------------------------
announce "format"
if OUT=$(dart format --output=none --set-exit-if-changed . 2>&1); then
  record "format" pass "no changes needed"
else
  N=$(echo "$OUT" | grep -c '^Changed'); record "format" fail "$N files need formatting"
fi

# --- analyzer -----------------------------------------------------------------
announce "analyzer"
if OUT=$(dart analyze 2>&1); then record "analyzer" pass "no issues"
else N=$(echo "$OUT" | grep -cE ' (error|warning|info) '); record "analyzer" fail "$N issues"; fi

# --- tests --------------------------------------------------------------------
announce "tests"
OUT=$(flutter test ${TEST_PATH:-} 2>&1 | tail -1)
if echo "$OUT" | grep -q "All tests passed"; then
  N=$(echo "$OUT" | grep -oE '\+[0-9]+' | tr -d '+' | tail -1)
  record "tests" pass "$N passed"
else
  DETAIL=$(echo "$OUT" | tr -d '\r' | head -c 60)
  record "tests" fail "${DETAIL:-tests produced no output}"
fi

# --- publish dry-run ----------------------------------------------------------
announce "publish dry-run"
if OUT=$(dart pub publish --dry-run 2>&1); then
  record "publish dry-run" pass "package validates"
else
  record "publish dry-run" fail "$(echo "$OUT" | grep -E 'Package (has|validation)' | tail -1 | head -c 60)"
fi

# --- pana ---------------------------------------------------------------------
announce "pana"
if command -v pana >/dev/null 2>&1; then
  OUT=$(pana --no-warning --exit-code-threshold "$PANA_THRESHOLD" . 2>&1)
  PANA_EXIT=$?
  SCORE=$(echo "$OUT" | grep -oE 'Points: [0-9]+/[0-9]+' | tail -1)
  if [ $PANA_EXIT -eq 0 ]; then record "pana" pass "${SCORE:-scored} (threshold: -$PANA_THRESHOLD)"
  else record "pana" fail "${SCORE:-failed} (threshold: -$PANA_THRESHOLD)"; fi
else
  record "pana" fail "not installed — dart pub global activate pana"
fi

# --- changelog ----------------------------------------------------------------
announce "changelog"
CL_HEAD=$(grep -m1 '^## ' CHANGELOG.md | sed 's/## //' | tr -d ' ')
if [ "$CL_HEAD" = "$PKG_VERSION" ]; then
  ENTRIES=$(awk '/^## /{n++} n==1 && /^- /{c++} END{print c+0}' CHANGELOG.md)
  if [ "$ENTRIES" -gt 0 ]; then record "changelog" pass "$PKG_VERSION heading with $ENTRIES entries"
  else record "changelog" fail "$PKG_VERSION heading has no entries"; fi
else
  record "changelog" fail "heading '$CL_HEAD' != version '$PKG_VERSION'"
fi

# --- dependency versions ------------------------------------------------------
announce "dependencies"
DEP_DETAIL=""
DEP_FAIL=0
# Overrides must live in pubspec_overrides.yaml (not published), never in
# pubspec.yaml where they'd ship or mask real constraint problems.
if grep -qE '^dependency_overrides:' pubspec.yaml; then
  DEP_DETAIL="dependency_overrides in pubspec.yaml (move to pubspec_overrides.yaml); "
  DEP_FAIL=1
fi
for SIB in xwidget_el xwidget; do
  [ "$SIB" = "$PKG_NAME" ] && continue
  grep -qE "^  $SIB:" pubspec.yaml || continue
  LOCKED=$(awk "/^  $SIB:/{f=1} f && /version:/{gsub(/\"/,\"\"); print \$2; exit}" pubspec.lock)
  LOCAL=$(grep '^version:' "../$SIB/pubspec.yaml" 2>/dev/null | awk '{print $2}')
  if [ -n "$LOCAL" ] && [ "$LOCKED" != "$LOCAL" ]; then
    DEP_DETAIL="$SIB locked $LOCKED != local $LOCAL; $DEP_DETAIL"; DEP_FAIL=1
  else
    DEP_DETAIL="$SIB $LOCKED ok; $DEP_DETAIL"
  fi
done
OUTDATED=$(dart pub outdated --json 2>/dev/null | python3 -c "
import json,sys
try:
  data = json.load(sys.stdin)
  n = sum(1 for p in data.get('packages', [])
          if p.get('isDiscontinued') is not True
          and p.get('current') and p.get('resolvable')
          and p['current'].get('version') != p['resolvable'].get('version'))
  print(n)
except Exception:
  print('?')
")
DEP_DETAIL="${DEP_DETAIL}${OUTDATED} upgradable"
if [ "$DEP_FAIL" = "0" ]; then record "dependencies" pass "$DEP_DETAIL"
else record "dependencies" fail "$DEP_DETAIL"; fi

# --- placeholder keys (define patterns when needed) ----------------------------
# record "placeholders" ...   # e.g. grep -rE 'CHANGEME|PLACEHOLDER-KEY' lib

# --- summary -------------------------------------------------------------------
echo ""
FAILED=0
i=0
while [ $i -lt ${#NAMES[@]} ]; do
  if [ "${STATUSES[$i]}" = "pass" ]; then MARK="✓"; else MARK="✗"; FAILED=$((FAILED+1)); fi
  printf " %s %-16s %s\n" "$MARK" "${NAMES[$i]}" "${DETAILS[$i]}"
  i=$((i+1))
done
TOTAL=${#NAMES[@]}
echo "--------------------------------------"
if [ $FAILED -eq 0 ]; then
  echo "$TOTAL/$TOTAL passed — READY"
  exit 0
else
  echo "$((TOTAL-FAILED))/$TOTAL passed — NOT READY"
  exit 1
fi
