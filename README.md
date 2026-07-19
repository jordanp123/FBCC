# Fords Branch Church of Christ — fordsbranch.church

Static website for [Fords Branch Church of Christ](https://fordsbranch.church) in Pikeville, KY.
Served by nginx in Docker, published to the internet through a Cloudflare Tunnel
(no ports are exposed on the server; only the tunnel can reach the site).

## Repo layout

```
├── files/                  # The webroot — everything in here is served as-is
│   ├── *.html              # Site pages (index, services, location, bulletin, events, contact, give, 404)
│   ├── robots.txt
│   ├── sitemap.xml
│   └── assets/
│       ├── css/style.css   # Single stylesheet for the whole site
│       └── images/
├── nginx.conf              # nginx server config (caching, security headers, clean URLs, custom 404)
├── Dockerfile              # nginx-unprivileged; copies the webroot read-only (files 444, dirs 755)
├── .dockerignore           # allowlist: only files/ and nginx.conf enter the build context
└── docker-compose.yaml     # website container + cloudflared tunnel container
```

## Updating content

| What | How |
|---|---|
| **Bulletin** | Edit the published Google Doc — the bulletin page embeds it, no deploy needed. |
| **Events** | Add/edit events in the `fordsbranchchurchofchrist@gmail.com` Google Calendar — the events page embeds it, no deploy needed. |
| **Page text** | Edit the matching file in `files/`, then deploy (below). |
| **Stylesheet** | Edit `files/assets/css/style.css`, then **bump the version** in every page's `<link ... href="assets/css/style.css?v=2" />` (v=2 → v=3, etc.), then deploy. Without the bump, returning visitors keep the old CSS for up to a day. |
| **Images** | Add the new image under a **new filename** and update the HTML to point at it. Images are cached by browsers for 1 year, so replacing a file in-place won't show up for returning visitors. |

> **Adding a *new* file** (a page, image, or any asset): just drop it under
> `files/` and deploy — the whole `files/` tree is copied into the image, so no
> Dockerfile change is needed. Editing an existing file is the same.

The pages share a shell (edit-into-every-page): header/nav, footer, and the small
nav-toggle script are duplicated in each HTML file. When changing them, change all
8 pages (including `404.html`, which uses absolute `/...` paths).

## Deploying

On the server, from this repo's directory:

```bash
git pull
docker compose up -d --build
docker compose exec website nginx -t   # sanity-check the nginx config
```

Then in the Cloudflare dashboard: **Caching → Purge Everything** (or at least the
changed asset URLs), since Cloudflare edge-caches CSS and images.

### Secrets

The Cloudflare tunnel token is read from `.env` on the server
(`TUNNEL_TOKEN=...`). `.env` is gitignored — **never commit it**. If it ever
leaks, rotate the token in the Cloudflare Zero Trust dashboard.

## Local preview

```bash
python3 -m http.server -d files 8000
# → http://localhost:8000
```

Good enough for checking content and styling. Clean URLs (`/services`), the
custom 404, caching, and security headers only exist through nginx — to test
those, build and run the container:

```bash
docker build -t fbcc-test . && docker run --rm -p 127.0.0.1:8080:8080 fbcc-test
```

## Server / infrastructure notes

- The nginx container runs unprivileged (`nginxinc/nginx-unprivileged:alpine-slim`),
  read-only, with all capabilities dropped and resource limits set.
- The webroot is copied read-only: every file is mode `444` and every directory
  `755`. That split matters — a directory needs its execute/traverse bit for the
  non-root runtime user (uid `7001`) to read files inside it, so the Dockerfile
  applies `--chmod=444` to the whole tree and then restores `755` on directories.
  Leaving directories at `444` strips traversal, and every request under a
  subdirectory (e.g. `/assets`) returns `403` — an unstyled site with broken
  images, served with `Content-Type: text/html` (a `nosniff` MIME error in the
  browser console) because nginx answers with the HTML error page.
- `no-new-privileges` is commented out in `docker-compose.yaml` because the Ubuntu
  **snap** Docker package can't handle it — re-enable it if Docker is ever
  installed from docker.com or apt instead.
- TLS terminates at Cloudflare; the origin only speaks plain HTTP :8080 to the
  tunnel on a private Docker network. HSTS and some security headers are also
  set at the Cloudflare edge. Note the edge **overrides** `Referrer-Policy` to
  `same-origin` (nginx is kept in sync) and — until cleaned up in the Cloudflare
  dashboard (Rules → Transform Rules → Modify Response Header) — adds two
  deprecated headers, `Expect-CT` and `X-XSS-Protection`, that are **not** in
  `nginx.conf`.
- An **enforced** `Content-Security-Policy` is set in `nginx.conf`. It shipped
  in `Content-Security-Policy-Report-Only` first, and the footprint was mapped
  across every page (front / bulletin / give) before enforcing: the only origin
  the policy would have blocked was the Cloudflare Insights beacon, which is now
  allowlisted. The Tithe.ly give widget and Google Docs/Calendar/Maps embeds are
  covered by `frame-src`; the whole Tithe.ly → Stripe → Plaid → hCaptcha →
  reCAPTCHA payment stack loads *inside* the tithe.ly iframe and answers to
  Tithe.ly's own CSP, not ours. Because every page relies on inline `<script>`
  and `style=""`, the policy keeps `'unsafe-inline'`, so it locks down external
  origins rather than inline injection. To go back to observing (e.g. before
  adding a new embed), rename the header to `Content-Security-Policy-Report-Only`.
- `nginx.conf` also hardens requests beyond the headers/CSP above: only `GET` and
  `HEAD` are allowed (anything else returns `405`), `server_tokens off` hides the
  nginx version from responses and error pages, and requests for hidden dotfiles
  (`/.git`, `/.env`, …) or common script extensions (`.php`, `.asp`, `.aspx`,
  `.jsp`, `.cgi`, `.sh`, `.py`, `.pl`, `.rb`) are denied with a `404`.
- The bulletin Google Doc is publicly readable by design — keep that in mind
  before putting personal details (e.g. prayer-request specifics) in it.
