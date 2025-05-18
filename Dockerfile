FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get install -y shellinabox apache2 libxml2-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Habilitar módulos do Apache para proxy reverso
RUN a2enmod proxy proxy_http rewrite headers

# Criar arquivo de configuração do Apache para proxy reverso do shellinabox
RUN printf '<VirtualHost *:80>\n\
    ServerAdmin webmaster@localhost\n\
\n\
    ProxyRequests Off\n\
    ProxyPreserveHost On\n\
\n\
    ProxyPass /shellinabox http://127.0.0.1:4200/\n\
    ProxyPassReverse /shellinabox http://127.0.0.1:4200/\n\
\n\
    RewriteEngine On\n\
    RewriteCond %{REQUEST_URI} ^/shellinabox/(.*)$\n\
    RewriteRule ^/shellinabox/(.*)$ /$1 [P,L]\n\
\n\
    ErrorLog ${APACHE_LOG_DIR}/error.log\n\
    CustomLog ${APACHE_LOG_DIR}/access.log combined\n\
</VirtualHost>\n' > /etc/apache2/sites-available/000-default.conf

EXPOSE 80

CMD service shellinabox start && apachectl -D FOREGROUND
