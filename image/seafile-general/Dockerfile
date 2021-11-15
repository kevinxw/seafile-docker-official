ARG SYSTEM=focal

# See https://hub.docker.com/r/phusion/baseimage/tags/
FROM phusion/baseimage:${SYSTEM}-1.0.0
ARG SEAFILE_VERSION
ENV SEAFILE_SERVER=seafile-server SEAFILE_VERSION=${SEAFILE_VERSION}

ARG TARGETARCH

RUN apt-get update --fix-missing && \
    # Utility tools
    apt-get install -y vim htop net-tools psmisc wget curl git && \
    # For suport set local time zone.
    export DEBIAN_FRONTEND=noninteractive && apt-get install tzdata -y && \
    # Nginx
    apt-get install -y nginx && \
    # Mysqlclient
    apt-get install -y libmysqlclient-dev && \
    # Memcache
    apt-get install -y libmemcached11 libmemcached-dev && \
    # Fuse
    apt-get install -y fuse && \
    # Python3
    apt-get install -y python3 python3-pip python3-setuptools && \
    rm -f /usr/bin/python && ln -s /usr/bin/python3 /usr/bin/python && \
    python3 -m pip install --upgrade pip && rm -r /root/.cache/pip && \
    pip3 install --timeout=3600 click termcolor colorlog pymysql \
      django==2.2.* && rm -r /root/.cache/pip && \
    pip3 install --timeout=3600 future mysqlclient Pillow pylibmc captcha jinja2 \
    sqlalchemy django-pylibmc django-simple-captcha pyjwt && \
    rm -r /root/.cache/pip

# Seafile
WORKDIR /opt/seafile

# Scripts
COPY scripts /scripts
COPY templates /templates
COPY services /services
RUN chmod u+x /scripts/* && \
    mkdir -p /etc/my_init.d && \
    rm -f /etc/my_init.d/* && \
    cp /scripts/create_data_links.sh /etc/my_init.d/01_create_data_links.sh && \
    mkdir -p /etc/service/nginx && \
    rm -f /etc/nginx/sites-enabled/* /etc/nginx/conf.d/* && \
    mv /services/nginx.conf /etc/nginx/nginx.conf && \
    mv /services/nginx.sh /etc/service/nginx/run && \
    case "${TARGETARCH}" in \
    "amd64") \
      SEAFILE_URL="https://download.seadrive.org/seafile-server_${SEAFILE_VERSION}_x86-64.tar.gz" ;; \
    "arm64") \
      SEAFILE_URL="https://github.com/haiwen/seafile-rpi/releases/download/v${SEAFILE_SERVER_VERSION}/seafile-server-${SEAFILE_VERSION}-${SYSTEM}-arm64v8.tar.gz" ;; \
    "arm") \
      SEAFILE_URL="https://github.com/haiwen/seafile-rpi/releases/download/v${SEAFILE_VERSION}/seafile-server-${SEAFILE_VERSION}-${SYSTEM}-armv7l.tar.gz" ;; \
    esac ; \
    mkdir -p /opt/seafile/ && cd /opt/seafile/ && \
    wget -c "${SEAFILE_URL}" -O seafile-server.tar.gz && \
    tar -zxvf seafile-server.tar.gz && \
    rm -f seafile-server.tar.gz && \
    # For using TLS connection to LDAP/AD server with docker-ce.
    find /opt/seafile/ \( -name "liblber-*" -o -name "libldap-*" -o -name "libldap_r*" -o -name "libsasl2.so*" -o -name "libcrypt.so.1" \) -delete


EXPOSE 80


CMD ["/sbin/my_init", "--", "/scripts/enterpoint.sh"]
