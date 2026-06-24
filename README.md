# Code9 Group — Local WordPress Stack

A self-hosted, containerized restore of the `code9group.org` website (originally
hosted on Hostinger). The site itself is unchanged WordPress — Aveit theme +
Elementor Pro — so the layout is identical to the live site. Only the *hosting*
is modernized: everything runs in pinned Docker containers and is reproducible
with one command.

## Stack

| Container  | Image                       | Role                                   |
|------------|-----------------------------|----------------------------------------|
| `nginx`    | nginx:stable-alpine         | Web server / reverse proxy (port 8082) |
| `wordpress`| custom (wordpress:php8.2-fpm)| PHP-FPM 8.2 runtime + phpredis        |
| `db`       | mariadb:11.8                | Database (matches original server)     |
| `redis`    | redis:7-alpine              | Optional object cache                  |
| `wpcli`    | wordpress:cli-php8.2        | One-off management commands (on demand)|

## URLs

- **Site:**  http://localhost:8082
- **Admin:** http://localhost:8082/wp-admin

> The host port is `8082` (80/8080/8081 were busy on this machine). To change it,
> edit `HTTP_PORT` and `SITE_URL` in `.env`, update `WP_HOME`/`WP_SITEURL` in
> `wordpress/wp-config.php`, then run a `wp search-replace` for the old→new URL.

## Everyday commands

```bash
make up            # start everything
make down          # stop everything (data is preserved)
make ps            # container status
make logs          # follow logs
make backup        # dump DB + archive wp-content into ./backups/
make flush-cache   # regenerate Elementor CSS + flush caches
make wpcli CMD="plugin list"        # any wp-cli command
make reset-admin-pass USER=Code-9-Group PASS=YourNewPass
```

Run `make help` for the full list.

## Directory layout

```
site/
├── docker-compose.yml     # the stack definition
├── .env                   # ports, DB creds, image versions
├── Makefile               # management shortcuts
├── nginx/default.conf     # web server vhost
├── php/Dockerfile         # PHP image (adds phpredis)
├── php/uploads.ini        # upload/memory limits
├── db/01-dump.sql.gz      # imported automatically on first boot
├── backups/               # output of `make backup`
└── wordpress/             # the WordPress files (themes, plugins, uploads)
```

## What was changed from the raw Hostinger backup

These are environment fixes only — no design/content was altered:

1. **`wp-config.php`** — DB host pointed at the `db` container; added local
   `WP_HOME`/`WP_SITEURL`, `WP_ENVIRONMENT_TYPE=local`, and Redis host.
2. **URLs** — `https://code9group.org` → `http://localhost:8082` across the
   database (serialization-safe, via wp-cli; emails like `sales@code9group.org`
   were intentionally left untouched).
3. **Host-specific plugins deactivated** — `really-simple-ssl` (forces HTTPS),
   `litespeed-cache` (LiteSpeed-only), `hostinger`, `hostinger-easy-onboarding`,
   `all-in-one-wp-migration`.
4. **Hostinger mu-plugins** moved to `wp-content/mu-plugins-disabled/`.

## Admin accounts

| Username        | Email                |
|-----------------|----------------------|
| `Code-9-Group`  | mindsonco@gmail.com  |
| `msfmfq@gmail.com` | msfmfq@gmail.com  |

If you don't know the password, set a new one:
`make reset-admin-pass USER=Code-9-Group PASS=YourNewPass`

## CI/CD — automatic deploys

Infra/code changes auto-deploy to this server via **GitHub Actions + a
self-hosted runner**.

- **Repo:** https://github.com/aliugoki/code9-site (private)
- **Flow:** `git push origin main` → GitHub Actions → self-hosted runner on this
  box → `git reset --hard` the live dir to the pushed commit → rebuild image →
  `docker compose up -d` + force-recreate nginx/wordpress → health-check
  `http://localhost:8082`.
- **Workflow:** `.github/workflows/deploy.yml` (also runnable on demand via the
  Actions tab → "Deploy" → Run workflow, or `gh workflow run deploy.yml`).

### What auto-deploys vs what doesn't

| Change type | Auto-deploys? |
|---|---|
| docker-compose, nginx vhost, php ini, Dockerfile, workflow | ✅ yes, on push |
| Custom code committed to the repo | ✅ yes, on push |
| WordPress content/design (pages, Elementor, posts, media) | ❌ no — these live in the DB/uploads and take effect instantly in wp-admin; they are not in git |

### Runner as a service (survives reboots)

The runner is registered as `code9-server` (label `code9`). Install it as a
systemd service once:

```bash
cd /home/meta/actions-runner
sudo ./svc.sh install meta
sudo ./svc.sh start
sudo ./svc.sh status
```

Manage later with `sudo ./svc.sh stop|start|status`.

### Typical change workflow

```bash
cd /home/meta/code9/site
# edit docker-compose.yml / nginx/ / php/ ...
git add -A && git commit -m "infra: <what changed>"
git push origin main          # deploy runs automatically; watch with:
gh run watch
```

## Notes

- RSS feeds return an error on purpose — the original site's "Disable Everything"
  plugin disables them. This matches the live site.
- The Google Fonts CSS under `wp-content/uploads/elementor/google-fonts/` still
  references the live domain for a couple of font files; they regenerate locally
  on demand and don't affect layout. Run `make flush-cache` to refresh if needed.
- To enable the Redis object cache, install/activate the "Redis Object Cache"
  plugin in wp-admin — the connection (`WP_REDIS_HOST=redis`) is already wired up.
```
