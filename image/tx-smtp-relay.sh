#!/bin/sh

TX_SMTP_RELAY_HOST=${TX_SMTP_RELAY_HOST?Missing env var TX_SMTP_RELAY_HOST}
TX_SMTP_RELAY_MYHOSTNAME=${TX_SMTP_RELAY_MYHOSTNAME?Missing env var TX_SMTP_RELAY_MYHOSTNAME}
TX_SMTP_RELAY_USERNAME=${TX_SMTP_RELAY_USERNAME?Missing env var TX_SMTP_RELAY_USERNAME}
TX_SMTP_RELAY_PASSWORD=${TX_SMTP_RELAY_PASSWORD?Missing env var TX_SMTP_RELAY_PASSWORD}


# handle sasl
echo "${TX_SMTP_RELAY_HOST} ${TX_SMTP_RELAY_USERNAME}:${TX_SMTP_RELAY_PASSWORD}" > /etc/postfix/sasl_passwd || exit 1
postmap /etc/postfix/sasl_passwd || exit 1
rm /etc/postfix/sasl_passwd || exit 1


cat << EOF > /etc/postfix/generic
do-not-reply@${TX_REWRITE_FROM_DOMAIN:-example.com}}  do-not-reply@${TX_RELAY_DOMAIN:-example.net}
@${TX_REWRITE_FROM_DOMAIN:-example.com}  do-not-reply@${TX_RELAY_DOMAIN:-example.net}
EOF


postconf 'smtp_sasl_auth_enable = yes' || exit 1
postconf 'smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd' || exit 1
postconf 'smtp_sasl_security_options = noanonymous' || exit 1
postconf 'smtp_use_tls = yes' || exit 1
postconf 'smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt' || exit 1

# These are required.
postconf "relayhost = ${TX_SMTP_RELAY_HOST}" || exit 1
postconf "myhostname = ${TX_SMTP_RELAY_MYHOSTNAME}" || exit 1
postconf "mydomain = ${TX_RELAY_DOMAIN}" || exit 1
postconf "smtp_generic_maps = hash://etc/postfix/generic" || exit 1
postmap /etc/postfix/generic || exit 1


# Override what you want here. The 10. network is for kubernetes and the 100. is for k8s services
postconf 'mynetworks = 10.0.0.0/8,127.0.0.0/8,172.17.0.0/16,100.0.0.0/8' || exit 1

# http://www.postfix.org/COMPATIBILITY_README.html#smtputf8_enable
postconf 'smtputf8_enable = no' || exit 1

# This makes sure the message id is set. If this is set to no dkim=fail will happen.
postconf 'always_add_missing_headers = yes' || exit 1



/usr/bin/supervisord -n
