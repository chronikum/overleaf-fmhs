# Overleaf - Full Managed Hosted ShareLaTeX (overleaf-fmhs)

This workspace contains a standalone Docker Compose setup for Overleaf Extended Community Edition. It builds a small local image from `overleafcep/sharelatex:6.1.2-ext-v4.1`, which includes the Extended CE feature bundle such as reference-key autocomplete, the symbol palette, template gallery, comments/track changes, and external URL import.

The local image also installs broad TeX Live collections for common academic documents: recommended LaTeX packages, LaTeX extras, BibLaTeX/BibTeX extras with `biber`, recommended fonts, and German language support. It also installs `algorithmicx`, `algorithms`, `dirtree`, and `struktex`, useful for algorithm floats, pseudocode, directory-tree diagrams, and structured diagrams, because they are not pulled in by those collections. This covers classes and packages such as `scrartcl`, `ngerman`, `csquotes`, `biblatex`, `algorithm`, `algpseudocode`, `dirtree`, and `struktex` without turning every missing package into a one-off Dockerfile edit.

Sandboxed compiles are disabled by default, and the Docker socket is not mounted.

MongoDB is pinned to `mongo:8.0.20` because this Overleaf Extended CE release requires MongoDB 8 or newer. 8.0.21+ refuses to start on any kernel reporting 6.19–7.0.13 ([SERVER-121912](https://jira.mongodb.org/browse/SERVER-121912)), including Ubuntu 26.04's `7.0.0-N` kernels that already carry the upstream 7.0.14 fix. Check the real upstream version with `cat /proc/version_signature`; only use this pin on a kernel that is genuinely 7.0.14+ (or below 6.19). Move back to `mongo:8.0` once the host kernel reports 7.0.14+ in `uname -r`.

The pinned Extended CE image is published for `linux/amd64`. The Compose file sets that platform explicitly, which works natively on amd64 servers and under Docker Desktop emulation on Apple Silicon.

## Quick Start

1. Copy the example environment file:

   ```sh
   cp .env.example .env
   ```

2. Edit `.env`:

   - Set `OVERLEAF_SITE_URL` to the public URL served by your reverse proxy.
   - Generate `OVERLEAF_SESSION_SECRET` with `openssl rand -hex 32`.
   - Leave `OVERLEAF_LISTEN_IP=127.0.0.1` and `OVERLEAF_PORT=8080` if your reverse proxy runs on the same host.

3. Validate the Compose configuration:

   ```sh
   docker compose config
   ```

4. Start Overleaf:

   ```sh
   docker compose up -d
   ```

5. Check status and logs:

   ```sh
   docker compose ps
   docker compose logs -f overleaf
   ```

Overleaf will be available on `http://127.0.0.1:8080` by default.

## First Admin Account

After the services are running, open:

```text
http://127.0.0.1:8080/launchpad
```

Register the first administrator account there, then log in at `/login`.

You can also create an administrator from the command line:

```sh
docker compose exec overleaf /bin/bash -ce "cd /overleaf/services/web && node modules/server-ce-scripts/scripts/create-user --admin --email=you@example.com"
```

If the command prints a password setup URL pointing at `localhost`, replace the host with your `OVERLEAF_SITE_URL` or `http://127.0.0.1:8080`.

## Reverse Proxy

Point your reverse proxy to:

```text
http://127.0.0.1:8080
```

Preserve these headers:

```text
Host
X-Forwarded-Proto
X-Forwarded-For
```

If your proxy runs in Docker rather than directly on the host, set `OVERLEAF_TRUSTED_PROXY_IPS` in `.env` to include the proxy network CIDR, for example:

```env
OVERLEAF_TRUSTED_PROXY_IPS=loopback,172.18.0.0/16
```

TLS is intentionally handled by your reverse proxy, not this Compose stack.

## Data And Backups

Persistent data lives in named Docker volumes:

- `overleaf-extended-ce_overleaf-data`
- `overleaf-extended-ce_mongo-data`
- `overleaf-extended-ce_redis-data`

For a consistent backup, stop the stack first:

```sh
docker compose stop
docker run --rm -v overleaf-extended-ce_overleaf-data:/data -v "$PWD:/backup" alpine tar czf /backup/overleaf-data.tgz -C /data .
docker run --rm -v overleaf-extended-ce_mongo-data:/data -v "$PWD:/backup" alpine tar czf /backup/mongo-data.tgz -C /data .
docker run --rm -v overleaf-extended-ce_redis-data:/data -v "$PWD:/backup" alpine tar czf /backup/redis-data.tgz -C /data .
docker compose start
```

## Upgrades

This setup pins the Overleaf base image for repeatable deployments. To upgrade:

1. Read the Extended CE release notes for the target tag.
2. Back up the three volumes.
3. Change the `FROM` image tag in `Dockerfile` and the local image tag in `compose.yaml`.
4. Run:

   ```sh
   docker compose build --pull overleaf
   docker compose up -d
   ```

Avoid downgrading after Overleaf has started against your MongoDB data unless you have restored a backup.

## Validation Scenario

After first login:

1. Create a new blank project.
2. Add `references.bib`:

   ```bibtex
   @article{knuth1984literate,
     title={Literate programming},
     author={Knuth, Donald E.},
     journal={The Computer Journal},
     year={1984}
   }
   ```

3. Add `main.tex`:

   ```tex
   \documentclass{article}
   \begin{document}
   Hello \cite{knuth1984literate}.
   \bibliographystyle{plain}
   \bibliography{references}
   \end{document}
   ```

4. In `main.tex`, type `\cite{kn` and confirm that reference-key autocomplete offers `knuth1984literate`.
5. Compile the project and confirm the PDF renders with the bibliography.

## Notes

- This setup uses local Overleaf accounts only.
- SMTP is not required for the first administrator account.
- Because sandboxed compiles are disabled, only run this for trusted users. LaTeX compiles can access container resources in non-sandboxed mode.
