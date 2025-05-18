FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99

# Instala dependências básicas e supervisor, xvfb, x11vnc, java etc.
RUN apt-get update && apt-get install -y \
    wget \
    git \
    curl \
    supervisor \
    xvfb \
    x11vnc \
    python3-pip \
    openjdk-11-jdk \
    libglu1-mesa \
    xterm \
    && rm -rf /var/lib/apt/lists/*

# Instala websockify via pip
RUN pip3 install websockify

# Clona o repositório docker-android para /opt/docker-android
RUN git clone https://github.com/budtmo/docker-android.git /opt/docker-android

# Cria o arquivo de configuração do supervisor com heredoc para evitar erro de quebra de linha
RUN mkdir -p /etc/supervisor/conf.d/ && \
    cat <<EOF > /etc/supervisor/conf.d/supervisord.conf
[supervisord]
nodaemon=true

[program:xvfb]
command=/usr/bin/Xvfb :99 -screen 0 1280x720x16
autostart=true
autorestart=true
stdout_logfile=/var/log/xvfb.log
stderr_logfile=/var/log/xvfb.err

[program:x11vnc]
command=/usr/bin/x11vnc -display :99 -nopw -forever -shared
autostart=true
autorestart=true
stdout_logfile=/var/log/x11vnc.log
stderr_logfile=/var/log/x11vnc.err

[program:android]
command=/opt/docker-android/entrypoint.sh
autostart=true
autorestart=true
stdout_logfile=/var/log/android.log
stderr_logfile=/var/log/android.err

[program:novnc]
command=/usr/local/bin/websockify --web=/opt/docker-android/utils/novnc 6080 localhost:5900
autostart=true
autorestart=true
stdout_logfile=/var/log/novnc.log
stderr_logfile=/var/log/novnc.err
EOF

# Expõe as portas padrão
EXPOSE 6080 5900

# Inicia o supervisord com o arquivo de configuração especificado
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
