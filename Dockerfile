FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get install -y \
        shellinabox \
        apache2 \
        libxml2-dev \
        libapache2-mod-proxy-html \
        libapache2-mod-substitute \
        libapache2-mod-headers && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN a2enmod proxy proxy_http proxy_html substitute headers

# Corrigir mensagem de "ServerName"
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Configuração do Apache com reescrita de caminho
RUN echo '<VirtualHost *:80>' > /etc/apache2/sites-available/000-default.conf && \
    echo '    ServerAdmin webmaster@localhost' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ProxyRequests Off' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ProxyPreserveHost On' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ProxyPass /shellinabox http://127.0.0.1:4200/' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ProxyPassReverse /shellinabox http://127.0.0.1:4200/' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    <Location /shellinabox>' >> /etc/apache2/sites-available/000-default.conf && \
    echo '        AddOutputFilterByType SUBSTITUTE text/html' >> /etc/apache2/sites-available/000-default.conf && \
    echo '        Substitute "s|/shellinabox/|/shellinabox/|ni"' >> /etc/apache2/sites-available/000-default.conf && \
    echo '        Substitute "s|/|/shellinabox/|ni"' >> /etc/apache2/sites-available/000-default.conf && \
    echo '        RequestHeader unset Accept-Encoding' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    </Location>' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ErrorLog ${APACHE_LOG_DIR}/error.log' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    CustomLog ${APACHE_LOG_DIR}/access.log combined' >> /etc/apache2/sites-available/000-default.conf && \
    echo '</VirtualHost>' >> /etc/apache2/sites-available/000-default.conf

EXPOSE 80

CMD service apache2 start && \
    shellinaboxd -t -s /:LOGIN && \
    tail -f /var/log/apache2/access.log
