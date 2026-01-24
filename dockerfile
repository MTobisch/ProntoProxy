FROM nginx:1.27.4-alpine

# Update packages
RUN apk update
RUN apk add openssl msmtp

# Default to production environment
ENV APP_ENV=prod

# Copy over maintenance files
COPY ./maintenance/ /maintenance
RUN chmod +x /maintenance/enable.sh && chmod +x /maintenance/disable.sh

# For serveWellKnown.conf. Intercepts requests to /.well-known and serves them from here for certbot validation.
RUN mkdir /well-known-webroot

# Configs
# ----------------------------------

RUN rm /etc/nginx/conf.d/default.conf

# Nginx does not natively work with env vars. The docker image however includes a process where "template" config files have their env vars replaced with the 
# actual values and the result copied into the real conf folder. E.g. /etc/nginx/templates/test.conf automatically becomes /etc/nginx/conf.d/test.conf.
# This defines the file suffix to recognize those template files by.
ENV NGINX_ENVSUBST_TEMPLATE_SUFFIX=.conf

# Copy over Nginx configs
COPY ./conf/nginx.conf /etc/nginx/nginx.conf
COPY ./conf/templates/ /etc/nginx/templates/
COPY ./conf/templates/includes /etc/nginx/templates/includes

# To prevent the template logic from removing the suffix from the template files
RUN sed -i 's|output_path="$output_dir/${relative_path%"$suffix"}"|output_path="$output_dir/$relative_path"|g' /docker-entrypoint.d/20-envsubst-on-templates.sh

# Entrypoint
# ----------------------------------

# Add additional init scripts
COPY ./docker-entrypoint.d/97-create-dummy-certs.sh /docker-entrypoint.d/97-create-dummy-certs.sh
RUN chmod +x /docker-entrypoint.d/97-create-dummy-certs.sh

COPY ./docker-entrypoint.d/98-configure-smtp.sh /docker-entrypoint.d/98-configure-smtp.sh
RUN chmod +x /docker-entrypoint.d/98-configure-smtp.sh

COPY ./docker-entrypoint.d/99-autoreload.sh /docker-entrypoint.d/99-autoreload.sh
RUN chmod +x /docker-entrypoint.d/99-autoreload.sh

# Send proper stop signal on close
STOPSIGNAL SIGTERM