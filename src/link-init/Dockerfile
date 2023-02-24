FROM alpine:latest

RUN apk add gettext openssh-client wireguard-tools python3 docker-cli;

COPY . /code

WORKDIR /code

ENTRYPOINT ["/code/entrypoint.sh"]
