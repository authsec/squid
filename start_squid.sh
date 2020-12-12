#!/bin/sh

set -e

SQUID_USER="squid"
SQUID_GROUP="squid"
SQUID="/usr/sbin/squid"
SQUID_LOG_DIR="/var/log/squid"
# We'll overlay this folder later, so we can keep the cache after restarts
SQUID_CACHE_DIR="/var/cache/squid"

# Please note if you change these file locations, that you need to adopt the squid.conf file appropriately
PROXY_CA_KEY="/etc/ssl/proxy/private/proxy-ca.key"
PROXY_CA_CERT="/etc/ssl/proxy/certs/proxy-ca.crt"

generate_root_ca() {
  if ! { [ -f ${PROXY_CA_KEY} ] && [ -f ${PROXY_CA_CERT} ]; }
  then
    echo "Generating a proxy CA certificate with key"
    libressl genrsa -out ${PROXY_CA_KEY} 4096
    libressl req -x509 -new -nodes -key ${PROXY_CA_KEY} -subj "/CN=authsec Squid Proxy Root CA/C=DE/ST=Baden-Wuerttemberg/L=Loerrach/O=CoffeeCrew/OU=authsec" -sha256 -days 1024 -out ${PROXY_CA_CERT}
  else
    echo "Found a proxy CA certificate with key"
  fi
}

serve_public_cert_folder() {
  if [ "${SERVE_CA_CERT}" != "false" ]
  then
    echo "!!! DO NOT USE THIS IN A PRODUCTIVE SETUP !!!"
    echo "!!! This is supposed to be used in a LAB environment ONLY !!!"

    cd $(dirname ${PROXY_CA_CERT})
    nohup python3 -m http.server 8000 &
  fi
}

setup_cache() {
  echo "Creating cache folder"
  mkdir -p "${SQUID_CACHE_DIR}"

  # Init the cache (use X to "watch" the process and basically stop until it is set up)
  ${SQUID} -zX

  sleep 5
  
  chown -R ${SQUID_USER}:${SQUID_GROUP} "${SQUID_CACHE_DIR}"
}

create_log_folders() {
  echo "Creating log folder"
  mkdir -p "${SQUID_LOG_DIR}"
  chown -R ${SQUID_USER}:${SQUID_GROUP} "${SQUID_LOG_DIR}"
}

create_certs_db() {
  echo "Removing the cert DB"
  rm -rf /var/lib/ssl_db

  # For squid 4.x
  echo "Preparing the cert DB"
  /usr/lib/squid/security_file_certgen -c -s /var/lib/ssl_db -M 4MB
  chown ${SQUID_USER}:${SQUID_GROUP} -R /var/lib/ssl_db
}

generate_root_ca
create_log_folders
setup_cache
create_certs_db

# Please remember to publish port 8000, so you can access the certificate
serve_public_cert_folder

echo "Starting Squid ..."
exec "$SQUID" -NYCd 1 