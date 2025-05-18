FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99

# Instala dependências básicas
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

# Instala websockify e noVNC via pip
RUN pip3 install websockify

# Clona o docker-android e copia utils
RUN git clone https://github.com/budtmo/docker-android.git /opt/docker-android

# Copia supervisord.conf dentro do container
RUN mkdir -p /etc/supervisor/conf.d/
RUN echo "[supervisord]\nnodaemon=true\n\n" \
         "[program:xvfb]\ncommand=/usr/bin/Xvfb :99 -screen 0 1280x720x16\nautostart=true\nautorestart=true\nstdout_logfile=/var/log/xvfb.log\nstderr_logfile=/var/log/xvfb.err\n\n" \
         "[program:x11vnc]\ncommand=/usr/bin/x11vnc -display :99 -nopw -forever -shared\nautostart=true\nautorestart=true\nstdout_logfile=/var/log/x11vnc.log\nstderr_logfile=/var/log/x11vnc.err\n\n" \
         "[program:android]\ncommand=/opt/docker-android/entrypoint.sh\nautostart=true\nautorestart=true\nstdout_logfile=/var/log/android.log\nstderr_logfile=/var/log/android.err\n\n" \
         "[program:novnc]\ncommand=/usr/local/bin/websockify --web=/opt/docker-android/utils/novnc 6080 localhost:5900\nautostart=true\nautorestart=true\nstdout_logfile=/var/log/novnc.log\nstderr_logfile=/var/log/novnc.err\n" \
    > /etc/supervisor/conf.d/supervisord.conf

EXPOSE 6080 5900

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
