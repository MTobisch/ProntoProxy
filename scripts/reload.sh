#!/bin/sh

# Reparse template conf files
/docker-entrypoint.d/20-envsubst-on-templates.sh

# Test first if conf works, then reload
nginx -t && nginx -s reload