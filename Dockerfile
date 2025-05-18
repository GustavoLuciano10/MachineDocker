FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_SDK_ROOT=/opt/android-sdk

# Instala dependências do sistema
RUN apt-get update && apt-get install -y \
    wget curl unzip git openjdk-11-jdk \
    libglu1-mesa xvfb x11vnc net-tools supervisor \
    novnc websockify xterm python3-pip tzdata \
    && apt-get clean

# Define timezone automaticamente
RUN ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# Cria diretórios
RUN mkdir -p /opt/android-sdk/cmdline-tools && \
    mkdir -p /var/log/supervisor

# Instala Command Line Tools do Android SDK
WORKDIR /opt/android-sdk/cmdline-tools
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O cmdline-tools.zip && \
    unzip cmdline-tools.zip && rm cmdline-tools.zip && \
    mv cmdline-tools tools

# Define o PATH
ENV PATH="${ANDROID_SDK_ROOT}/cmdline-tools/tools/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

# Aceita licenças e instala componentes necessários
RUN yes | /opt/android-sdk/cmdline-tools/tools/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses && \
    /opt/android-sdk/cmdline-tools/tools/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} \
    "platform-tools" \
    "platforms;android-30" \
    "emulator" \
    "system-images;android-30;google_apis;x86_64" \
    "build-tools;30.0.3"

# Instala emulador
RUN echo "no" | /opt/android-sdk/cmdline-tools/tools/bin/avdmanager create avd \
    -n test -k "system-images;android-30;google_apis;x86_64" --device "pixel"

# Cria script de entrada para iniciar o emulador
RUN echo '#!/bin/bash\n'\
'xvfb-run --server-args="-screen 0 1920x1080x24" nohup emulator -avd test -no-audio -no-boot-anim -accel off -no-snapshot &\n'\
'exec "$@"' > /entrypoint.sh && chmod +x /entrypoint.sh

# Configuração do supervisord
RUN echo '[supervisord]\n\
nodaemon=true\n\
\n\
[program:xvfb]\n\
command=/usr/bin/Xvfb :0 -screen 0 1024x768x24\n\
autostart=true\n\
autorestart=true\n\
\n\
[program:x11vnc]\n\
command=/usr/bin/x11vnc -forever -usepw -create\n\
autostart=true\n\
autorestart=true\n\
\n\
[program:novnc]\n\
command=/usr/share/novnc/utils/launch.sh --vnc localhost:5900\n\
autostart=true\n\
autorestart=true\n\
\n\
[program:emulator]\n\
command=/entrypoint.sh\n\
autostart=true\n\
autorestart=true\n' > /etc/supervisord.conf

EXPOSE 6080 5900

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
