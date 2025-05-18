FROM ubuntu:20.04

# Instala os pacotes necessários
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    shellinabox \
    apache2 \
    libapache2-mod-proxy-html \
    libxml2-dev \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Define senha do root
RUN echo 'root:root' | chpasswd

# Ativa os módulos do Apache necessários para proxy
RUN a2enmod proxy proxy_http

# Cria o arquivo de configuração do Apache para proxy
RUN echo '<VirtualHost *:80>\n\
    ProxyPreserveHost On\n\
    ProxyPass /shell http://localhost:4200/\n\
    ProxyPassReverse /shell http://localhost:4200/\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Expor apenas a porta do Apache
EXPOSE 80

# Comando para iniciar tanto o Apache quanto o Shellinabox
CMD service shellinabox start && apachectl -D FOREGROUND
