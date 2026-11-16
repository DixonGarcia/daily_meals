# Hetzner Cloud VPS Deployment Guide (Multi-App Subpath `/daily_meals` + Caddy + PostgreSQL)

This guide deploys **DailyMeals** onto a **Hetzner Cloud** VPS using [`compose.production.yml`](../compose.production.yml) so your main domain (`yourdomain.com`) stays free for your personal website and other services (such as a Python chatbot), while **`https://yourdomain.com/daily_meals`** routes directly to DailyMeals.

---

## 1. Configure GoDaddy DNS

In GoDaddy DNS Management for your domain:

1. Edit (or create) the root **`A`** record:
   - **Type**: `A`
   - **Name**: `@`
   - **Value**: `<YOUR_HETZNER_VPS_IP>`
   - **TTL**: `600` seconds (or shortest available)
2. Remove any GoDaddy parking/forwarding `A` records pointing to other IPs on `@`.
3. Optional: add a **`CNAME`** record `www` -> `yourdomain.com` (or `A` record `www` -> `<YOUR_HETZNER_VPS_IP>`).

---

## 2. Bootstrap the Fresh Hetzner VPS (Ubuntu 24.04)

```bash
ssh root@<YOUR_HETZNER_VPS_IP>
curl -fsSL https://raw.githubusercontent.com/DixonGarcia/daily_meals/main/deploy/hetzner-bootstrap.sh -o hetzner-bootstrap.sh
bash hetzner-bootstrap.sh
```

This installs Docker + Compose, enables UFW (`22`, `80`, `443`), creates a 2 GB swapfile, clones the repo into `/opt/daily_meals`, and generates `/opt/daily_meals/.env.production` with `RAILS_RELATIVE_URL_ROOT=/daily_meals` and random PostgreSQL/`SECRET_KEY_BASE` secrets.

---

## 3. Configure `.env.production` and Start

```bash
nano /opt/daily_meals/.env.production
```

Update:
- `SITE_ADDRESS=yourdomain.com` (once GoDaddy DNS propagates to your VPS IP)
- `FORCE_SSL=true` (automatic Let's Encrypt HTTPS via Caddy)
- `APP_ACCESS_PASSWORD=your-strong-password`
- `GEMINI_API_KEY=your-gemini-api-key`

*(If DNS has not propagated yet, temporarily keep `SITE_ADDRESS=:80` and `FORCE_SSL=false` and visit `http://<YOUR_HETZNER_VPS_IP>/daily_meals`.)*

Start the stack:

```bash
cd /opt/daily_meals
docker compose -f compose.production.yml up -d --build
```

Verify healthcheck and access:

```bash
docker compose -f compose.production.yml ps
curl -i http://127.0.0.1/daily_meals/up
```

Open **`https://yourdomain.com/daily_meals`** in your browser or phone.

---

## 4. Adding Your Main Website & Python Chatbot on the Same VPS

[`compose.production.yml`](../compose.production.yml) exposes the shared Docker network `daily_meals_proxy`.

When you deploy your website or Python chatbot containers on the same VPS:
1. Attach them to the external network `daily_meals_proxy` in their compose file:
   ```yaml
   networks:
     daily_meals_proxy:
       external: true
   ```
2. Update `/opt/daily_meals/deploy/Caddyfile` to route `/` to your website container and e.g. `/chatbot*` to your Python bot container, then reload Caddy:
   ```bash
   docker compose -f /opt/daily_meals/compose.production.yml exec caddy caddy reload --config /etc/caddy/Caddyfile
   ```

---

## 5. Day-2 Operations

- **Deploy updates from `main`**:
  ```bash
  cd /opt/daily_meals && git pull --ff-only && docker compose -f compose.production.yml up -d --build
  ```
- **Tail Rails logs**:
  ```bash
  docker compose -f /opt/daily_meals/compose.production.yml logs -f web
  ```
- **PostgreSQL backup**:
  ```bash
  docker compose -f /opt/daily_meals/compose.production.yml exec -T db pg_dump -U daily_meals daily_meals_production > backup_$(date +%F).sql
  ```
