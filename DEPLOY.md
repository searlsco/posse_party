# Docker deployment guide

This app ships a single Docker Compose stack designed to run on any Linux VM with Docker + Docker Compose v2 installed. The same commands apply on DigitalOcean, Hetzner, Linode/Akamai, AWS Lightsail/EC2, or any other Docker-capable host.

## One-time setup (curl-and-go)

On a fresh VM with Docker + Compose installed (see these [quick-start guides for various hosting services](#provider-quick-starts)), just run:

```bash
APP_HOST=your.domain /bin/bash -c "$(curl -fsSL https://posseparty.com/setup.sh)"
```

There are a number of [env vars to consider](#configuring-your-installation), but the two you might want to set before running the above command are:

- `APP_HOST` sets the public host for HTTPS via Caddy/Let’s Encrypt and Rails URL helpers (IP addresses are OK, e.g., `192.168.1.24`). If omitted, Caddy still serves plain HTTP on :80 (IP access).
- `APP_PRIVATE_HOST` (defaults to `false`) keeps Caddy from attempting a public certificate for private hosts/IPs and tells Rails’ host auto-detection to pick the first non-loopback address (useful when running on a NAS or other LAN-only host). When `true`, `FORCE_SSL` is automatically disabled.

### What gets deployed

- **web**: Rails app (Puma) with static assets served in-container.
- **worker**: Solid Queue via `./script/worker`.
- **db**: Postgres with healthcheck and a persisted `db_data` volume.
- **proxy**: TLS-terminating reverse proxy on 80/443, proxying to `web:3000` for `APP_HOST`.
- **migrate**: one-shot `./script/release` (runs Rails migrations) that must succeed before other services start.

All of this is defined in `docker-compose.yml` and wired so that `web`/`worker` wait for a healthy database and successful migrations before booting.

## Provider quick-starts

### DigitalOcean Droplet

1. Create a Droplet from the [Docker Marketplace image](https://marketplace.digitalocean.com/apps/docker)
2. SSH (`ssh root@ip`).
3. Follow “One-time setup”.

### Hetzner Cloud
1. Create a server using the **Docker CE** app image (Ubuntu with Docker + Compose).
2. SSH (`ssh root@ip`).
3. Run the setup commands.

### Linode / Akamai
1. Use the **Docker** Marketplace app or install Docker + Compose plugin on Ubuntu (`sudo apt install docker-compose-plugin`).
2. SSH (`ssh root@ip`).
3. Run the setup commands.

### AWS Lightsail or small EC2
1. Launch Ubuntu 22.04/24.04.
2. Install Docker and the Compose plugin using the official Linux instructions.
3. SSH (`ssh ubuntu@ip`).
4. Run the setup commands.

### Anywhere else
If Docker Engine and the `docker compose` plugin are present, the same `setup.sh` → `bin/start` flow works.

## Configuring your installation

POSSE Party is configured via environment variables, which can be edited on your server using whatever text editor is available in the `.env` file. If you ran the above setup command, it will be in a subdirectory named `posse_party`

```bash
nano posse_party/.env
```

Variables you might be interested in setting:

- `APP_HOST` (hostname or IP, e.g., `myapp.posseparty.com` or `192.168.1.24`; if provided, app will be served via HTTPS unless `APP_PRIVATE_HOST=true` disables FORCE_SSL)
- `APP_PRIVATE_HOST` — set to `true` when deploying to a private hostname/IP so Caddy skips public cert attempts, Rails prefers the first non-loopback address for URL helpers, and `FORCE_SSL` is automatically disabled
- `FORCE_SSL` — Redirects HTTP requests to HTTPS (defaults to `true` if `APP_HOST` is set; forced to `false` when `APP_PRIVATE_HOST=true`)
- `RAILS_ASSET_HOST` — CDN host for static assets (e.g., `https://cdn.example.com`)
- `SECRET_KEY_BASE` (set by default with `openssl rand -hex 64`)
- Email delivery is optional, but required to send login and transactional emails:
- `MAIL_PROVIDER` (amazon_ses | resend | mailgun | postmark | sendgrid | brevo | mailjet | smtp). Each requires a different set of environment variables (see [docs/mail.md](/docs/mail.md))
- `MAIL_FROM_ADDRESS` (e.g. `possy@possyparty.com`)

Whenever you change these settings, you'll need to restart the server, which you can do by running:

```
./posse_party/bin/restart
```

## Maintenance scripts

For your convenience, POSSE Party's setup command leaves behind a handful of scripts for managing your install.

You'll find these scripts wherever you ran the setup script in a `posse_party` subdirectory, so you may need to first change to that directory:

```bash
cd posse_party
```

### Starting the server

```bash
./bin/start
```

### Stopping the server

```bash
./bin/stop
```

### Upgrading to a new release of POSSE Party

```bash
./bin/upgrade
```

### Debugging your installation

You can run the production Rails console with `bin/console`:

```bash
./bin/console
```

The Postgres CLI is available via `bin/psql` (any args will be forwarded):

```bash
./bin/psql
```

You can also tail the production server logs with `bin/log`. By default, this will pass `-n 200 -f`, but you can pass your own arguments to override that:

```bash
./bin/log
```

### Backing up the database

```sh
./bin/backup
```

Unless an argument is specified, a timestamped SQL backup will be saved to `backups/`.

### Restoring the database from a backup

```sh
./bin/stop
# Will ask you to confirm, pass --confirm to override:
./bin/drop_database
./bin/restore backups/2025-12-25-12-00-00-posse-party-backup.sql
./bin/start
```

## Automation

### Automatically running and storing backups

On my Mac, I have a nightly backup job that runs this script, which lives `~bin/backup_posse_party`. My backup disk is named after the Orlando Magic mascot, [Stuff](https://en.wikipedia.org/wiki/Stuff_the_Magic_Dragon):

```bash
#!/usr/bin/env bash

set -euo pipefail

REMOTE_USER="possy"
REMOTE_HOST="app.posseparty.com"
REMOTE_ADDRESS="${REMOTE_USER}@${REMOTE_HOST}"
REMOTE_DIRECTORY="~/posse_party"
LOCAL_DIRECTORY="${1:-/Volumes/stuff/backups/posse_party}"

echo "Running backup of POSSE Party database"
ssh "$REMOTE_ADDRESS" "cd $REMOTE_DIRECTORY && ./bin/backup"

echo "Syncing backups of POSSE Party database"
mkdir -p "$LOCAL_DIRECTORY/database"
rsync -av --ignore-existing "$REMOTE_ADDRESS:$REMOTE_DIRECTORY/backups/" "$LOCAL_DIRECTORY/database"
```

## Starting over

If you find yourself stuck and just want a fresh start, here's how to do it:

### Keep your data and configuration intact

To recreate containers without wiping data:

```bash
cd posse_party
docker compose down
docker volume rm posse_party_proxy_data # Resets TLS/SSL cache
docker compose up -d
```

### Deleting your database and configuration

To start over completely, deleting your database before recreating the containers:

```bash
cd posse_party
docker compose down -v
cd ..
rm -rf posse_party
APP_HOST=your.domain /bin/bash -c "$(curl -fsSL https://posseparty.com/setup.sh)"
```
