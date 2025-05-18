# Base image
FROM ubuntu:22.04

# Variáveis para não interagir durante build
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=America/Sao_Paulo

# Atualiza e instala dependências
RUN apt-get update && apt-get install -y \
    wget curl unzip git gnupg2 ca-certificates \
    openjdk-11-jdk \
    xvfb x11vnc supervisor novnc python3 python3-pip \
    net-tools libvirt-daemon-system libvirt-clients qemu-kvm \
    && rm -rf /var/lib/apt/lists/*

# Instala o Android SDK Command Line Tools
ENV ANDROID_SDK_ROOT=/opt/android-sdk
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools \
 && cd ${ANDROID_SDK_ROOT}/cmdline-tools \
 && wget https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -O sdk.zip \
 && unzip sdk.zip -d tools \
 && rm sdk.zip

ENV PATH="${ANDROID_SDK_ROOT}/cmdline-tools/tools/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

# Aceita licenças e instala componentes
RUN yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses \
 && sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "platform-tools" "platforms;android-30" "emulator" "system-images;android-30;google_apis;x86_64" "build-tools;30.0.3"

# Cria o AVD
RUN echo "no" | avdmanager create avd -n test -k "system-images;android-30;google_apis;x86_64" --force

# Copia o arquivo de configuração do supervisord
RUN mkdir -p /etc/supervisor/conf.d

# Embute o supervisord.conf via HEREDOC
RUN tee /etc/supervisor/conf.d/supervisord.conf > /dev/null <<EOF
[supervisord]
nodaemon=true

[program:xvfb]
command=/usr/bin/Xvfb :0 -screen 0 1024x768x16
autorestart=true

[program:x11vnc]
command=/usr/bin/x11vnc -display :0 -nopw -forever
autorestart=true

[program:novnc]
command=/usr/share/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080
autorestart=true

[program:android]
command=/opt/android-sdk/emulator/emulator -avd test -noaudio -no-boot-anim -no-snapshot -gpu swiftshader_indirect -verbose -no-window -qemu -vnc :0
autorestart=true
EOF

# Expõe as portas do VNC e noVNC
EXPOSE 5900 6080

# Define o entrypoint do supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
