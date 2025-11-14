#!/bin/bash
# Check YAML files for quote consistency
# Enforces double quotes for strings (matching render.yaml and railway.toml style)

set -e

YAML_FILES=("router.yaml" "render.yaml" "supergraph.yaml" "railway.toml")
ERRORS=0

echo "Checking YAML quote consistency (expecting double quotes)..."

for file in "${YAML_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    continue
  fi
  
  # Check for single-quoted strings that should be double-quoted
  # Exclude comments and already-double-quoted strings
  SINGLE_QUOTES=$(grep -n "['\"].*['\"]" "$file" | grep -v "^[[:space:]]*#" | grep -E "('[^']*':|:[[:space:]]*'[^']*')" | grep -v '".*"' || true)
  
  if [ -n "$SINGLE_QUOTES" ]; then
    echo "❌ $file: Found single quotes (should use double quotes):"
    echo "$SINGLE_QUOTES" | head -5
    ERRORS=$((ERRORS + 1))
  else
    echo "✅ $file: Quote style consistent"
  fi
done

if [ $ERRORS -eq 0 ]; then
  echo ""
  echo "✅ All YAML files use consistent double quotes"
  exit 0
else
  echo ""
  echo "❌ Found $ERRORS file(s) with inconsistent quotes"
  echo "Standard: Use double quotes (\") for all string values"
  exit 1
fi

