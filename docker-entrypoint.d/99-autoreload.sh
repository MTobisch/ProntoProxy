#!/bin/sh

# Auto-reload nginx
while :; do
  sleep 7d

  echo "Autoreload: Reloading nginx per scheduled intverval..."

  OUT=$(nginx -t 2>&1)
  EXIT_CODE=$?

  if [ $EXIT_CODE -ne 0 ]; then
    echo "Autoreload: Tried reloading nginx, but nginx config test failed. Aborting." >&2
    echo "$OUT" >&2

    # Send email notification on failure
    if [ -n "$EMAIL" ] && [ -n "$SMTP_HOST" ] && [ -n "$SMTP_USER" ] && [ -n "$SMTP_PASSWORD" ]; then
      (
      echo "From: $SMTP_USER"
      echo "To: $EMAIL"
      echo "Subject: Nginx-Autoreload failed on $HOSTNAME"
      echo "Content-Type: text/plain; charset=UTF-8"
      echo ""
      echo "Tried validating nginx config before reload and failed! Reload cancelled. Output of 'nginx -t':"
      echo ""
      echo "$OUT"
      ) | msmtp $EMAIL
    fi
  else
    nginx -s reload
    echo "Autoreload: Nginx reloaded."
  fi

done & # <-- Run as background process