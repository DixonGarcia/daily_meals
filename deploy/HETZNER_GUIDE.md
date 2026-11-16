# Hetzner Cloud VPS Deployment Guide (Subdomain `meals.yourdomain.com` + Caddy + PostgreSQL)

This guide deploys **DailyMeals** onto a **Hetzner Cloud** VPS using [`compose.production.yml`](../compose.production.yml) on a dedicated subdomain (**`https://meals.yourdomain.com`**), keeping your apex domain (`yourdomain.com`) free for your personal website and separate subdomains (such as `bot.yourdomain.com`) for your Python chatbot.

---

## 1. Configure GoDaddy DNS

In GoDaddy DNS Management for your domain, create **`A`** records pointing to your Hetzner VPS IPv4 (`<YOUR_HETZNER_VPS_IP>`):

| Type | Name | Value | TTL | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `A` | `meals` | `<YOUR_HETZNER_VPS_IP>` | `600` | DailyMeals (`meals.yourdomain.com`) |
| `A` | `@` | `<YOUR_HETZNER_VPS_IP>` | `600` | Future main website (`yourdomain.com`) |
| `A` | `bot` | `<YOUR_HETZNER_VPS_IP>` | `600` | Future Python chatbot (`bot.yourdomain.com`) |

*(You can create `meals` now and add `@` / `bot` whenever you are ready to deploy those services.)*

---

## 2. Bootstrap the Fresh Hetzner VPS (Ubuntu 24.04)

```bash
ssh root@<YOUR_HETZNER_VPS_IP>
curl -fsSL https://raw.githubusercontent.com/DixonGarcia/daily_meals/main/deploy/hetzner-bootstrap.sh -o hetzner-bootstrap.sh
bash hetzner-bootstrap.sh
```

This installs Docker + Compose, enables UFW (`22`, `80`, `443`), creates a 2 GB swapfile, clones the repo into `/opt/daily_meals`, and initializes `/opt/daily_meals/.env.production` with random PostgreSQL and `SECRET_KEY_BASE` secrets.

---

## 3. Configure `.env.production` and Start

```bash
nano /opt/daily_meals/.env.production
```

Set:
- `SITE_ADDRESS=meals.yourdomain.com`
- `FORCE_SSL=true`
- `APP_ACCESS_PASSWORD=your-strong-password`
- `GEMINI_API_KEY=your-gemini-api-key`

*(If DNS has not propagated yet, temporarily keep `SITE_ADDRESS=:80` and `FORCE_SSL=false` and test at `http://<YOUR_HETZNER_VPS_IP>`.)*

Build and start the stack:

```bash
cd /opt/daily_meals
docker compose -f compose.production.yml up -d --build
```

Verify containers and healthcheck:

```bash
docker compose -f compose.production.yml ps
curl -i http://127.0.0.1:3000/up || docker compose -f compose.production.yml exec web curl -i http://127.0.0.1:3000/up
```

Open **`https://meals.yourdomain.com`** in your browser or phone.

---

## 4. Adding Your Main Website & Python Chatbot on the Same VPS

[`compose.production.yml`](../compose.production.yml) creates the shared Docker network `daily_meals_proxy`.

When you deploy your website or Python chatbot on the same VPS:
1. Attach them to the external network `daily_meals_proxy` in their compose file:
   ```yaml
   networks:
     daily_meals_proxy:
       external: true
   ```
2. Uncomment and customize the `yourdomain.com` / `bot.yourdomain.com` blocks in `/opt/daily_meals/deploy/Caddyfile`, then reload Caddy:
   ```bash
   docker compose -f /opt/daily_meals/compose.production.yml exec caddy caddy reload --config /etc/caddy/Caddyfile
   ```

Caddy automatically obtains and renews separate Let's Encrypt TLS certificates for each subdomain.

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
