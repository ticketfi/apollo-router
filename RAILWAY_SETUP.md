# Railway Dashboard Setup Guide

This guide walks you through setting up the Apollo Router service in the Railway dashboard.

## Prerequisites

- Railway account with access to the `ticketfi-backend` project
- GitHub repository connected to Railway
- Apollo GraphOS credentials ready

## Step-by-Step Setup

### 1. Create or Select Service

**Option A: Create New Service**

1. Go to [Railway Dashboard](https://railway.app)
2. Select the **ticketfi-backend** project (or create it if it doesn't exist)
3. Click **"New"** → **"GitHub Repo"**
4. Select your repository: `ticketfi/apollo-router` (or your repo name)
5. Railway will detect the `railway.toml` file automatically

**Option B: Use Existing Service**

1. Navigate to your project in Railway
2. Find the existing router service (if already created)
3. Click on it to configure

### 2. Configure Environment Variables

Go to your service → **Variables** tab → **Add Variable**

#### Required Variables (Production)

Add these environment variables for the **production** environment:

```bash
APOLLO_KEY=service:ticketfi-backend:GGT7wuB8sKTC5jhLhBAwVw
APOLLO_GRAPH_REF=ticketfi-backend@current
APOLLO_ROUTER_CONFIG_PATH=router.yaml
NODE_ENV=production
LOG_LEVEL=error
COOKIE_DOMAIN=.ticketfi.ai
NEXT_PUBLIC_GRAPHQL_ENDPOINT=https://api.ticketfi.ai/graphql
```

#### Optional Variables

```bash
POSTHOG_API_KEY=phc_xcrPyHLrd3GrsX0fZe55Mv3loVzaKnSjIGayJsaFxox
POSTHOG_HOST=https://us.i.posthog.com
POSTHOG_PROJECT_ID=245543
RAILWAY_PROJECT_ID=ca72e15c-2ec5-4f38-a08f-2917a9185589
```

**Important:** `PORT` is automatically set by Railway (defaults to `8080`) - **DO NOT manually set PORT** in Railway dashboard. If you set a different port manually (e.g., `8088`), it will cause a mismatch between what Railway expects and what the router listens on, resulting in 502 errors. The router.yaml uses `${env.PORT:-4000}`, so it will automatically use Railway's assigned port.

### 3. Set Up Domain

1. Go to your service → **Settings** tab
2. Scroll to **"Networking"** section
3. Click **"Generate Domain"** or **"Add Domain"**
4. Set custom domain: `api.ticketfi.ai`
5. Railway will provide DNS instructions if needed

### 4. Verify Configuration

1. **Service Settings:**

   - **Build Command:** (auto-detected from `railway.toml`)
   - **Start Command:** `/init` (from `railway.toml`)
   - **Health Check Path:** `/health` (from `railway.toml`)

2. **Deployment:**
   - Railway will auto-deploy when you push to the connected branch
   - Or manually trigger: **Settings** → **"Redeploy"**

### 5. Check Deployment Logs

1. Go to **Deployments** tab
2. Click on the latest deployment
3. Check **Logs** for:
   - ✅ `Router started successfully`
   - ✅ `Listening on 0.0.0.0:4000`
   - ✅ `Health check available at /health`
   - ❌ Any errors about missing `APOLLO_KEY` or `APOLLO_GRAPH_REF`

### 6. Test Deployment

After deployment succeeds:

```bash
# Test health endpoint
curl https://api.ticketfi.ai/health

# Test GraphQL endpoint
curl https://api.ticketfi.ai/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __typename }"}'
```

## Environment-Specific Setup

### Development Environment

If you have a separate dev environment:

1. Create a new service or use environment variables
2. Set environment to **"Development"**
3. Use these variables:
   ```bash
   APOLLO_GRAPH_REF=ticketfi-backend@dev
   NODE_ENV=development
   LOG_LEVEL=debug
   COOKIE_DOMAIN=.ticketfi.dev
   NEXT_PUBLIC_GRAPHQL_ENDPOINT=https://api.ticketfi.dev/graphql
   ```

### Staging Environment

For staging:

1. Set environment to **"Staging"**
2. Use these variables:
   ```bash
   APOLLO_GRAPH_REF=ticketfi-backend@stg
   NODE_ENV=staging
   LOG_LEVEL=info
   COOKIE_DOMAIN=.ticketfi.net
   NEXT_PUBLIC_GRAPHQL_ENDPOINT=https://api.ticketfi.net/graphql
   ```

## Quick Setup Using Doppler (Recommended)

Instead of manually adding variables, you can sync from Doppler:

```bash
# Pull production variables
pnpm doppler:pull:prd

# Then copy values to Railway dashboard
# Or use Railway CLI to set them programmatically
```

## Troubleshooting

### Service Won't Start

1. **Check Logs:**

   - Look for errors about missing environment variables
   - Verify `APOLLO_KEY` and `APOLLO_GRAPH_REF` are set

2. **Verify Configuration:**
   - Ensure `railway.toml` is in the root directory
   - Check that `Dockerfile` exists
   - Verify `router.yaml` is present

### Health Check Failing (502 Errors)

1. **Check Health Endpoint:**

   ```bash
   curl https://api.ticketfi.ai/health
   ```

2. **Verify Router Config:**

   - Check logs for router startup messages
   - Verify health check path matches `/health` in `router.yaml`
   - Verify router is listening on the correct port (check logs for `Listening on 0.0.0.0:PORT`)

3. **Common Causes:**
   - **Timing Issue**: Railway may check health before router is fully ready
     - Solution: Health check timeout is set to 120 seconds in `railway.toml`
     - Wait a minute or two after deployment and check again
   - **Port Mismatch**: Router listening on different port than Railway expects
     - **Common cause**: Manually setting `PORT` in Railway dashboard (e.g., `8088`) when Railway expects `8080`
     - Solution: **Remove any manual `PORT` setting** from Railway - let Railway auto-assign it (defaults to `8080`)
     - The router uses `${env.PORT:-4000}`, so it will automatically use Railway's assigned port
     - Verify no `PORT` variable is manually set in Railway environment variables
   - **Health Endpoint Not Accessible**: Router health check must listen on `0.0.0.0` (not `127.0.0.1`)
     - Solution: Verify `router.yaml` has `listen: 0.0.0.0:${env.PORT:-4000}` for health_check

### CORS Issues

1. **Check CORS Configuration:**

   - Verify `router.yaml` has correct origins
   - Check that `allow_credentials: true` is set

2. **Test CORS:**
   ```bash
   curl -X OPTIONS https://api.ticketfi.ai/graphql \
     -H "Origin: https://organizer.ticketfi.ai" \
     -H "Access-Control-Request-Method: POST" \
     -v
   ```

## Railway Dashboard Checklist

- [ ] Service created and connected to GitHub repo
- [ ] `railway.toml` detected by Railway
- [ ] `APOLLO_KEY` environment variable set
- [ ] `APOLLO_GRAPH_REF` environment variable set
- [ ] Domain configured (`api.ticketfi.ai`)
- [ ] Health check path set to `/health`
- [ ] Service deployed successfully
- [ ] Health endpoint responding
- [ ] GraphQL endpoint accessible
- [ ] CORS headers present in responses

## Next Steps

After setup is complete:

1. **Monitor Logs:** Keep an eye on deployment logs for any issues
2. **Set Up Alerts:** Configure Railway alerts for deployment failures
3. **Test Endpoints:** Verify all endpoints are working correctly
4. **Update Documentation:** Document any custom configurations

## Reference

- **Railway Docs:** https://docs.railway.app
- **Apollo Router Docs:** https://www.apollographql.com/docs/router
- **Project Config:** See `DEPLOYMENT_CHECKLIST.md` for detailed configuration
