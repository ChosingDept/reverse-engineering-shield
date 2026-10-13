#!/bin/bash
# Reverse Engineering Shield — audit what an artifact hands to clients: source maps, secrets,
# AI prompts, internal URLs, unminified code, React Native bundles without Hermes and, in URL
# mode, maps and sensitive files exposed by a live site.
#
# Usage:
#   audit.sh <build-folder | .zip | .crx | .xpi | .apk | .ipa | .aab | .asar>
#   audit.sh https://your-domain.example          (only domains you own or are authorized to test)
#   SHIELD_TERMS="pricing,margin" audit.sh dist   (business terms that should not reach the client)
#
# Exit codes: 2 = at least one CRITICAL (block the release), 1 = WARNING only, 0 = clean.
set -u
TARGET=${1:?"usage: audit.sh <folder|file|https://url>"}
TERMS=${SHIELD_TERMS:-}
TMP=$(mktemp -d "${TMPDIR:-/tmp}/shield.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
CRIT=0; WARN=0

critical() { echo "CRITICAL $*"; CRIT=$((CRIT+1)); }
warning()  { echo "WARNING  $*"; WARN=$((WARN+1)); }
ok()       { echo "ok       $*"; }
mask()     { sed -E 's/(.{10}).{4,}/\1…/'; }  # never print a whole secret

TEXT=(--include='*.js' --include='*.mjs' --include='*.cjs' --include='*.html' --include='*.json'
       --include='*.map' --include='*.bundle' --include='*.jsbundle' --include='*.plist' --include='*.xml'
       --include='*.txt' --include='*.env' --include='.env*')

# ---------- URL mode: what the live site serves ----------
audit_url() {
  local base=${1%/} page="$TMP/index.html" n=0
  curl -sSL -A "Mozilla/5.0 blindagem-audit" -o "$page" "$base/" || { critical "could not open $base"; return; }
  mkdir -p "$TMP/site"
  local srcs; srcs=$(grep -oE '<script[^>]+src="[^"]+"' "$page" | sed -E 's/.*src="([^"]+)".*/\1/')
  for s in $srcs; do
    case "$s" in http*) u=$s ;; //*) u="https:$s" ;; /*) u="$base$s" ;; *) u="$base/$s" ;; esac
    n=$((n+1)); local f="$TMP/site/$n.js"
    curl -sSL -o "$f" "$u" || continue
    local mapref; mapref=$(tail -c 400 "$f" | grep -oE 'sourceMappingURL=[^ *]+' | cut -d= -f2)
    local mapurl
    if [ -n "$mapref" ]; then case "$mapref" in http*) mapurl=$mapref ;; data:*) critical "inline source map embedded in $u"; continue ;; *) mapurl="${u%/*}/$mapref" ;; esac
    else mapurl="$u.map"; fi
    if curl -sSL "$mapurl" 2>/dev/null | head -c 200000 | grep -q '"sourcesContent"'; then
      critical "public source map with source code: $mapurl"
    fi
  done
  ok "$n scripts downloaded from $base"
  curl -sSL "$base/asset-manifest.json" 2>/dev/null | grep -q '\.map"' && critical "$base/asset-manifest.json lists the source maps"
  curl -sSL "$base/.git/HEAD" 2>/dev/null | grep -q '^ref:' && critical "git repository exposed at $base/.git/"
  curl -sSL "$base/.env" 2>/dev/null | grep -qE '^[A-Z_]+=' && critical ".env file exposed at $base/.env"
  for p in swagger swagger.json api-docs api/docs docs/api openapi.json graphql; do
    local code; code=$(curl -s -o /dev/null -w '%{http_code}' "$base/$p")
    [ "$code" = 200 ] && warning "API docs/introspection publicly reachable: $base/$p"
  done
  audit_dir "$TMP/site"
}

# ---------- file/folder mode: the artifact that ships ----------
audit_dir() {
  local d=$1
  local nmaps; nmaps=$(find "$d" -type f -name '*.map' | wc -l | tr -d ' ')
  if [ "$nmaps" -gt 0 ]; then
    critical "$nmaps source maps in the artifact (they rebuild the original source): $(find "$d" -type f -name '*.map' | head -3 | sed "s#$d/##" | tr '\n' ' ')"
  else ok "no .map files"; fi
  local nref; nref=$(grep -rlE 'sourceMappingURL=' "$d" --include='*.js' --include='*.mjs' 2>/dev/null | wc -l | tr -d ' ')
  [ "$nref" -gt 0 ] && warning "$nref files still reference a source map (sourceMappingURL); if the .map is on the server, it leaks"

  # secrets (case-sensitive so base64 noise does not match)
  local pat='AKIA[0-9A-Z]{16}|-----BEGIN ([A-Z]+ )?PRIVATE KEY|sk-(or-v1-|ant-|proj-)?[A-Za-z0-9_-]{24,}|sk_live_[0-9A-Za-z]{16,}|rk_live_[0-9A-Za-z]{16,}|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|xox[baprs]-[A-Za-z0-9-]{10,}|(postgres(ql)?|mysql|mongodb(\+srv)?|redis|amqp)://[^:/ "]+:[^@/ "]+@|"private_key": *"|"type": *"service_account"'
  local hits; hits=$(grep -rIoE "$pat" "$d" "${TEXT[@]}" 2>/dev/null | sort -u)
  if [ -n "$hits" ]; then
    critical "secrets in the artifact:"; echo "$hits" | head -10 | sed "s#$d/##" | mask | sed 's/^/           /'
  else ok "no server-side secrets"; fi
  local pub; pub=$(grep -rIoE 'AIza[0-9A-Za-z_-]{35}' "$d" "${TEXT[@]}" 2>/dev/null | sort -u | wc -l | tr -d ' ')
  [ "$pub" -gt 0 ] && warning "$pub Google/Firebase key(s) (AIza…): fine only if public by design and restricted by domain/app"
  local jwt; jwt=$(grep -rIoE 'eyJ[A-Za-z0-9_-]{15,}\.eyJ[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{10,}' "$d" "${TEXT[@]}" 2>/dev/null | sort -u | wc -l | tr -d ' ')
  [ "$jwt" -gt 0 ] && warning "$jwt hard-coded JWT(s) (make sure none is a service key, e.g. Supabase service_role)"

  # internal addresses
  local intern; intern=$(grep -rIhoE 'https?://(localhost|127\.0\.0\.1|10\.[0-9]+\.[0-9]+\.[0-9]+|192\.168\.[0-9]+\.[0-9]+|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]+\.[0-9]+|[a-z0-9.-]*(staging|homolog|hml|internal|dev)\.[a-z0-9.-]+)(:[0-9]+)?' "$d" --include='*.js' --include='*.mjs' --include='*.html' --include='*.json' --include='*.bundle' --include='*.jsbundle' 2>/dev/null | sort -u)
  [ -n "$intern" ] && warning "internal/staging URLs in the artifact: $(echo "$intern" | head -6 | tr '\n' ' ')"

  # AI prompts and business terms
  local prompts; prompts=$(grep -rIlE 'You are an? |Você é (um|uma|o|a) |Voce e (um|uma) |systemPrompt|system_prompt|role: *["'"'"']system' "$d" --include='*.js' --include='*.mjs' --include='*.bundle' --include='*.jsbundle' 2>/dev/null | head -5)
  [ -n "$prompts" ] && warning "looks like an AI prompt shipped to the client: $(echo "$prompts" | sed "s#$d/##" | tr '\n' ' ')"
  if [ -n "$TERMS" ]; then
    IFS=',' read -ra list <<< "$TERMS"
    for t in "${list[@]}"; do
      local c; c=$(grep -rIoF "$t" "$d" --include='*.js' --include='*.mjs' --include='*.bundle' --include='*.jsbundle' 2>/dev/null | wc -l | tr -d ' ')
      [ "$c" -gt 0 ] && warning "business term \"$t\" appears $c time(s) in client code"
    done
  fi

  # debug leftovers
  local logs; logs=$(grep -rIoE 'console\.(log|debug)\(|debugger;' "$d" --include='*.js' --include='*.mjs' 2>/dev/null | wc -l | tr -d ' ')
  [ "$logs" -gt 20 ] && warning "$logs console.log/debugger calls in the build (drop them in production builds)"

  # minification: a large file with short lines is readable code
  local readable=""
  while IFS= read -r f; do
    local stats; stats=$(awk '{n++; s+=length($0)} END {if (n) printf "%d %d", n, s/n}' "$f")
    local lines=${stats% *} avg=${stats#* }
    [ "${lines:-0}" -gt 300 ] && [ "${avg:-999}" -lt 120 ] && readable="$readable ${f#$d/}"
  done < <(find "$d" -type f \( -name '*.js' -o -name '*.mjs' \) -size +20k -not -path '*/node_modules/*')
  [ -n "$readable" ] && warning "files that look unminified (or carry long templates):$(echo "$readable" | tr ' ' '\n' | head -5 | tr '\n' ' ')"

  # React Native: the bundle should be Hermes bytecode
  while IFS= read -r b; do
    if [ "$(od -An -tx1 -N4 "$b" | tr -d ' \n')" = "c61fbc03" ]; then ok "Hermes bytecode bundle: ${b#$d/}"
    else warning "plain-text React Native bundle (enable Hermes): ${b#$d/}"; fi
  done < <(find "$d" -type f \( -name 'main.jsbundle' -o -name 'index.android.bundle' -o -name '*.hbc' \))
}

# ---------- entry point ----------
case "$TARGET" in
  http://*|https://*) audit_url "$TARGET" ;;
  *)
    [ -e "$TARGET" ] || { echo "not found: $TARGET"; exit 2; }
    if [ -d "$TARGET" ]; then audit_dir "$(cd "$TARGET" && pwd)"
    else
      case "$TARGET" in
        *.zip|*.crx|*.xpi|*.apk|*.ipa|*.aab) unzip -qq -o "$TARGET" -d "$TMP/x" 2>/dev/null || true; audit_dir "$TMP/x" ;;
        *.asar) npx -y @electron/asar extract "$TARGET" "$TMP/x" >/dev/null 2>&1 || { critical "could not extract the asar"; }; audit_dir "$TMP/x" ;;
        *) mkdir -p "$TMP/x" && cp "$TARGET" "$TMP/x/" && audit_dir "$TMP/x" ;;
      esac
    fi ;;
esac

echo
echo "result: $CRIT critical, $WARN warning(s)"
[ $CRIT -gt 0 ] && exit 2
[ $WARN -gt 0 ] && exit 1
exit 0
