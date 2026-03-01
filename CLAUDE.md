# CLAUDE.md

This file provides context for Claude Code when working with this repository.

## Project Overview

This is the **TicketFi Apollo Router** — a GraphQL Federation gateway that routes queries to backend microservices. It uses the Apollo Runtime container (`ghcr.io/apollographql/apollo-runtime`) and is deployed on **Railway** (primary) with Render as an alternative.

The router connects to **Apollo GraphOS** to fetch the supergraph schema using `APOLLO_KEY` and `APOLLO_GRAPH_REF` environment variables. It does not contain application source code — the repo is purely configuration and deployment infrastructure.

## Repository Structure

```
router.yaml          # Apollo Router configuration (CORS, limits, telemetry, health checks)
supergraph.yaml      # Federated subgraph definitions (for local dev with rover CLI)
Dockerfile           # Based on ghcr.io/apollographql/apollo-runtime
railway.toml         # Railway deployment config
render.yaml          # Render deployment config
package.json         # pnpm scripts for validation, linting, formatting, Doppler secrets
scripts/             # Shell scripts for YAML quote checking and Doppler secret management
.yamllint            # YAML lint rules (double quotes preferred, 2-space indent, 120 char lines)
.prettierrc.yaml     # Prettier config for YAML formatting
.apollo/             # JSON schemas for IDE autocomplete
```

## Key Commands

```bash
# Validate router config (requires Docker)
pnpm validate:router

# Validate supergraph composition (requires rover CLI)
pnpm validate:supergraph

# Run both validations
pnpm test

# Lint YAML files
pnpm lint:yaml          # yamllint check
pnpm lint:quotes        # Check for single-quote usage (double quotes enforced)

# Format YAML files
pnpm format:yaml        # Auto-format with Prettier
pnpm format:check       # Check formatting without modifying

# Local development with Docker
pnpm dev                # Build and run with .env file
pnpm build              # Build Docker image only
pnpm start              # Run previously built image

# Doppler secret management
pnpm doppler:pull:local # Pull dev secrets to .env
pnpm doppler:pull       # Pull all environments
pnpm doppler:push       # Push all environments
```

## Configuration Conventions

- **YAML quoting**: Always use double quotes (`"`) for string values — enforced by `.yamllint` and `scripts/check-yaml-quotes.sh`.
- **Indentation**: 2 spaces for all YAML files.
- **Line length**: 120 characters max (warning level).
- **IPv6 binding**: All listen directives use `[::]:${env.PORT:-4000}` for Railway private networking compatibility (IPv6 Wireguard tunnels).
- **DNS resolution**: Subgraph traffic uses `ipv6_only` strategy since all subgraphs are Railway internal services.

## Environment Variables

- `APOLLO_KEY` — GraphOS API key (secret, never commit)
- `APOLLO_GRAPH_REF` — Graph reference (e.g., `my-graph@production`)
- `PORT` — Server port (defaults to 4000)
- `MCP_ENABLE` — Set to `1` to enable the Apollo MCP server

Environment files (`.env`, `.env.*`) are gitignored. Secrets are managed via **Doppler** (project: `ticketfi-router`, configs: `dev`, `stg`, `prd`).

## CORS Domains

The router allows requests from TicketFi domains across three environments:
- **Development**: `*.ticketfi.dev`
- **Staging**: `*.ticketfi.net`
- **Production**: `*.ticketfi.ai`

Plus `https://studio.apollographql.com` for Apollo Studio.

## Deployment

Deployments are triggered by GitHub Actions (not Railway auto-deploy). The Dockerfile copies `router.yaml` into the container as `/config/router_config.yaml`. Changes to `router.yaml` or `Dockerfile` trigger rebuilds (see `railway.toml` watchPaths).

## Common Tasks

- **Adding a new CORS origin**: Edit the `cors.policies[0].origins` list in `router.yaml`.
- **Adding a new subgraph**: Add to `supergraph.yaml` for local dev; the production supergraph is managed in GraphOS.
- **Changing router limits**: Edit the `limits` section in `router.yaml`.
- **Updating the runtime version**: Modify the `FROM` image tag in `Dockerfile` (Renovate handles this automatically).
