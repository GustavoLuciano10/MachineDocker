FROM ubuntu:20.04

RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository universe && apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    shellinabox \
    apache2 \
    libapache2-mod-proxy-html \
    libxml2-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo 'root:root' | chpasswd

RUN a2enmod proxy proxy_http

RUN echo '<VirtualHost *:80>\n\
    ProxyPreserveHost On\n\
    ProxyPass /shell http://localhost:4200/\n\
    ProxyPassReverse /shell http://localhost:4200/\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

EXPOSE 80

CMD service shellinabox start && apachectl -D FOREGROUND
