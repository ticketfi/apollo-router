# TCP Issues Troubleshooting Guide

## Overview

This document outlines potential TCP connection issues between the Apollo Router and subgraph services (specifically the user service) in Railway production environments.

## Common Causes & Solutions

### 1. DNS Resolution Issues ⚠️ **MOST LIKELY**

**Problem:**
- Router cannot resolve subgraph hostnames in Railway's containerized environment
- DNS queries may timeout or fail intermittently
- **Railway uses IPv6 for internal networking** - router must resolve to IPv6 addresses, not IPv4

**Symptoms:**
- `Connection refused` errors
- `Name resolution failed` errors
- Intermittent connection failures
- Timeouts before connection is established

**Solution Applied:**
Added `dns_resolution_strategy: ipv6_only` to `traffic_shaping` configuration. **Railway uses IPv6 for internal service-to-service communication**, so the router must resolve subgraph hostnames to IPv6 addresses.

**Additional Checks:**
1. Verify subgraph URL in GraphOS is correct and accessible
2. Ensure subgraph service is running and healthy in Railway
3. Check Railway service logs for DNS resolution errors

---

### 2. Connection Timeout Issues

**Problem:**
- Default 30s timeout may be too short for slow subgraph responses
- Network latency between Railway services
- Subgraph service taking too long to respond

**Current Configuration:**
```yaml
traffic_shaping:
  all:
    timeout: 30s  # Current setting
```

**Solutions:**
- **Increase timeout** if subgraph is legitimately slow:
  ```yaml
  traffic_shaping:
    all:
      timeout: 60s  # Increase for slow subgraphs
  ```

- **Per-subgraph timeout** if only user service is slow:
  ```yaml
  traffic_shaping:
    subgraphs:
      users:  # Replace with actual subgraph name
        timeout: 60s
  ```

- **Check subgraph performance** - investigate why it's slow:
  - Database query performance
  - External API calls
  - Resource constraints (CPU/memory)

---

### 3. Connection Pool Exhaustion

**Problem:**
- Router may exhaust available TCP connections to subgraph
- No connection reuse/pooling configured
- High concurrent request volume

**Symptoms:**
- `Connection refused` errors under load
- Errors increase with traffic volume
- Subgraph appears healthy but router can't connect

**Solutions:**
- **Monitor connection metrics** via Prometheus (`/metrics` endpoint)
- **Check subgraph connection limits** - ensure subgraph can handle concurrent connections
- **Implement connection pooling** at subgraph level (if using HTTP server)
- **Consider request batching** to reduce connection count

**Note:** Apollo Router handles connection pooling internally, but subgraph services must also support concurrent connections.

---

### 4. TLS/SSL Handshake Issues

**Problem:**
- TLS handshake failures between router and subgraph
- Certificate validation errors
- TLS version/cipher suite mismatches

**Symptoms:**
- `peer misbehaved: abbreviated handshake` errors
- `certificate verify failed` errors
- Connection failures only on HTTPS subgraphs

**Solutions:**
- **Verify subgraph TLS configuration** - ensure valid certificates
- **Check TLS version compatibility** - router and subgraph must support compatible TLS versions
- **Review Railway TLS settings** - ensure proper certificate configuration
- **Test subgraph URL directly** - verify HTTPS works outside router

---

### 5. Railway Network Policies

**Problem:**
- Railway service-to-service networking restrictions
- Private network isolation
- Firewall rules blocking connections

**Symptoms:**
- Connections work locally but fail in Railway
- Intermittent failures
- Specific ports/protocols blocked

**Solutions:**
- **Use Railway private networking** - ensure services are in same project/environment
- **Verify Railway service URLs** - use internal Railway hostnames when possible
- **Check Railway networking docs** - ensure proper service configuration
- **Use Railway service discovery** - leverage Railway's internal DNS

---

### 6. Subgraph URL Configuration Issues

**Problem:**
- Incorrect subgraph URL in GraphOS
- URL points to wrong environment/service
- URL uses wrong protocol (http vs https)

**Symptoms:**
- Consistent connection failures
- Works in one environment but not another
- Connection refused errors

**Solutions:**
1. **Verify GraphOS subgraph configuration:**
   ```bash
   rover subgraph list ticketfi-backend@current
   ```

2. **Check subgraph URL:**
   - Should match Railway service URL
   - Use HTTPS for production
   - Verify URL is accessible from router's network

3. **Update subgraph URL if needed:**
   ```bash
   rover subgraph publish ticketfi-backend@current \
     --name users \
     --schema ./schema.graphql \
     --routing-url https://your-users-service.railway.app
   ```

---

### 7. Health Check Interference

**Problem:**
- Router health checks overwhelming subgraph
- Health check endpoint not configured correctly
- Health checks causing connection exhaustion

**Current Configuration:**
```yaml
health_check:
  enabled: true
  listen: 0.0.0.0:${env.PORT:-4000}
  path: /health
```

**Solutions:**
- **Verify health check endpoint** - ensure `/health` exists and responds quickly
- **Monitor health check frequency** - Railway may be checking too frequently
- **Separate health check port** - if needed, configure separate port for health checks

---

## Diagnostic Steps

### 1. Check Router Logs

Look for these error patterns:
- `Connection refused`
- `Name resolution failed`
- `Timeout while connecting`
- `TLS handshake failed`
- `Too many connections`

### 2. Check Subgraph Logs

In Railway, check user service logs for:
- Connection attempts from router
- Rejected connections
- Timeout errors
- Resource exhaustion

### 3. Test Subgraph Directly

```bash
# Test subgraph URL directly (replace with actual URL)
curl -v https://your-users-service.railway.app/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __typename }"}'
```

### 4. Check Router Metrics

Access Prometheus metrics endpoint:
```bash
curl https://api.ticketfi.ai/metrics | grep subgraph
```

Look for:
- `apollo_router_subgraph_requests_total`
- `apollo_router_subgraph_request_duration_seconds`
- `apollo_router_subgraph_errors_total`

### 5. Verify GraphOS Configuration

```bash
# List all subgraphs
rover subgraph list ticketfi-backend@current

# Check specific subgraph details
rover subgraph check ticketfi-backend@current --name users
```

---

## Configuration Recommendations

### For User Service Specifically

If user service continues to have issues, add per-subgraph configuration:

```yaml
traffic_shaping:
  all:
    timeout: 30s
    deduplicate_query: true
    dns_resolution_strategy: ipv6_only  # Railway uses IPv6 internally
  subgraphs:
    users:  # Replace with actual subgraph name from GraphOS
      timeout: 45s  # Longer timeout for user service
      dns_resolution_strategy: ipv6_only  # Railway uses IPv6 internally
      deduplicate_query: true
```

### Override Subgraph URL (If Needed)

If you need to override the URL from GraphOS for testing:

```yaml
override_subgraph_url:
  users: https://your-users-service.railway.app
```

**⚠️ Warning:** Only use this for testing/debugging. Production should use GraphOS-managed URLs.

---

## Railway-Specific Considerations

1. **IPv6 Internal Networking:** ⚠️ **CRITICAL** - Railway uses **IPv6 addresses for internal service-to-service communication**. The router must be configured to resolve DNS to IPv6 addresses (`dns_resolution_strategy: ipv6_only`), not IPv4. This is the most common cause of TCP connection failures in Railway.

2. **Service Discovery:** Railway provides internal DNS. Use Railway service hostnames when possible.

3. **Private Networking:** Services in the same Railway project can communicate via private network using IPv6.

4. **Port Configuration:** Ensure `PORT` environment variable matches Railway's assigned port.

5. **Health Checks:** Railway uses the health check endpoint to determine service status.

6. **Resource Limits:** Check Railway service resource limits (CPU/memory) - may cause connection issues if exhausted.

---

## Next Steps

1. ✅ **Applied DNS resolution fix** - Added `dns_resolution_strategy: ipv6_only` (Railway uses IPv6 internally)
2. **Monitor** - Watch logs and metrics after deployment
3. **Adjust timeout** - If needed, increase timeout for user service
4. **Verify GraphOS** - Ensure user service URL is correct in GraphOS
5. **Check Railway** - Verify user service is healthy and accessible
6. **Verify IPv6 resolution** - Test that router can resolve subgraph hostnames to IPv6 addresses

---

## Additional Resources

- [Apollo Router Traffic Shaping Docs](https://www.apollographql.com/docs/router/configuration/traffic-shaping)
- [Railway Networking Docs](https://docs.railway.app/develop/networking)
- [Apollo Router Troubleshooting](https://www.apollographql.com/docs/router/troubleshooting)

