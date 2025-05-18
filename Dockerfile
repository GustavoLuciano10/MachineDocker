FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependências
RUN apt-get update && \
    apt-get install -y \
    apache2 \
    git \
    build-essential \
    autoconf \
    libtool \
    libssl-dev \
    zlib1g-dev \
    pkg-config \
    libpam0g-dev \
    libwrap0-dev \
    libglib2.0-dev \
    libxml2-dev \
    libjson-c-dev \
    curl

# Baixar e compilar o shellinabox com suporte a --static-url-prefix
WORKDIR /opt
RUN git clone https://github.com/shellinabox/shellinabox.git && \
    cd shellinabox && \
    autoreconf -i && \
    ./configure && \
    make && \
    make install

# Ativa módulos necessários no Apache
RUN a2enmod proxy proxy_http rewrite headers

# Configura Apache para servir Shellinabox em /shellinabox
RUN echo '<VirtualHost *:80>' > /etc/apache2/sites-available/000-default.conf && \
    echo '    ServerAdmin webmaster@localhost' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ProxyRequests Off' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ProxyPreserveHost On' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ProxyPass /shellinabox http://127.0.0.1:4200/shellinabox' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ProxyPassReverse /shellinabox http://127.0.0.1:4200/shellinabox' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ErrorLog \${APACHE_LOG_DIR}/error.log' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    CustomLog \${APACHE_LOG_DIR}/access.log combined' >> /etc/apache2/sites-available/000-default.conf && \
    echo '</VirtualHost>' >> /etc/apache2/sites-available/000-default.conf

EXPOSE 80

# Inicia apache2 + shellinabox com caminho customizado
CMD service apache2 start && \
    shellinaboxd --no-beep --disable-ssl --static-url-prefix=/shellinabox/ -s /:LOGIN && \
    tail -f /var/log/apache2/access.log
