FROM ubuntu:20.04

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get install -y shellinabox apache2 libxml2-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN a2enmod proxy proxy_http rewrite headers

# Criar arquivo de configuração do Apache para proxy reverso do shellinabox
RUN cat << EOF > /etc/apache2/sites-available/000-default.conf \
<VirtualHost *:80>
    ServerAdmin webmaster@localhost

    ProxyRequests Off
    ProxyPreserveHost On

    ProxyPass /shellinabox http://127.0.0.1:4200/
    ProxyPassReverse /shellinabox http://127.0.0.1:4200/

    RewriteEngine On
    RewriteCond %{REQUEST_URI} ^/shellinabox/(.*)$
    RewriteRule ^/shellinabox/(.*)$ /$1 [P,L]

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

EXPOSE 80

CMD ["apachectl", "-D", "FOREGROUND"]
