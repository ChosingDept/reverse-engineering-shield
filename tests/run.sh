#!/bin/bash
# Tests for audit.sh. Fixtures are generated at runtime so the repository never contains
# secret-looking strings.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
AUDIT="$ROOT/.agents/skills/reverse-engineering-shield/scripts/audit.sh"
WORK=$(mktemp -d "${TMPDIR:-/tmp}/shield-test.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0

# expect <name> <expected-exit> <grep-pattern-or-empty> <audit args...>
expect() {
  local name=$1 want=$2 pattern=$3; shift 3
  local out code
  out=$("$AUDIT" "$@" 2>&1); code=$?
  if [ "$code" != "$want" ]; then
    echo "FAIL $name: exit $code, expected $want"; echo "$out" | sed 's/^/     /'; FAIL=$((FAIL+1)); return
  fi
  if [ -n "$pattern" ] && ! grep -qE "$pattern" <<< "$out"; then
    echo "FAIL $name: output does not match /$pattern/"; echo "$out" | sed 's/^/     /'; FAIL=$((FAIL+1)); return
  fi
  echo "pass $name"; PASS=$((PASS+1))
}

minified() { printf 'var a=1;function b(c){return c*2}%s\n' "$(head -c 30000 /dev/zero | tr '\0' 'x')"; }

# 1. clean build
mkdir -p "$WORK/clean/assets"; minified > "$WORK/clean/assets/index.js"
expect clean-build 0 "result: 0 critical, 0 warning" "$WORK/clean"

# 2. source map in the artifact
mkdir -p "$WORK/maps/assets"; minified > "$WORK/maps/assets/index.js"
echo '{"version":3,"sources":["src/App.tsx"],"sourcesContent":["export const x=1"]}' > "$WORK/maps/assets/index.js.map"
expect source-map 2 "CRITICAL .*source maps" "$WORK/maps"

# 3. server secret is reported and masked
SECRET="sk_live_$(printf 'Ab1%.0s' {1..10})"
mkdir -p "$WORK/secret"; printf 'const k="%s";\n' "$SECRET" > "$WORK/secret/app.js"
expect secret 2 "CRITICAL secrets" "$WORK/secret"
if "$AUDIT" "$WORK/secret" 2>&1 | grep -qF "$SECRET"; then echo "FAIL secret-masked: full secret printed"; FAIL=$((FAIL+1)); else echo "pass secret-masked"; PASS=$((PASS+1)); fi

# 4. internal URL
mkdir -p "$WORK/internal"; echo 'fetch("http://localhost:3000/api")' > "$WORK/internal/app.js"
expect internal-url 1 "WARNING  internal/staging URLs" "$WORK/internal"

# 5. zipped extension with a map
(cd "$WORK/maps" && zip -qr "$WORK/ext.zip" .)
expect zip-archive 2 "CRITICAL .*source maps" "$WORK/ext.zip"

# 6. business terms
mkdir -p "$WORK/terms"; echo 'const floorPrice=computeMargin(x);' > "$WORK/terms/app.js"
SHIELD_TERMS="computeMargin" expect business-terms 1 'business term "computeMargin"' "$WORK/terms"

# 7. AI prompt shipped to the client
mkdir -p "$WORK/prompt"; echo 'const p="You are a pricing assistant";' > "$WORK/prompt/app.js"
expect ai-prompt 1 "AI prompt" "$WORK/prompt"

# 8. React Native bundles: Hermes bytecode vs plain text
mkdir -p "$WORK/rn-hermes" "$WORK/rn-plain"
printf '\xc6\x1f\xbc\x03\xc1\x03\x19\x1f' > "$WORK/rn-hermes/index.android.bundle"
echo 'var __BUNDLE_START_TIME__=1;' > "$WORK/rn-plain/index.android.bundle"
expect hermes 0 "Hermes bytecode bundle" "$WORK/rn-hermes"
expect plain-bundle 1 "enable Hermes" "$WORK/rn-plain"

# 9. missing target
expect missing-target 2 "not found" "$WORK/does-not-exist"

echo; echo "$PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
