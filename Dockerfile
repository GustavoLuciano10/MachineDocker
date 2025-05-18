FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get install -y shellinabox apache2 libxml2-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Habilitar módulos necessários do Apache
RUN a2enmod proxy proxy_http rewrite headers

# Copiar configuração customizada do Apache para proxy reverso Shellinabox
COPY shellinabox-proxy.conf /etc/apache2/sites-available/000-default.conf

# Expor apenas porta 80 do Apache
EXPOSE 80

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
