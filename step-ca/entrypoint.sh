#!/bin/sh
set -e

PASSWORD_PATH="/home/step/.step/"
PASSWORD_FILE="password_file"
PASSWORD_FILEPATH="${PASSWORD_PATH}${PASSWORD_FILE}"

mkdir -p "${PASSWORD_PATH}"

# --- Check mandatory environment variables ---
if [ -z "$STEP_CA_PASSWORD" ] || [ -z "$ORGANISATION" ] || [ -z "$DOMAIN_SUFFIX" ] || [ -z "$TRAEFIK_EMAIL" ]; then
    echo "❌ Missing environment variables."
    echo "The following variables are required: STEP_CA_PASSWORD, ORGANISATION, DOMAIN_SUFFIX, TRAEFIK_EMAIL."
    exit 1
fi

# --- Validate DOMAIN_SUFFIX format ---
if [[ ! "$DOMAIN_SUFFIX" =~ ^\. ]]; then
    echo "FATAL ERROR: DOMAIN_SUFFIX variable is misconfigured." >&2
    echo "The DOMAIN_SUFFIX value must start with a period (e.g., .test, .local)." >&2
    echo "Current value: $DOMAIN_SUFFIX" >&2
    exit 1
fi

echo "🔧 Configuring step-ca..."
echo "   - Organisation: ${ORGANISATION}"
echo "   - Domain suffix: *${DOMAIN_SUFFIX}"

# --- Save the CA password securely ---
echo "${STEP_CA_PASSWORD}" > "${PASSWORD_FILEPATH}"
chmod 600 "${PASSWORD_FILEPATH}"

# --- Initialize step-ca if not already configured ---
if [ ! -f "/home/step/.step/config/ca.json" ]; then
    echo "🔐 Initializing Step-CA..."
    step ca init \
        --deployment-type="standalone" \
        --name="${ORGANISATION}" \
        --dns="stepca" \
        --address=":9000" \
        --provisioner="admin" \
        --password-file="${PASSWORD_FILEPATH}" \
        --provisioner-password-file="${PASSWORD_FILEPATH}" \
        --acme \
        --dns-names="${DOMAIN_SUFFIX#.}"

    echo "⚙️ Removing default JWK provisioner..."
    step ca provisioner remove admin --all || true

    echo "🔧 Adding ACME provisioner for Traefik..."
    step ca provisioner add traefik-acme --type ACME --claims='{
      "allowWildcardNames": false,
      "maxTLSCertDuration": "8760h"
    }'

    echo "✅ Step-CA successfully initialized with ACME support for ${DOMAIN_SUFFIX}"
fi

# --- Adjust permissions for root CA ---
chmod 644 /home/step/.step/certs/root_ca.crt

# --- Start Step-CA ---
echo "🚀 Starting Step-CA..."
exec step-ca --password-file "${PASSWORD_FILEPATH}"
