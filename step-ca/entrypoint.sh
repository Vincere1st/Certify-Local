#!/bin/sh
set -e

PASSWORD_PATH="/home/step/.step/"
PASSWORD_FILE="password_file"
PASSWORD_FILEPATH="${PASSWORD_PATH}${PASSWORD_FILE}"
mkdir -p "${PASSWORD_PATH}"

# Checks
if [ -z "$STEP_CA_PASSWORD" ] || [ -z "$ORGANISATION" ] || [ -z "$DOMAIN_SUFFIX" ] || [ -z "$TRAEFIK_EMAIL" ]; then
 echo "❌ Missing environment variables."
 echo "The following variables are mandatory: STEP_CA_PASSWORD, ORGANISATION, DOMAIN_SUFFIX, TRAEFIK_EMAIL."
 exit 1
fi


# Checks if DOMAIN_SUFFIX starts with a period.
if [[ ! "$DOMAIN_SUFFIX" =~ ^\. ]]; then
    echo "FATAL ERROR: DOMAIN_SUFFIX variable is misconfigured." >&2
    echo "The DOMAIN_SUFFIX value must start with a period to be valid (e.g., .test, .local)." >&2
    echo "Current value: $DOMAIN_SUFFIX" >&2
    exit 1
fi

echo "🔧 Configuring step-ca..."
echo " - Organisation: ${ORGANISATION}"
echo " - Domain: *${DOMAIN_SUFFIX}"

echo "${STEP_CA_PASSWORD}" > "${PASSWORD_FILEPATH}"
chmod 600 "${PASSWORD_FILEPATH}"

# Initialization
if [ ! -f "/home/step/.step/config/ca.json" ]; then
 echo "🔐 Initializing the CA..."
 step ca init \
 --deployment-type="standalone" \
 --provisioner="admin" \
 --name="${ORGANISATION} Development CA" \
 --dns="stepca" \
 --dns="${DOMAIN_SUFFIX}" \
 --address=":9000" \
 --password-file="${PASSWORD_FILEPATH}" \ 
 --provisioner-password-file="${PASSWORD_FILEPATH}"
 
 # Remove JWK provisioner and add ACME
 step ca provisioner remove admin --all || true
 
 echo "🔧 Adding ACME provisioner..."
 step ca provisioner add traefik-acme --type ACME
 
 echo "✅ CA successfully initialized with ACME provisioner"
fi

chmod 644 /home/step/.step/certs/root_ca.crt

echo "🚀 Starting step-ca..."
exec step-ca --password-file "${PASSWORD_FILEPATH}"
