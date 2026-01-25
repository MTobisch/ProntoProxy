#!/bin/sh

# Reparse template conf files
/docker-entrypoint.d/20-envsubst-on-templates.sh

# Then test
nginx -t