#!/bin/bash
# Push environment variables from .env file to Doppler
# Usage: ./scripts/doppler-push.sh <env-file> <project> <config>

set -e

ENV_FILE=$1
PROJECT=$2
CONFIG=$3

if [ -z "$ENV_FILE" ] || [ -z "$PROJECT" ] || [ -z "$CONFIG" ]; then
  echo "Usage: $0 <env-file> <project> <config>"
  echo "Example: $0 .env.dev ticketfi-router dev"
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: File $ENV_FILE not found"
  exit 1
fi

echo "Pushing secrets from $ENV_FILE to Doppler project: $PROJECT, config: $CONFIG"
echo ""

# Variables to skip (Doppler metadata)
SKIP_VARS="DOPPLER_CONFIG DOPPLER_ENVIRONMENT DOPPLER_PROJECT"

# Read the env file and push each secret
while IFS='=' read -r key value || [ -n "$key" ]; do
  # Skip empty lines and comments
  [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
  
  # Trim whitespace
  key=$(echo "$key" | xargs)
  
  # Skip Doppler metadata variables
  if echo "$SKIP_VARS" | grep -qw "$key"; then
    continue
  fi
  
  # Remove quotes from value if present
  if [[ "$value" =~ ^\".*\"$ ]]; then
    value=$(echo "$value" | sed 's/^"//;s/"$//')
  elif [[ "$value" =~ ^\'.*\'$ ]]; then
    value=$(echo "$value" | sed "s/^'//;s/'$//")
  fi
  
  # Trim whitespace from value
  value=$(echo "$value" | xargs)
  
  if [ -n "$key" ] && [ -n "$value" ]; then
    echo "Setting $key..."
    doppler secrets set "$key"="$value" --project "$PROJECT" --config "$CONFIG" --no-interactive > /dev/null 2>&1 || {
      echo "  ⚠️  Failed to set $key"
    }
  fi
done < "$ENV_FILE"

echo ""
echo "✅ Done pushing secrets to Doppler"


