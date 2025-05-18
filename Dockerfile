FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository universe && apt-get update && \
    apt-get install -y \
        shellinabox \
        apache2 \
        libapache2-mod-proxy-html2 \
        libxml2-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Ativa módulos do Apache necessários
RUN a2enmod proxy proxy_http proxy_html rewrite headers

# Exemplo simples para habilitar shellinabox na porta 4200
EXPOSE 4200

CMD service apache2 start && shellinaboxd -t -p 4200 && tail -f /dev/null
