# Pronto Proxy

This is a small, nginx-based webserver Docker image that can be used to quickly set up an reverse proxy on any server.

It aims to remain maximally flexible (by allowing any nginx configuration to be loaded) and comes with the typical nginx configuration options built in to take away some of the tedium.

It also provides many optional configuration snippets for frequently needed tasks that can be included with one line in your server configs.

## Usage

Let's assume a simple server configuration with a proxy pass:

```
server {
  listen 80;
  listen [::]:80;

  server_name mydomain.com;

  location / {
    set $proxyTarget http://some-other-server:80;
    include conf.d/includes/proxyPass.conf;
  }
}
```

In this, we're setting the `$proxyTarget` variable to the target url and then load the helper snippet `conf.d/includes/proxyPass.conf` to handle the rest of the proxy pass. There are many more of such "convenience"-snippets that can be included in the `conf/templates/includes` folder of this repo.

Now simply start a container from the docker image and mount your custom nginx `.conf` files into it. There are two options:

- Bind mount the conf files into `/etc/nginx/templates/extra` to extend the standard configuration.
- Bind mount the conf files into `/etc/nginx/templates` directly to replace the standard configuration.

Every `.conf` file placed directly into these folders will have its environment variables substituted with their real values and will automatically be included at the end of `nginx.conf`.

A minimal Docker compose config might then look like this:

```
services:
  proxy:
    image: mtobisch/pronto-proxy
    ports:
      - 80:80
    volumes:
      - ./conf:/etc/nginx/templates/extra
```

**Note:** When starting the container, any `.conf` files in `/etc/nginx/templates` will be moved to `/etc/nginx/conf.d`. This is important to keep in mind when using `include` and other filesystem-related directives (you need to use paths assuming the latter location).

## Scripts

This image comes with a couple of utility scripts that can be found in the `/scripts`-folder, most notably:

- `test.sh` to test the nginx configuration
- `reload.sh` to reload the nginx configuration
- `maintenance-enable.sh`/`maintenance-disable.sh` to toggle the maintenance page of a server (see: `conf/templates/includes/maintenanceMode.conf`)

From outside the container, these can simply be called for example via `docker exec pronto-proxy /scripts/reload.sh`.

## Certbot & SSL

This proxy does not come with certbot by itself, but can be used with it easily. A sample server configuration with SSL enabled might look like this:

```
server {
  listen 80;
  listen [::]:80;
  listen 443 ssl;
  listen [::]:443 ssl;

  server_name         mydomain.com;
  ssl_certificate     /dummycert/fullchain.pem;
  ssl_certificate_key /dummycert/privkey.pem;

  include conf.d/includes/serveWellKnown.conf;

  location / {
    set $proxyTarget http://some-other-server:80;
    include conf.d/includes/proxyPass.conf;
  }
}
```

This image comes with self-signed dummy certs, so you can use those temporarily while we fetch the real ones.

By including the `conf.d/includes/interceptAcme.conf` snippet in your server block, all http requests to `/.well-known/acme-challenge` use the `/acme` folder as its webroot. You can then simply bind-mount that folder so certbot can access it from the host. In addition, you should also bind-mount the `/etc/letsencrypt` folder, so the certificates aren't lost on container restarts.

The final "volumes" config in docker compose would then look like so:

```
volumes:
- ./conf:/etc/nginx/templates/extra
- ./acme:/acme
- /etc/letsencrypt:/etc/letsencrypt
```

When fetching the certificates on the host, you can then just point the "webroot-path" CLI option in certbot to `./acme`.

```
certbot certonly --webroot --webroot-path ./acme -d mydomain.com -m me@mydomain.com --agree-tos
```

**Note:** If certbot is running in a container too, you will have to bind mount the `./acme` and `/etc/letsencrypt` folders from the host into the certbot container as well and point the webroot-path option to wherever your have mounted it at.

When everything worked, just replace the dummy certificates in your server config with the actual ones you just received and make sure to refresh the certificates regularly by calling `certbot renew` via a method of your choosing (cronjob, etc.).

## Auto-reload

The server will gracefully auto-reload every 7 days to load new configuration and potentially new certificates (see section above).

Before doing this, it checks if the configuration is valid before attempting the reload and has the ability to send an e-mail if it is not. For this, the following environment variables must be set for the container:

```
EMAIL=YOUR_MAIL_ADDRESS
SMTP_HOST=YOUR_SMTP_HOST
SMTP_PORT=YOUR_SMTP_PORT
SMTP_USER=YOUR_SMTP_USER
SMTP_PASSWORD=YOUR_SMTP_PASSWORD
```
