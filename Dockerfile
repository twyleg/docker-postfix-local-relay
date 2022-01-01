FROM debian:bullseye-slim

LABEL description="postfix local relay"
MAINTAINER Torsten Wylegala <mail@twyleg.de>

RUN apt-get update && \
    apt-get install -y postfix procmail mailutils ssl-cert ca-certificates

EXPOSE 25

# Configure Postfix on startup
COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["/usr/sbin/postfix", "start-fg"]
