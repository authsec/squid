# Squid with SSL/TLS Proxying

This container provides a Squid 4 proxy based on Alpine Linux.

It allows you to proxy TLS/SSL connections by breaking up the TLS connection. In order to do this, the container will generate a certificate for the requested site on the fly.

In order to properly access this from your browser you need to have the CA certificate installed that generates the certificates. 

I trust you know how to do that if you are using this container.

The container will break open the TLS connection if you configure your browser using port 4128. If you configure your browser on port 3128 it will behave like a regular old squid proxy.

**NOTE:** If you want to keep the cached files on your host OS as well, you need to mount a directory on your host to `/var/cache/squid` e.g. `-v /var/opt/squid/cache:/var/cache/squid`.

# CA Certificates

If you do not bind mount a CA certificate alongside its key into the container on `/etc/ssl/proxy/certs/proxy-ca.crt` and `/etc/ssl/proxy/private/proxy-ca.key` accordingly, the container will generate a keypair you can use for testing/lab/home purposes.

## Generate a CA for me

If you want the certificate generated and be able to download the CA-certificate from the host on port 8000 (e.g. `http://localhost:8000`), you can start the container as follows:

``` bash
#$> docker run -e SERVE_CA_CERT=true --rm --name squid -p8000:8000 -p3128:3128 -p4128:4128 authsec/squid
```

If you do want to keep the generated certificates, so you do not have to import a new root CA into your browser on every restart, you can start the container like so:

``` bash
#$> mkdir cacerts
#$> mkdir cakeys
#$> docker run -e SERVE_CA_CERT=true --rm --name squid -p8000:8000 -p3128:3128 -p4128:4128 -v$(pwd)/cacerts:/etc/ssl/proxy/certs -v$(pwd)/cakeys:/etc/ssl/proxy/private/ authsec/squid
```

## I have a CA already

In this case you obviously do not need to access the certificate and don't need them generated. However, make sure you do set both, the certificate and the key. If you only set one of them you certificate may be overridden. 

You can run the container like so (in this example the `ca.crt` and `ca.key` file obviously have to exist in the directory you're starting the container from):

``` bash
#$> docker run --rm --name squid -p3128:3128 -p4128:4128 -v"$(pwd)/ca.crt":/etc/ssl/proxy/certs/proxy-ca.crt -v"$(pwd)/ca.key":/etc/ssl/proxy/private/proxy-ca.key authsec/squid
```

# I want my own squid.conf

No problem. This is what I'd suggest anyway, so you can exclude TLS/SSL traffic to banking sites etc. from being intercepted by the proxy.

In this case copy the `squid.conf` file form the repository and adopt the `acl serverIsBank` settings to fit your needs. I suggest seeing [the squid homepage](http://www.squid-cache.org/) for further details.

After you have put together a proper `squid.conf` configuration file in the same directory where you have created the `cacerts` and `cakeys` folder, you can mount it into the container like so (when using the generate and keep CA approach):

``` bash
#$> docker run -e SERVE_CA_CERT=true --rm --name squid -p8000:8000 -p3128:3128 -p4128:4128 -v$(pwd)/squid.conf:/etc/squid/squid.conf -v$(pwd)/cacerts:/etc/ssl/proxy/certs -v$(pwd)/cakeys:/etc/ssl/proxy/private/ authsec/squid
```

