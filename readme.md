- bind mount your .conf files (server blocks, etc.) to "/etc/nginx/templates/extra" to extend the standard configuration or "/etc/nginx/templates" if you want to entirely replace it.
- every .conf file placed directly into these folders is included automatically at the end of nginx.conf. if you wish to not load some .conf files and instead wish to instead include them manually when you need them, just put them in a subfolder so they aren't automatically loaded.
- when starting the container, any conf files in /etc/nginx/templates will have their env vars substituted with their real values and be moved to /etc/nginx/conf.d. So when using includes and
  other filesystem-related directives in you conf files, you need to use paths assuming the latter location.

# Certbot

This proxy does not come with certbot by itself, but it does provide an conf snippet (conf.d/includes/serveWellKnown.conf) that you can include in a server block which will direct all requests for the .well-known location to the folder "/well-known-webroot". You can then easily wire up certbot by bind-mounting this folder and pointing certbot to it like:

volumes:

- /etc/letsencrypt:/etc/letsencrypt
- ./some-folder:/well-known-webroot

On the host, you can then just point the "webroot-path" CLI option in certbot to "./some-folder". If certbot is also running in a container, just bind mount "./some-folder"
