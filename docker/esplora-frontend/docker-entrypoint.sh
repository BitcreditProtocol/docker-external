#!/bin/sh
set -eu

: "${ESPLORA_FLAVOR:=bitcoin-mainnet}"
: "${ELECTRS_HTTP_URL:=http://electrs:3000}"
: "${ESPLORA_SERVER_NAME:=_}"

validate_server_name() {
  case "$1" in
    _|*[!A-Za-z0-9._*-]*|'')
      [ "$1" = "_" ] && return 0
      ;;
    *)
      return 0
      ;;
  esac

  echo "ESPLORA_SERVER_NAME must be _ or a single nginx server_name token using only letters, digits, dot, dash, underscore, and *: $1" >&2
  exit 1
}

validate_http_url() {
  case "$1" in
    http://*|https://*)
      ;;
    *)
      echo "ELECTRS_HTTP_URL must start with http:// or https://: $1" >&2
      exit 1
      ;;
  esac

  if [ "$1" = "http://" ] || [ "$1" = "https://" ]; then
    echo "ELECTRS_HTTP_URL must include a host: $1" >&2
    exit 1
  fi

  if ! printf '%s' "$1" | grep -Eq '^https?://[A-Za-z0-9._~:/?&=,+%@#-]+$'; then
    echo "ELECTRS_HTTP_URL contains unsupported characters: $1" >&2
    exit 1
  fi
}

default_base_href() {
  case "$1" in
    bitcoin-mainnet) printf '/\n' ;;
    bitcoin-testnet) printf '/testnet/\n' ;;
    bitcoin-testnet4) printf '/testnet4/\n' ;;
    bitcoin-signet) printf '/signet/\n' ;;
    bitcoin-regtest) printf '/regtest/\n' ;;
    *)
      return 1
      ;;
  esac
}

if ! DEFAULT_BASE_HREF="$(default_base_href "${ESPLORA_FLAVOR}")"; then
  echo "Unsupported ESPLORA_FLAVOR: ${ESPLORA_FLAVOR}" >&2
  exit 1
fi

ESPLORA_BASE_HREF="${ESPLORA_BASE_HREF:-${DEFAULT_BASE_HREF}}"
ELECTRS_HTTP_URL="${ELECTRS_HTTP_URL%/}"

validate_server_name "${ESPLORA_SERVER_NAME}"
validate_http_url "${ELECTRS_HTTP_URL}"

case "${ESPLORA_BASE_HREF}" in
  /)
    API_PREFIX="/api/"
    INDEX_FALLBACK="/index.html"
    BASE_PATH_NO_SLASH=""
    ;;
  /*/)
    API_PREFIX="${ESPLORA_BASE_HREF}api/"
    INDEX_FALLBACK="${ESPLORA_BASE_HREF}index.html"
    BASE_PATH_NO_SLASH="${ESPLORA_BASE_HREF%/}"
    ;;
  *)
    echo "ESPLORA_BASE_HREF must be / or start and end with /: ${ESPLORA_BASE_HREF}" >&2
    exit 1
    ;;
esac

case "${ESPLORA_BASE_HREF}" in
  *[!A-Za-z0-9._~/-]*)
    echo "ESPLORA_BASE_HREF contains unsupported characters: ${ESPLORA_BASE_HREF}" >&2
    exit 1
    ;;
esac

STATIC_DIR="/srv/esplora/static/${ESPLORA_FLAVOR}"
DOCROOT="/usr/share/nginx/html"

if [ ! -d "${STATIC_DIR}" ]; then
  echo "Static assets for ${ESPLORA_FLAVOR} are missing at ${STATIC_DIR}" >&2
  exit 1
fi

rm -rf "${DOCROOT:?}"/*

if [ "${ESPLORA_BASE_HREF}" = "/" ]; then
  cp -a "${STATIC_DIR}"/. "${DOCROOT}/"
  APP_LOCATION_BLOCK=$(cat <<'EOF'
    location / {
        try_files $uri $uri/ /index.html;
    }
EOF
)
  ROOT_REDIRECT_BLOCK=""
else
  mkdir -p "${DOCROOT}${ESPLORA_BASE_HREF}"
  cp -a "${STATIC_DIR}"/. "${DOCROOT}${ESPLORA_BASE_HREF}"
  APP_LOCATION_BLOCK=$(cat <<EOF
    location = ${BASE_PATH_NO_SLASH} {
        return 302 ${ESPLORA_BASE_HREF};
    }

    location ^~ ${ESPLORA_BASE_HREF} {
        try_files \$uri \$uri/ ${INDEX_FALLBACK};
    }
EOF
)
  ROOT_REDIRECT_BLOCK=$(cat <<EOF
    location = / {
        return 302 ${ESPLORA_BASE_HREF};
    }
EOF
)
fi

cat > /etc/nginx/conf.d/default.conf <<EOF
server {
    listen 80;
    server_name ${ESPLORA_SERVER_NAME};
    server_tokens off;
    root ${DOCROOT};

    location = /healthz {
        access_log off;
        add_header Content-Type text/plain;
        return 200 'ok';
    }

    location = /favicon.ico {
        return 302 ${ESPLORA_BASE_HREF}img/favicon.png;
    }

${ROOT_REDIRECT_BLOCK}
    location ^~ ${API_PREFIX} {
        proxy_pass ${ELECTRS_HTTP_URL}/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        add_header Cache-Control "no-store" always;
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Expose-Headers "x-total-results" always;
    }

${APP_LOCATION_BLOCK}
}
EOF

exec "$@"
