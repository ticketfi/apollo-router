# Apollo Router Railway Deployment Checklist

## Pre-Deployment Verification

### ✅ Configuration Files

- [x] `railway.toml` - Properly configured with Dockerfile builder
- [x] `router.yaml` - CORS configured with production domains
- [x] `Dockerfile` - Copies router.yaml to correct location
- [x] Health check configured at `/health`

### ⚠️ Required Environment Variables in Railway

Verify these are set in your Railway production environment:

- [ ] `APOLLO_KEY` - Your Apollo GraphOS API key
- [ ] `APOLLO_GRAPH_REF` - Your graph reference (e.g., `ticketfi-backend@current` for production)
- [ ] `APOLLO_ROUTER_CONFIG_PATH=/dist/config/router.yaml` - **absolute path** for the standalone `router:v2.x` image (WORKDIR `/dist`). A relative `router.yaml` resolves to `/dist/router.yaml` and the router won't find the config → boot failure. Must match the Dockerfile COPY target.
- [ ] `PORT` - **DO NOT manually set this** - Railway sets it automatically (defaults to `8080`). If you manually set a different port, it will cause 502 errors due to port mismatch.

### 🔒 Security Considerations

- [x] **Introspection**: Enabled (`introspection: true`) - **This is fine!**
  - GraphOS handles schema management, but router introspection allows clients to query `__schema`/`__type`
  - Many production APIs keep this enabled for client tooling (Apollo Client, GraphiQL, etc.)
  - Only disable if you want to hide the schema from clients (uncommon for public APIs)

### 🚀 Deployment Steps

1. **Verify Environment Variables**

   - Go to Railway dashboard → ticketfi-backend project → Production environment
   - Check that `APOLLO_KEY` and `APOLLO_GRAPH_REF` are set
   - Verify `PORT` is set (Railway usually sets this automatically)

2. **Deploy to Railway**

   - Push to `main` branch (if auto-deploy is enabled)
   - Or manually trigger deployment in Railway dashboard

3. **Verify Deployment**

   - Check Railway logs for successful startup
   - Test health endpoint: `curl https://api.ticketfi.ai/health`
   - Test GraphQL endpoint: `curl https://api.ticketfi.ai/graphql`

4. **Test CORS**
   - Test from `https://organizer.ticketfi.ai` to verify CORS headers are present
   - Check browser console for CORS errors

### 📋 Current Configuration Summary

**Router Config:**

- Port: Uses `${env.PORT:-4000}` (Railway will set PORT automatically)
- GraphQL Path: `/graphql`
- Health Check: `/health`
- CORS: Configured for all production `.ai` domains
- Introspection: Enabled (appropriate for production with GraphOS)

**Railway Config:**

- Builder: Dockerfile
- Start Command: none (standalone `router:v2.x` image entrypoint; `/init` was legacy-image-only and would crash)
- Config path: `APOLLO_ROUTER_CONFIG_PATH=/dist/config/router.yaml` (absolute; matches Dockerfile COPY)
- Health Check Path: `/health`
- Health Check Timeout: 120 seconds

### 🔍 Known Issues

- See `CORS_ISSUE_PROMPT.md` for documented CORS issues
- If CORS issues persist after deployment:
  1. Verify router.yaml is being loaded (check logs)
  2. Check Railway proxy configuration
  3. Verify OPTIONS requests are handled correctly

### ✅ Ready to Deploy?

**YES** - If:

- ✅ Environment variables are set in Railway (`APOLLO_KEY` and `APOLLO_GRAPH_REF`)
- ✅ You've reviewed the CORS configuration

**NO** - If:

- ❌ Missing `APOLLO_KEY` or `APOLLO_GRAPH_REF` in Railway
