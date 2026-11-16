# Hetzner Cloud VPS Deployment Guide (Docker Compose + Caddy + PostgreSQL)

This guide deploys **DailyMeals** cleanly onto a fresh **Hetzner Cloud** VPS using [`compose.production.yml`](../compose.production.yml), running Rails 8 + Puma (`web`), PostgreSQL 16 (`db`), and Caddy 2 (`caddy`) on ports `80`/`443`.

---

## 1. Recommended Hetzner Cloud Server Specs

- **Type**: Shared vCPU **CX22** (2 vCPU, 4 GB RAM, 40 GB NVMe — Intel/AMD x86) or **CAX11** (2 vCPU, 4 GB RAM, 40 GB NVMe — ARM64)
- **Location**: `ash` (Ashburn, VA) or `hil` (Hillsboro, OR) if accessing from the Americas, or `nbg1` / `fsn1` (EU)
- **Image**: **Ubuntu 24.04 LTS**
- **SSH Key**: Add your local SSH public key (`~/.ssh/id_ed25519.pub` or `~/.ssh/id_rsa.pub`) during server creation in the Hetzner Cloud Console

---

## 2. Bootstrap the Fresh VPS

SSH into the new server using its public IPv4 (`<VPS_IP>`):

```bash
ssh root@<VPS_IP>
```

Download and run the idempotent bootstrap script:

```bash
curl -fsSL https://raw.githubusercontent.com/DixonGarcia/daily_meals/main/deploy/hetzner-bootstrap.sh -o hetzner-bootstrap.sh
bash hetzner-bootstrap.sh
```

The script automatically:
1. Installs Docker Engine & Docker Compose plugin.
2. Creates a 2 GB swapfile (prevents out-of-memory errors while building Ruby gems & precompiling assets).
3. Enables UFW firewall allowing only ports `22`, `80`, and `443`.
4. Clones `DixonGarcia/daily_meals` into `/opt/daily_meals` and generates `/opt/daily_meals/.env.production` with random PostgreSQL and `SECRET_KEY_BASE` credentials.

---

## 3. Set Your App Passwords & Start DailyMeals (IP-Only Mode)

Edit `/opt/daily_meals/.env.production`:

```bash
nano /opt/daily_meals/.env.production
```

Replace the two placeholders:
- `APP_ACCESS_PASSWORD=...` (your private login password for `/session/new`)
- `GEMINI_API_KEY=...` (your Google Gemini key)

Keep `SITE_ADDRESS=:80` and `FORCE_SSL=false` while accessing via raw IP (`http://<VPS_IP>`), then build and boot the stack:

```bash
cd /opt/daily_meals
docker compose -f compose.production.yml up -d --build
```

Verify containers and healthcheck:

```bash
docker compose -f compose.production.yml ps
curl -i http://127.0.0.1/up
```

Open `http://<VPS_IP>` in Chrome/Safari on your phone or desktop and log in with `APP_ACCESS_PASSWORD`.

---

## 4. Upgrading to Automatic HTTPS When You Add a Domain

1. Create an `A` DNS record pointing your domain (e.g., `meals.yourdomain.com`) to `<VPS_IP>`.
2. Edit `/opt/daily_meals/.env.production`:
   ```env
   SITE_ADDRESS=meals.yourdomain.com
   FORCE_SSL=true
   ```
3. Recreate Caddy and Rails with the updated environment:
   ```bash
   cd /opt/daily_meals
   docker compose -f compose.production.yml up -d
   ```

Caddy automatically obtains and renews a free Let's Encrypt TLS certificate, and Rails enables HSTS + `Secure` cookies.

---

## 5. Day-2 Operations

- **Deploy new commits from `main`**:
  ```bash
  cd /opt/daily_meals && git pull --ff-only && docker compose -f compose.production.yml up -d --build
  ```
  (`bin/docker-entrypoint` runs `./bin/rails db:prepare` automatically on container boot.)
- **Tail application logs**:
  ```bash
  docker compose -f compose.production.yml logs -f web
  ```
- **Run a PostgreSQL backup**:
  ```bash
  docker compose -f compose.production.yml exec -T db pg_dump -U daily_meals daily_meals_production > backup_$(date +%F).sql
  ```
