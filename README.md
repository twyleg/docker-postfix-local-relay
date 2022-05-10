# Postfix local relay

Docker image based on Debian to provide a simple postfix local relay server that can be used by other applications/containers to send emails through an external provider.

## Example compose file

	version: '3.8'

	services:
	  postfix:
	    image: twyleg/postfix-local-relay
	    restart: always
	    ports:
	      - 127.0.0.1:25:25
	    environment:
		POSTFIX_HOSTNAME: "<SENDER_HOSTNAME>"
		POSTFIX_RELAY_HOST: "[<SMTP_SERVER_HOSTNAME]:587"
		POSTFIX_RELAY_USER: "<SMTP_USERNAME>"
		POSTFIX_HEADER_CHECK_RULES: "/From:.*/ REPLACE From: <SENDER_MAILADRESS>"
		POSTFIX_CANONICAL_MAPS: "/.+/ <SENDER_MAILADRESS>"
		POSTFIX_RELAY_PASSWORD_FILE: /run/secrets/postfix_relay_password
	    secrets:
	      - postfix_relay_password
	secrets:
	  postfix_relay_password:
	    file: ./secrets/postfix_relay_password.txt

Put your SMTP-Password into into **./secrets/postfix_relay_password.txt**

## References

Heavily influenced by the following blog post:
https://xc2.wb1.xyz/post/how-to-run-a-postfix-mail-server-in-a-docker-container/ 
