# odysseus-railway-searxng

SearXNG sidecar image for the [Odysseus](https://github.com/pewdiepie-archdaemon/odysseus)
Railway template. Published as `ghcr.io/bon5co/odysseus-railway-searxng:latest`.

Odysseus calls SearXNG with `format=json`
(`services/search/providers.py`). The stock SearXNG image ships
`search.formats: [html]` only, so an unmodified image answers **HTTP 403** to
every Odysseus web search and Deep Research call while the container itself
stays healthy. This image installs the settings file upstream Odysseus ships
for exactly that reason, with `server.secret_key` taken from `SEARXNG_SECRET`
at boot instead of being baked into a public image layer.

Pinned to `searxng/searxng:2026.5.31-7159b8aed` — the tag upstream Odysseus
pins in its own `docker-compose.yml`.
