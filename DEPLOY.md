# Docker deployment guide

This app ships a single Docker Compose stack designed to run on any Linux VM with Docker + Docker Compose v2 installed. The same commands apply on DigitalOcean, Hetzner, Linode/Akamai, AWS Lightsail/EC2, or any other Docker-capable host.

## One-time setup (curl-and-go)

On a fresh VM with Docker + Compose installed (see these [quick-start guides for various hosting services](#provider-quick-starts)), just run:

```bash
APP_HOST=your.domain.or.ip /bin/bash -c "$(curl -fsSL https://posseparty.com/setup.sh)"
```

There are a number of [env vars to consider](#configuring-your-installation), but the two you might want to set before running the above command are:

- `APP_HOST` sets the public host for HTTPS via Caddy/Let’s Encrypt and Rails URL helpers (IP addresses are OK, e.g., `192.168.1.24`). If omitted, Caddy still serves plain HTTP on :80 (IP access).
- `APP_PRIVATE_HOST` (defaults to `false`) when true, Caddy skips public ACME certificates and uses an internal CA for TLS, and Rails will assume HTTPS is supported but will not force HTTPS unless you explicitly set `FORCE_SSL=true`.

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

- `APP_HOST` - hostname (`myapp.posseparty.com`) or IP address (`192.168.1.24`). If this isn't set, the app won't be able to generate full URLs, which are needed for transactional emails and OAuth authorization flows (e.g., LinkedIn, YouTube)
- `APP_HTTP_PORT` — host port to expose HTTP for the app (maps to container port 80, defaults to `80`)
- `APP_HTTPS_PORT` — host port to expose HTTPS for the app (maps to container port 443, defaults to `443`)
- `APP_PRIVATE_HOST` — set to `true` when deploying to a private hostname/IP so Caddy skips public ACME cert attempts and uses an internal TLS certificate; Rails will generate `https://` URLs for that host but will not force HTTPS redirects unless you explicitly set `FORCE_SSL=true`.
- `FORCE_SSL` — redirects HTTP requests to HTTPS. When unset/blank, it defaults to `true` for public HTTPS hosts and `false` when `APP_PRIVATE_HOST=true` or HTTPS is not configured.
- `RAILS_ASSET_HOST` — CDN host for static assets (e.g., `https://cdn.example.com`)
- `SECRET_KEY_BASE` (set by default with `openssl rand -hex 64`)
- Email delivery is optional, but required to send login and transactional emails:
    - `MAIL_PROVIDER` one of: `amazon_ses`, `resend`, `mailgun`, `postmark`, `sendgrid`, `brevo`, `mailjet`, `smtp`. Each requires a different set of environment variables to be configured (see [docs/mail.md](/docs/mail.md) for details)
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

### Automatically upgrading POSSE Party

By default, POSSE Party will only be updated to the latest version if you SSH into your server and run:

```bash
cd posse_party
./bin/upgrade
```

If you'd prefer to automatically fetch and deploy the latest release, here are a couple options.

#### Auto-upgrades with systemd

On most modern Linux distributions (Ubuntu, Debian, etc.), you can use a systemd timer to run the upgrade script at a fixed time each day.

Find the full directory where POSSE Party is installed:

```bash
cd posse_party
pwd
```

Note the full path printed by `pwd`; you will use it below.

Create a systemd service that runs the upgrade script. As root:

```bash
sudo nano /etc/systemd/system/posse-party-upgrade.service
```

Paste the following, replacing `/path/to/posse_party` with the directory you found above:

```ini
[Unit]
Description=POSSE Party upgrade

[Service]
Type=oneshot
WorkingDirectory=/path/to/posse_party
ExecStart=/usr/bin/env bash -lc './bin/upgrade'
```

Create a timer that runs once per night (below, we set it for 03:30 server time):

```bash
sudo nano /etc/systemd/system/posse-party-upgrade.timer
```

Paste:

```ini
[Unit]
Description=Run POSSE Party upgrade nightly

[Timer]
OnCalendar=*-*-* 03:30:00
Persistent=true

[Install]
WantedBy=timers.target
```

Reload systemd and enable the timer:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now posse-party-upgrade.timer
```

You can verify it is scheduled with:

```bash
systemctl list-timers | grep posse-party-upgrade
```

To disable automatic upgrades later:

```bash
sudo systemctl disable --now posse-party-upgrade.timer
```

#### Auto-upgrades with cron

If your server does not use systemd, you can run the upgrade once a night using cron.

Edit the crontab for the user that owns the POSSE Party install:

```bash
crontab -e
```

Add a line like this, adjusting `/path/to/posse_party` if needed:

```bash
0 3 * * * cd /path/to/posse_party && ./bin/upgrade >> ~/posse_party_upgrade.log 2>&1
```

This will attempt an upgrade every day at 03:00 and append output to `~/posse_party_upgrade.log`.

Before turning on automatic upgrades, make sure your backups are working (for example, using the backup automation from the previous section), so you can roll back if something goes wrong.

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
APP_HOST=your.domain.or.ip /bin/bash -c "$(curl -fsSL https://posseparty.com/setup.sh)"
```
