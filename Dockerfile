FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y shellinabox apache2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN a2enmod proxy proxy_http rewrite headers

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

RUN echo '<VirtualHost *:80>' > /etc/apache2/sites-available/000-default.conf && \
    echo '    ServerAdmin webmaster@localhost' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ProxyRequests Off' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ProxyPreserveHost On' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ProxyPass /shellinabox http://127.0.0.1:4200/' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ProxyPassReverse /shellinabox http://127.0.0.1:4200/' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    RewriteEngine On' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    RewriteCond %{REQUEST_URI} ^/shellinabox/(.*)$' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    RewriteRule ^/shellinabox/(.*)$ /$1 [P,L]' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ErrorLog ${APACHE_LOG_DIR}/error.log' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    CustomLog ${APACHE_LOG_DIR}/access.log combined' >> /etc/apache2/sites-available/000-default.conf && \
    echo '</VirtualHost>' >> /etc/apache2/sites-available/000-default.conf

EXPOSE 80

CMD service apache2 start && shellinaboxd -t --url-prefix=/shellinabox -s /:LOGIN && tail -f /var/log/apache2/access.log
