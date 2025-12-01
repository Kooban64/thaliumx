#!/bin/sh
set -e

# Ballerine Vault-integrated entrypoint
# Fetches secrets from HashiCorp Vault at container startup using Node.js

echo "Fetching secrets from Vault..."

# Use Node.js to fetch secrets from Vault
SECRETS_OUTPUT=$(node /vault-secrets.js)

if [ $? -ne 0 ]; then
  echo "ERROR: Failed to fetch secrets from Vault"
  echo "$SECRETS_OUTPUT"
  exit 1
fi

# Evaluate the export statements
eval "$SECRETS_OUTPUT"

echo "Secrets loaded successfully from Vault"
echo "BCRYPT_SALT is set: $([ -n "$BCRYPT_SALT" ] && echo 'yes' || echo 'no')"
echo "SESSION_SECRET is set: $([ -n "$SESSION_SECRET" ] && echo 'yes' || echo 'no')"
echo "API_KEY is set: $([ -n "$API_KEY" ] && echo 'yes' || echo 'no')"
echo "DB_URL is set: $([ -n "$DB_URL" ] && echo 'yes' || echo 'no')"

# Call the original docker-entrypoint.sh with the command
exec /usr/local/bin/docker-entrypoint.sh "$@"