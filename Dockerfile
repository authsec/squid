FROM alpine:3.12
LABEL maintainer="jens.frey@coffeecrew.org"

ENV SERVE_CA_CERT=${SERVE_CA_CERT:-false}

COPY additional_cas /tmp/additional_cas

RUN apk add --no-cache squid \
  ca-certificates \
  libressl \
  python3 \
  wget \
  && \
  tr '\n' < /tmp/additional_cas | xargs -n 1 wget -P /usr/local/share/ca-certificates -c \
  && \
  update-ca-certificates

COPY start_squid.sh /usr/local/bin/start_squid.sh
COPY squid.conf /etc/squid/squid.conf

RUN mkdir -p /etc/ssl/proxy/certs /etc/ssl/proxy/private && chown squid:squid /etc/ssl/proxy
RUN chmod 0755 /usr/local/bin/start_squid.sh

# Standard proxy port, needs no CA installation in browser
EXPOSE 3128
# TLS/SSL intercepting proxy port, needs CA installation in browser
EXPOSE 4128

# Used for the SERVE_CA_CERT option
EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/start_squid.sh"]