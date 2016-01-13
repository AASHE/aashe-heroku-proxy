FROM heroku/cedar:14

RUN mkdir -p /app/user
WORKDIR /app/user

# Install HAProxy

RUN apt-get update && apt-get install -y libssl1.0.0 libpcre3 --no-install-recommends && rm -rf /var/lib/apt/lists/*

ENV HAPROXY_MAJOR 1.5
ENV HAPROXY_VERSION 1.5.14
ENV HAPROXY_MD5 ad9d7262b96ba85a0f8c6acc6cb9edde

# see http://sources.debian.net/src/haproxy/1.5.8-1/debian/rules/ for some helpful navigation of the possible "make" arguments
RUN buildDeps='curl gcc libc6-dev libpcre3-dev libssl-dev make' \
    && set -x \
    && apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
    && curl -SL "http://www.haproxy.org/download/${HAPROXY_MAJOR}/src/haproxy-${HAPROXY_VERSION}.tar.gz" -o haproxy.tar.gz \
    && echo "${HAPROXY_MD5}  haproxy.tar.gz" | md5sum -c \
    && mkdir -p /app/user/src/haproxy \
    && tar -xzf haproxy.tar.gz -C /app/user/src/haproxy --strip-components=1 \
    && rm haproxy.tar.gz \
    && make -C /app/user/src/haproxy \
        TARGET=linux2628 \
        USE_PCRE=1 PCREDIR= \
        USE_OPENSSL=1 \
        USE_ZLIB=1 \
    PREFIX=/app/user \
        all \
        install-bin \
    && rm -rf /app/user/src/haproxy \
    && apt-get purge -y --auto-remove $buildDeps

COPY haproxy.cfg /app/user/haproxy.cfg
