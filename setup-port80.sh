#!/usr/bin/env bash
# Installs the host-nginx reverse proxy + hosts entry so the local site
# answers on http://code9group.org (port 80). Run with: sudo bash setup-port80.sh
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/hostproxy/code9group.org.conf"
DEST_AVAIL="/etc/nginx/sites-available/code9group.org"
DEST_ENABLED="/etc/nginx/sites-enabled/code9group.org"

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root:  sudo bash $0" >&2
  exit 1
fi

echo "==> Installing nginx vhost"
cp "$SRC" "$DEST_AVAIL"
ln -sf "$DEST_AVAIL" "$DEST_ENABLED"

echo "==> Ensuring /etc/hosts entry"
if grep -qE '^[^#]*\bcode9group\.org\b' /etc/hosts; then
  echo "    /etc/hosts already maps code9group.org — leaving as is"
else
  printf '127.0.0.1 code9group.org www.code9group.org\n' >> /etc/hosts
  echo "    added: 127.0.0.1 code9group.org www.code9group.org"
fi

echo "==> Testing nginx config"
nginx -t

echo "==> Reloading nginx"
systemctl reload nginx

echo "==> Done. The proxy is live; finish by switching the WordPress URLs."
