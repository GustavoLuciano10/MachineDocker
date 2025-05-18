FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common \
    iproute2 \
    net-tools \
    openjdk-8-jdk-headless \
    supervisor \
    wget \
    unzip \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Instala Docker (Docker-in-Docker)
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" && \
    apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io && \
    rm -rf /var/lib/apt/lists/*

# Instala dependências para Android (simplificado)
RUN apt-get update && apt-get install -y \
    dbus-x11 \
    xvfb \
    x11vnc \
    fluxbox \
    && rm -rf /var/lib/apt/lists/*

# Configura supervisord.conf embutido
RUN echo "[supervisord]" > /etc/supervisor/conf.d/supervisord.conf && \
    echo "nodaemon=true" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "[program:docker]" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "command=/usr/bin/dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "priority=10" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "autostart=true" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "autorestart=true" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "stderr_logfile=/var/log/docker.err.log" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "stdout_logfile=/var/log/docker.out.log" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "[program:android]" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "command=/bin/bash -c \"/start-android.sh\"" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "priority=20" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "autostart=true" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "autorestart=true" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "stderr_logfile=/var/log/android.err.log" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "stdout_logfile=/var/log/android.out.log" >> /etc/supervisor/conf.d/supervisord.conf

# Expor portas (modifique conforme sua necessidade)
EXPOSE 6080 5554 5555 2375

# Você precisa criar o /start-android.sh (copiar ou criar via RUN) que inicializa o Android

CMD ["/usr/bin/supervisord", "-n"]
