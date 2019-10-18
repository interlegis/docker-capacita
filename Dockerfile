#!/bin/sh
FROM alpine:3.7

ENV BUILD_PACKAGES postgresql-dev graphviz-dev graphviz build-base git pkgconfig \
python3-dev libxml2-dev jpeg-dev libressl-dev libffi-dev libxslt-dev nodejs py3-lxml \
py3-magic postgresql-client poppler-utils antiword vim

ENV CAPACITA_VERSION=1.0.0-64 \
    CAPACITA_URL=https://github.com/interlegis/capacita.git

RUN apk update --update-cache && apk upgrade

RUN apk --update add fontconfig ttf-dejavu && fc-cache -fv

RUN apk add --no-cache python3 nginx tzdata && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    rm -r /root/.cache && \
    rm -f /etc/nginx/conf.d/*

RUN mkdir -p /var/interlegis/capacita && \
    apk add --update --no-cache $BUILD_PACKAGES && \
    npm install -g bower && \
    npm cache verify

RUN cd /tmp \
 && git clone ${CAPACITA_URL} --depth=1 --branch ${CAPACITA_VERSION} \
 && mv /tmp/capacita /var/interlegis

WORKDIR /var/interlegis/capacita/

COPY capacita.sql  /var/interlegis/capacita/
COPY start.sh /var/interlegis/capacita/
COPY busy-wait.sh /var/interlegis/capacita/
COPY create_admin.py /var/interlegis/capacita/
COPY genkey.py /var/interlegis/capacita/
COPY gunicorn_start.sh /var/interlegis/capacita/
COPY config/nginx/capacita.conf /etc/nginx/conf.d
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf

RUN pip install -r /var/interlegis/capacita/requirements.txt --upgrade setuptools && \
    rm -r /root/.cache
COPY config/env_dockerfile /var/interlegis/capacita/.env

#RUN python3 manage.py compilescss

#RUN python3 manage.py collectstatic --noinput --clear

# Remove .env(fake) e capacita.db da imagem
RUN rm -rf /var/interlegis/capacita/.env && \
    rm -rf /var/interlegis/capacita/capacita.db

RUN chmod +x /var/interlegis/capacita/start.sh && \
    chmod +x /var/interlegis/capacita/busy-wait.sh && \
    chmod +x /var/interlegis/capacita/gunicorn_start.sh && \
    ln -sf /proc/self/fd/1 /var/log/nginx/access.log && \
    ln -sf /proc/self/fd/1 /var/log/nginx/error.log && \
    mkdir /var/log/capacita/

VOLUME ["/var/interlegis/capacita/data", "/var/interlegis/capacita/media"]

CMD ["/var/interlegis/capacita/start.sh"]
