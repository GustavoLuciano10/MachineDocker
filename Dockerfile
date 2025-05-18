FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99

RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    x11vnc \
    xvfb \
    supervisor \
    net-tools \
    python3 \
    python3-pip \
    openjdk-11-jdk \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip3 install websockify

# Clonar o docker-android
RUN git clone https://github.com/budtmo/docker-android.git /opt/docker-android

# Criar script start-android.sh
RUN printf '#!/bin/bash\n\
set -e\n\
export DISPLAY=:99\n\
sleep 5\n\
# Aqui você deve iniciar o Android emulator (exemplo do repo original)\n\
# /opt/docker-android/entrypoint.sh &\n\
while true; do sleep 1000; done\n' > /opt/start-android.sh && chmod +x /opt/start-android.sh

# Criar script launch_novnc.sh
RUN printf '#!/bin/bash\n\
set -e\n\
export DISPLAY=:99\n\
websockify --web=/opt/docker-android/utils/novnc 6080 localhost:5900\n' > /opt/launch_novnc.sh && chmod +x /opt/launch_novnc.sh

# Criar arquivo de configuração do supervisord
RUN printf '[supervisord]\n\
nodaemon=true\n\
logfile=/var/log/supervisord.log\n\
loglevel=info\n\
\n\
[program:xvfb]\n\
command=Xvfb :99 -screen 0 1024x768x16\n\
autostart=true\n\
autorestart=true\n\
stdout_logfile=/var/log/xvfb.log\n\
stderr_logfile=/var/log/xvfb.err\n\
\n\
[program:android]\n\
command=/opt/start-android.sh\n\
autostart=true\n\
autorestart=true\n\
stdout_logfile=/var/log/android.log\n\
stderr_logfile=/var/log/android.err\n\
\n\
[program:novnc]\n\
command=/opt/launch_novnc.sh\n\
autostart=true\n\
autorestart=true\n\
stdout_logfile=/var/log/novnc.log\n\
stderr_logfile=/var/log/novnc.err\n' > /etc/supervisor/conf.d/supervisord.conf

EXPOSE 6080 5554 5555

CMD ["/usr/bin/supervisord", "-n"]
