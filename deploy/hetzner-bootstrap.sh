#!/usr/bin/env bash
set -euo pipefail

# Idempotent bootstrap script for Ubuntu 24.04 on a fresh Hetzner Cloud VPS.
# Installs Docker Engine + Compose plugin, configures UFW firewall (22/80/443),
# adds a 2GB swapfile for reliable Docker builds on small instances, clones/updates
# DailyMeals, and initializes .env.production with strong random secrets.

REPO_URL="${REPO_URL:-https://github.com/DixonGarcia/daily_meals.git}"
APP_DIR="${APP_DIR:-/opt/daily_meals}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run this script as root (e.g. sudo bash hetzner-bootstrap.sh)."
  exit 1
fi

echo "==> [1/5] Installing base system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y --no-install-recommends ca-certificates curl git ufw openssl

if ! command -v docker >/dev/null 2>&1; then
  echo "==> [2/5] Installing Docker Engine & Docker Compose plugin..."
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list
  apt-get update -qq
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
  echo "==> [2/5] Docker already installed, skipping."
fi

if [ ! -f /swapfile ]; then
  echo "==> [3/5] Creating 2GB swapfile for build headroom..."
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo "/swapfile none swap sw 0 0" >> /etc/fstab
else
  echo "==> [3/5] Swapfile already configured, skipping."
fi

echo "==> [4/5] Configuring UFW firewall (SSH 22, HTTP 80, HTTPS 443)..."
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "==> [5/5] Fetching DailyMeals into ${APP_DIR}..."
if [ -d "${APP_DIR}/.git" ]; then
  git -C "${APP_DIR}" pull --ff-only
else
  git clone "${REPO_URL}" "${APP_DIR}"
fi

cd "${APP_DIR}"

if [ ! -f .env.production ]; then
  PG_PASS="$(openssl rand -hex 24)"
  SECRET_KEY="$(openssl rand -hex 64)"
  cat > .env.production <<EOF
SITE_ADDRESS=:80
FORCE_SSL=false

POSTGRES_USER=daily_meals
POSTGRES_PASSWORD=${PG_PASS}
POSTGRES_DB=daily_meals_production
DATABASE_URL=postgres://daily_meals:${PG_PASS}@db:5432/daily_meals_production

RAILS_ENV=production
RAILS_LOG_LEVEL=info
SECRET_KEY_BASE=${SECRET_KEY}

APP_ACCESS_PASSWORD=CHANGE_ME_STRONG_PASSWORD
GEMINI_API_KEY=CHANGE_ME_GEMINI_API_KEY
GEMINI_MODEL=gemini-3.1-flash-lite
EOF
  chmod 600 .env.production
  echo ""
  echo "================================================================="
  echo "Created ${APP_DIR}/.env.production with random DB & Rails secrets."
  echo "NEXT STEP: Edit APP_ACCESS_PASSWORD and GEMINI_API_KEY, then start:"
  echo "  nano ${APP_DIR}/.env.production"
  echo "  cd ${APP_DIR} && docker compose -f compose.production.yml up -d --build"
  echo "================================================================="
else
  echo "${APP_DIR}/.env.production already exists; leaving untouched."
  echo "To deploy updates:"
  echo "  cd ${APP_DIR} && docker compose -f compose.production.yml up -d --build"
fi
