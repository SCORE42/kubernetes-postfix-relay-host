FROM alpine:3.4

RUN apk add --no-cache \
            ca-certificates \
            libsasl \
            postfix \
            rsyslog \
            supervisor
RUN /usr/bin/newaliases

COPY . /

EXPOSE 25

ENTRYPOINT [ "/tx-smtp-relay.sh" ]

