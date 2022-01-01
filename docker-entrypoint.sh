#!/bin/bash

#
# Simple local smtp relay server based on https://xc2.wb1.xyz/post/how-to-run-a-postfix-mail-server-in-a-docker-container/
#

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_PASSWORD' 'example'
# (will allow for "$XYZ_PASSWORD_FILE" to fill in the value of
#  "$XYZ_PASSWORD" from a file, especially for Docker's secrets feature)
# copied from mariadb docker entrypoint file
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

file_env "POSTFIX_RELAY_PASSWORDr"

# Create some files
echo "$POSTFIX_HOSTNAME" >> /etc/mailname 
touch /etc/postfix/aliases

# Log to stdout
postconf -e "maillog_file=/dev/stdout"

# Update aliases database. It's not used, but postfix complains if the .db file is missing
postalias /etc/postfix/aliases

# Don't allow requests from outside
postconf -e "mynetworks=127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"

# Set up hostname
postconf -e myhostname=$POSTFIX_HOSTNAME

postconf -e "inet_protocols=ipv4"

# Relay configuration
postconf -e relayhost=$POSTFIX_RELAY_HOST
echo "$POSTFIX_RELAY_HOST $POSTFIX_RELAY_USER:$POSTFIX_RELAY_PASSWORD" >> /etc/postfix/sasl_passwd
postmap hash:/etc/postfix/sasl_passwd
postconf -e "smtp_sasl_auth_enable=yes"
postconf -e "smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd"
postconf -e "smtp_sasl_security_options=noanonymous"
postconf -e "smtp_tls_security_level=encrypt"
postconf -e "smtp_tls_CAfile=/etc/ssl/certs/ca-certificates.crt"

echo "$POSTFIX_HEADER_CHECK_RULES" >> /etc/postfix/header_check
echo "$POSTFIX_CANONICAL_MAPS" >> /etc/postfix/sender_canonical

postconf -e "smtp_header_checks=regexp:/etc/postfix/header_check"
postconf -e "sender_canonical_maps=regexp:/etc/postfix/sender_canonical"
postconf -e "sender_canonical_classes=envelope_sender, header_sender"


# Dirty hack to let the init.d script setup the chroot jail
/etc/init.d/postfix start > /dev/null 2>&1
/etc/init.d/postfix stop > /dev/null 2>&1

echo
echo 'postfix configured.: Ready for start up.'
echo

exec "$@"

