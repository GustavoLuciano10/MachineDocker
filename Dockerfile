FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Instala pacotes necessários
RUN apt-get update && apt-get install -y \
    shellinabox apache2 libapache2-mod-proxy-html libxml2-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Ativa os módulos do Apache
RUN a2enmod proxy proxy_http rewrite headers

# Define ServerName para evitar warning do Apache
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Configura o Apache para proxy reverso na raiz (/) para o shellinabox (porta 4200)
RUN echo '<VirtualHost *:80>' > /etc/apache2/sites-available/000-default.conf && \
    echo '    ServerAdmin webmaster@localhost' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ProxyRequests Off' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ProxyPreserveHost On' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ProxyPass / http://127.0.0.1:4200/' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ProxyPassReverse / http://127.0.0.1:4200/' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    RewriteEngine On' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ErrorLog ${APACHE_LOG_DIR}/error.log' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    CustomLog ${APACHE_LOG_DIR}/access.log combined' >> /etc/apache2/sites-available/000-default.conf && \
    echo '</VirtualHost>' >> /etc/apache2/sites-available/000-default.conf

EXPOSE 80

# Inicia o apache e o shellinabox (sem url-prefix), mantendo o log rodando para o container não fechar
CMD service apache2 start && shellinaboxd -t -s /:LOGIN && tail -f /var/log/apache2/access.log
