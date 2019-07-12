FROM ubuntu:16.04
LABEL maintainer Ascensio System SIA <support@onlyoffice.com>

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8 DEBIAN_FRONTEND=noninteractive

RUN echo "#!/bin/sh\nexit 101" > /usr/sbin/policy-rc.d && \
    apt-get -y update && \
    apt-get -yq install wget apt-transport-https curl locales && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0x8320ca65cb2de8e5 && \
    locale-gen en_US.UTF-8 && \
    curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get -y update && \
    apt-get -yq install \
        adduser \
        bomstrip \
        htop \
        libasound2 \
        libboost-regex-dev \
        libcairo2 \
        libcurl3 \
        libgconf2-4 \
        libgtkglext1 \
        libnspr4 \
        libnss3 \
        libnss3-nssdb \
        libstdc++6 \
        libxml2 \
        libxss1 \
        libxtst6 \
        nano \
        net-tools \
        netcat \
        nginx-extras \
        nodejs \
        postgresql \
        postgresql-client \
        pwgen \
        rabbitmq-server \
        redis-server \
        software-properties-common \
        sudo \
        supervisor \
        xvfb \
        zlib1g && \
    service postgresql start && \
    sudo -u postgres psql -c "CREATE DATABASE onlyoffice;" && \
    sudo -u postgres psql -c "CREATE USER onlyoffice WITH password 'onlyoffice';" && \
    sudo -u postgres psql -c "GRANT ALL privileges ON DATABASE onlyoffice TO onlyoffice;" && \ 
    service postgresql stop && \
    service redis-server stop && \
    service rabbitmq-server stop && \
    service supervisor stop && \
    service nginx stop && \
    rm -rf /var/lib/apt/lists/*

COPY app_onlyoffice /app/onlyoffice/

EXPOSE 80 443

ARG REPO_URL="deb http://download.onlyoffice.com/repo/debian squeeze main"

RUN echo "$REPO_URL" | tee /etc/apt/sources.list.d/onlyoffice.list && \
    apt-get -y update && \
    service postgresql start && \
    dpkg --force-all -i /app/onlyoffice/onlyoffice-documentserver_amd64-v5.3.2.deb && \
    service postgresql stop && \
    service supervisor stop && \
    chmod 755 /app/onlyoffice/*.sh && \
    rm -rf /var/log/onlyoffice && \
    rm -rf /var/lib/apt/lists/* && \
    find /var/www/onlyoffice/documentserver/sdkjs-plugins/* -maxdepth 0 -type d -exec rm -rf '{}' \; && \
    cp -fpR /app/onlyoffice/documentserver/* /var/www/onlyoffice/documentserver/ && \
    chown -R ds:ds /var/www/onlyoffice/documentserver && \
    rm /app/onlyoffice/onlyoffice-documentserver_amd64-v5.3.2.deb && \
    rm -Rf /app/onlyoffice/documentserver

VOLUME /etc/onlyoffice /var/log/onlyoffice /var/lib/onlyoffice /var/www/onlyoffice/Data /var/lib/postgresql /usr/share/fonts/truetype/custom

ENTRYPOINT /app/onlyoffice/run-document-server.sh
