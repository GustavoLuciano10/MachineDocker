FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Instala dependências para compilar e rodar shellinabox + apache
RUN apt-get update && apt-get install -y \
    git build-essential cmake pkg-config libssl-dev libpam0g-dev libprotobuf-dev protobuf-compiler apache2 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Clona e compila shellinabox (versão atual do GitHub)
RUN git clone https://github.com/shellinabox/shellinabox.git /tmp/shellinabox && \
    cd /tmp/shellinabox && \
    mkdir build && cd build && \
    cmake .. && make && make install && \
    rm -rf /tmp/shellinabox

# Habilita módulos apache necessários
RUN a2enmod proxy proxy_http rewrite headers

# Define ServerName para evitar warnings
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Configura Apache para proxy reverso shellinabox
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
