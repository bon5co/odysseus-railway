# odysseus-railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/odysseus-v102-or-pewdiepie-ai-workspace-?referralCode=Z1xivh&utm_medium=integration&utm_source=template&utm_campaign=generic)

**Deploy on Railway:** [Odysseus template](https://railway.com/deploy/odysseus-v102-or-pewdiepie-ai-workspace-?referralCode=Z1xivh&utm_medium=integration&utm_source=template&utm_campaign=generic)

Wrapper image for the [Odysseus](https://github.com/pewdiepie-archdaemon/odysseus)
Railway template. Built `FROM` the **official** upstream image, pinned by digest.

Published as `ghcr.io/bon5co/odysseus-railway:latest`.

What it adds, and why:

| Change | Reason |
|---|---|
| `CMD` execs uvicorn on `$PORT` | Railway's HTTP healthcheck dials the **injected** port, not the domain's target port. Upstream's `--port 7000` is fixed, so a healthchecked service never goes healthy. |
| Railway-constant settings baked as `ENV` | `templateGenerate` drops a template variable whose default is a literal and republishes it as *required, no value* — every one of them becomes a blank field on the deploy form. |
| `@playwright/mcp` warmed into the npx cache | Upstream installs it over the network on first start. On Railway that cache is on the ephemeral layer, so the download repeats on every deploy and the Built-in: Browser MCP server is missing until it completes. |

The upstream `ENTRYPOINT` is deliberately preserved: it repairs ownership of
`/app/data` (Railway mounts volumes as uid 0) and runs `setup.py` before
dropping privileges with `gosu`. A Railway **start command** would replace it
outright and skip all of that, which is why the port fix is a `CMD` here.
