# CORS Issue Investigation Prompt

## Problem Summary

The Apollo Router at `https://api.ticketfi.ai/graphql` is blocking CORS requests from `https://organizer.ticketfi.ai` with the following error:

```
Access to fetch at 'https://api.ticketfi.ai/graphql' from origin 'https://organizer.ticketfi.ai'
has been blocked by CORS policy: Response to preflight request doesn't pass access control check:
No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

## What We've Verified

### ✅ Router Configuration (router.yaml)

- CORS is properly configured in `router.yaml` with:
  - `https://organizer.ticketfi.ai` explicitly listed in allowed origins (line 56)
  - All production `.ai` domains included
  - `allow_credentials: true` set
  - Proper headers configured (`content-type`, `authorization`, `cookie`, etc.)
  - Configuration file is copied to `/config/router_config.yaml` in Dockerfile

### ✅ Infrastructure Setup

- Apollo Router deployed on Railway
- Domain: `api.ticketfi.ai` → Railway service
- Router listens on port 4000
- Dockerfile copies `router.yaml` to `/config/router_config.yaml`

### ❌ Current Behavior

- OPTIONS preflight requests to `https://api.ticketfi.ai/graphql` return **502 Bad Gateway**
- No CORS headers (`Access-Control-Allow-Origin`) in responses
- Browser blocks all cross-origin requests from `organizer.ticketfi.ai`

## Investigation Needed

Please investigate the following:

### 1. Router Service Health

- Is the Apollo Router service running and healthy in Railway?
- Check Railway service logs for errors, especially around OPTIONS requests
- Verify the service is responding on port 4000

### 2. Configuration Loading

- Verify that `/config/router_config.yaml` is being loaded by the Apollo Router
- Check if the router is using default CORS settings instead of the custom config
- Review router startup logs to confirm config file is being read

### 3. Railway Proxy/Load Balancer

- Check Railway's proxy configuration for `api.ticketfi.ai`
- Verify if Railway is stripping CORS headers
- Check if Railway's proxy is handling OPTIONS requests correctly
- Look for any Railway-specific CORS settings that might override router config

### 4. OPTIONS Request Handling

- Test if the router responds to OPTIONS requests directly (bypassing Railway if possible)
- Check if Apollo Router version supports CORS properly
- Verify router logs show OPTIONS requests being received

### 5. Deployment Status

- Confirm the latest `router.yaml` configuration has been deployed
- Verify the Docker image includes the updated config file
- Check if a redeploy is needed to pick up CORS changes

## Test Commands

```bash
# Test OPTIONS preflight request
curl -X OPTIONS https://api.ticketfi.ai/graphql \
  -H "Origin: https://organizer.ticketfi.ai" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type,authorization" \
  -v

# Test regular POST request
curl -X POST https://api.ticketfi.ai/graphql \
  -H "Content-Type: application/json" \
  -H "Origin: https://organizer.ticketfi.ai" \
  -d '{"query":"{ __typename }"}' \
  -v
```

## Expected Behavior

For OPTIONS requests, the router should return:

- `Access-Control-Allow-Origin: https://organizer.ticketfi.ai`
- `Access-Control-Allow-Credentials: true`
- `Access-Control-Allow-Methods: POST, OPTIONS`
- `Access-Control-Allow-Headers: content-type, authorization, cookie`
- HTTP 200 or 204 status (not 502)

## Configuration Reference

The CORS configuration in `router.yaml` (lines 19-82):

```yaml
cors:
  policies:
    - origins:
        - https://organizer.ticketfi.ai # Line 56
        # ... other origins ...
      allow_credentials: true
      allow_headers:
        - content-type
        - authorization
        - cookie
        # ... other headers ...
```

## Questions to Answer

1. **Is the router.yaml config actually being applied?** Check router logs/startup
2. **Why are OPTIONS requests returning 502?** Is Railway blocking them or is the router not responding?
3. **Are there any middleware/proxies between Railway and the router that could interfere?**
4. **Does Railway have any CORS settings that need to be configured separately?**

## Next Steps

Once you identify the root cause, please:

- Fix the issue (whether it's config loading, Railway proxy, or router version)
- Verify CORS headers are present in responses
- Test from `https://organizer.ticketfi.ai` to confirm it works
- Document any Railway-specific CORS configuration needed

---

**Router Config Location:** `/Users/ticketfi/Developer/ticketfi.com/apollo-router/router.yaml`
**Dockerfile:** Copies `router.yaml` → `/config/router_config.yaml`
**Deployment Platform:** Railway
**Domain:** `api.ticketfi.ai`





