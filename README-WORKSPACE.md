# ⚠️ Production Router Template - Rarely Modified

## Important Notice

This directory contains the **production Apollo Router configuration** and is:

- ✅ **Production deployment only**
- ✅ **Rarely modified** (typically only for production config changes)
- ❌ **NOT used for local development**

## Local Development

For local development, use the **backend's built-in router**:

```bash
cd backend
npm run dev          # Includes local Apollo router
npm run dev:router   # Start router separately if needed
```

The backend has its own router configuration at:
- `backend/router-local-composed.yaml`
- `backend/router-local-graphos.yaml`
- `backend/supergraph-local.yaml`

## When to Modify This Directory

Only modify `router-template/` when:
1. Updating production router configuration
2. Changing production CORS policies
3. Updating production authentication flows
4. Modifying production routing rules

## Deployment

This template is used for production deployments (Railway/Render/etc.) and should match production requirements, not local development needs.

---

**TL;DR**: For daily development, work in `backend/` and `frontend/`. This directory is for production router config only.


