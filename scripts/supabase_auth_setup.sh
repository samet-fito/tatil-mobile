#!/usr/bin/env bash
# Supabase Auth yapılandırması (Management API)
# Token: https://supabase.com/dashboard/account/tokens
#
# Kullanım:
#   cp scripts/.env.supabase.local.example scripts/.env.supabase.local
#   # dosyayı doldur
#   ./scripts/supabase_auth_setup.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT_DIR/scripts/.env.supabase.local"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

PROJECT_REF="${SUPABASE_PROJECT_REF:-dcktytulwlqlwpzyxdst}"
MOBILE_REDIRECT="${MOBILE_REDIRECT:-io.supabase.tatilbulucu://login-callback}"
WEB_CALLBACK="https://${PROJECT_REF}.supabase.co/auth/v1/callback"

if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
  echo "❌ SUPABASE_ACCESS_TOKEN eksik."
  echo "   https://supabase.com/dashboard/account/tokens adresinden alın."
  echo "   scripts/.env.supabase.local dosyasına ekleyin."
  exit 1
fi

API="https://api.supabase.com/v1/projects/${PROJECT_REF}"

echo "→ Mevcut auth ayarları okunuyor..."
curl -sS -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
  "${API}/config/auth" | python3 -c "
import json,sys
d=json.load(sys.stdin)
keys=[k for k in d if k.startswith('external_') and k.endswith('_enabled')]
print('Provider durumu:')
for k in sorted(keys):
    print(f'  {k}: {d.get(k)}')
print('uri_allow_list:', d.get('uri_allow_list',''))
" || true

echo ""
echo "→ Auth ayarları güncelleniyor..."

# Apple secret yoksa .p8 dosyasından üret
if [[ -z "${APPLE_SECRET:-}" ]] && [[ -n "${APPLE_P8_KEY_PATH:-}" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    echo "→ Apple client secret üretiliyor (.p8)..."
    export APPLE_TEAM_ID APPLE_KEY_ID APPLE_SERVICES_ID APPLE_P8_KEY_PATH
    APPLE_SECRET="$(python3 "$ROOT_DIR/scripts/generate_apple_secret.py")"
    export APPLE_SECRET
  fi
fi

PAYLOAD=$(SUPABASE_PROJECT_REF="$PROJECT_REF" MOBILE_REDIRECT="$MOBILE_REDIRECT" \
  GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-}" GOOGLE_CLIENT_SECRET="${GOOGLE_CLIENT_SECRET:-}" \
  FACEBOOK_APP_ID="${FACEBOOK_APP_ID:-}" FACEBOOK_APP_SECRET="${FACEBOOK_APP_SECRET:-}" \
  APPLE_SERVICES_ID="${APPLE_SERVICES_ID:-}" APPLE_SECRET="${APPLE_SECRET:-}" \
  APPLE_TEAM_ID="${APPLE_TEAM_ID:-}" APPLE_KEY_ID="${APPLE_KEY_ID:-}" \
  APPLE_P8_KEY_PATH="${APPLE_P8_KEY_PATH:-}" \
  python3 <<'PY'
import json, os
ref = os.environ.get("SUPABASE_PROJECT_REF", "dcktytulwlqlwpzyxdst")
mobile = os.environ.get("MOBILE_REDIRECT", "io.supabase.tatilbulucu://login-callback")
p = {
  "external_email_enabled": True,
  "mailer_autoconfirm": True,
  "site_url": mobile,
  "uri_allow_list": f"{mobile},https://{ref}.supabase.co/auth/v1/callback",
}
gid = os.environ.get("GOOGLE_CLIENT_ID", "").strip()
gsec = os.environ.get("GOOGLE_CLIENT_SECRET", "").strip()
if gid and gsec:
  p["external_google_enabled"] = True
  p["external_google_client_id"] = gid
  p["external_google_secret"] = gsec
fid = os.environ.get("FACEBOOK_APP_ID", "").strip()
fsec = os.environ.get("FACEBOOK_APP_SECRET", "").strip()
if fid and fsec:
  p["external_facebook_enabled"] = True
  p["external_facebook_client_id"] = fid
  p["external_facebook_secret"] = fsec
asid = os.environ.get("APPLE_SERVICES_ID", "").strip()
asec = os.environ.get("APPLE_SECRET", "").strip()
if asid and asec:
  p["external_apple_enabled"] = True
  p["external_apple_client_id"] = asid
  p["external_apple_secret"] = asec
print(json.dumps(p))
PY
)

curl -sS -X PATCH "${API}/config/auth" \
  -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" | python3 -m json.tool > /dev/null

echo "✓ Auth provider + redirect URL güncellendi."

if [[ -f "$ROOT_DIR/supabase/migrations/20250612_auth_profiles.sql" ]]; then
  echo "→ profiles migration uygulanıyor..."
  SQL=$(cat "$ROOT_DIR/supabase/migrations/20250612_auth_profiles.sql" | python3 -c 'import json,sys; print(json.dumps({"query": sys.stdin.read()}))')
  curl -sS -X POST "${API}/database/query" \
    -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$SQL" > /dev/null
  echo "✓ profiles tablosu hazır."
fi

echo ""
echo "Tamamlandı. Kontrol:"
echo "  https://supabase.com/dashboard/project/${PROJECT_REF}/auth/providers"
