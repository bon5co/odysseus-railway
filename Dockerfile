# Odysseus for Railway.
#
# Wraps the OFFICIAL upstream image (pewdiepie-archdaemon/odysseus), pinned by
# digest, rather than building the app from a fork on the deployer's build
# minutes. Adds only what a Railway deploy needs:
#
#   1. The listener follows Railway's injected $PORT. Upstream's CMD hardcodes
#      --port 7000, and Railway's HTTP healthcheck dials the INJECTED port, not
#      the domain's target port, so a fixed listener makes a healthchecked
#      service fail to deploy even while the public URL serves 200.
#   2. Every setting that is a constant for a Railway deploy is baked as ENV.
#      A template variable whose default is a literal is dropped by
#      templateGenerate and republished as "required, no value", which turns
#      the deploy form into a questionnaire.
#   3. The @playwright/mcp package is warmed into the npx cache at build time.
#      Upstream installs it over the network on first start; on Railway that
#      cache lives on the ephemeral layer, so the download repeats on every
#      single deploy and the Built-in: Browser MCP server is missing until it
#      finishes.
FROM ghcr.io/pewdiepie-archdaemon/odysseus@sha256:80ed3a1c17fd08e95d12fc709889905aca47f51fa3524b07b53d692d25639879

# Runtime user the upstream entrypoint drops to (it also repairs ownership of
# /app/data, which Railway mounts as uid 0).
ENV PUID=1000 \
    PGID=1000 \
    # Auth on, loopback bypass off — the instance is on the public internet.
    AUTH_ENABLED=true \
    LOCALHOST_BYPASS=false \
    SECURE_COOKIES=true \
    ODYSSEUS_ADMIN_USER=admin \
    # Absolute path: uvicorn's CWD is /app, but an absolute URL removes any
    # doubt about which side of the volume mount the database lands on.
    DATABASE_URL=sqlite:////app/data/app.db \
    # Embedding model cache on the volume; otherwise it is re-downloaded from
    # HuggingFace on every deploy.
    FASTEMBED_MODEL=sentence-transformers/all-MiniLM-L6-v2 \
    FASTEMBED_CACHE_PATH=/app/data/fastembed \
    CHROMADB_PORT=8000 \
    CHROMADB_CONNECT_TIMEOUT=5.0 \
    CLEANUP_INTERVAL_HOURS=24 \
    ODYSSEUS_INPROCESS_TASKS=1 \
    ODYSSEUS_INPROCESS_POLLERS=1 \
    ODYSSEUS_SCRIPT_HOST=localhost \
    LLM_HOST=localhost

# Warm the Built-in: Browser MCP package into the npx cache. Runs as root at
# build time; the cache lands in /root/.npm, and the entrypoint's gosu user
# reads it through npx's global cache path.
RUN npx -y @playwright/mcp@latest --version \
    && npm cache verify >/dev/null 2>&1 || true

# Upstream ENTRYPOINT (ownership repair -> setup.py -> gosu) is preserved; only
# the command it execs changes. A Railway *start command* would replace the
# entrypoint outright and skip all of that, so the port fix goes here.
CMD ["sh", "-c", "exec uvicorn app:app --host 0.0.0.0 --port ${PORT:-7000}"]
