# renovate: datasource=docker depName=ghcr.io/apollographql/router versioning=semver
FROM ghcr.io/apollographql/router:v2.12.1

# Copy router configuration
COPY router.yaml /dist/config/router.yaml

# For local development without GraphOS:
# Uncomment the line below to use a locally composed supergraph schema
# COPY data/schema.graphql /dist/config/schema.graphql
