# GraphOS Variant Fix

## Issue

The Apollo Router was failing with:
```
uplink error: No valid graph configuration for graphID: ticketfi-backend, variant: prd
```

## Root Cause

The production variant in GraphOS is named `current`, not `prd`. When copying environment variables from `ticketfi-backend`, the variant name was incorrectly changed from `@current` to `@prd`.

## Solution

Updated `APOLLO_GRAPH_REF` in Doppler for production:
- **Before:** `ticketfi-backend@prd`
- **After:** `ticketfi-backend@current`

## Variant Names by Environment

- **Dev:** `ticketfi-backend@dev` ✅
- **Staging:** `ticketfi-backend@stg` ✅
- **Production:** `ticketfi-backend@current` ✅ (NOT `@prd`)

## Next Steps

1. Update Railway environment variable:
   - Go to Railway dashboard → Service → Variables
   - Change `APOLLO_GRAPH_REF` from `ticketfi-backend@prd` to `ticketfi-backend@current`
   - Or redeploy to pick up the updated Doppler value

2. Verify the router starts successfully after the change

3. Test the GraphQL endpoint:
   ```bash
   curl https://api.ticketfi.ai/graphql \
     -H "Content-Type: application/json" \
     -d '{"query":"{ __typename }"}'
   ```


