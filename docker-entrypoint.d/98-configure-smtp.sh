#!/bin/sh

# Create msmtp config from env vars
cat > /etc/msmtprc <<EOF
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/msmtp.log

account default
host $SMTP_HOST
port $SMTP_PORT
user $SMTP_USER
from $SMTP_USER
password $SMTP_PASSWORD
EOF