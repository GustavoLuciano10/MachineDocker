FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Definindo timezone automaticamente
RUN ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && \
    echo "America/Sao_Paulo" > /etc/timezone && \
    apt-get update && \
    apt-get install -y tzdata && \
    apt-get install -y \
        openjdk-11-jdk wget unzip curl git \
        x11vnc xvfb supervisor novnc net-tools python3-pip \
        libgl1-mesa-dev libglu1-mesa && \
    rm -rf /var/lib/apt/lists/*

# Criar diretórios necessários
RUN mkdir -p /root/.android && \
    mkdir -p /opt/android-sdk && \
    mkdir -p /var/log/supervisor

# Baixar SDK Tools
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O sdk-tools.zip && \
    unzip sdk-tools.zip -d /opt/android-sdk/cmdline-tools && \
    mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest && \
    rm sdk-tools.zip

# Configurar variáveis de ambiente
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin

# Instalar SDKs e ferramentas necessárias
RUN yes | sdkmanager --sdk_root=${ANDROID_HOME} --licenses && \
    sdkmanager --sdk_root=${ANDROID_HOME} \
        "platform-tools" \
        "emulator" \
        "platforms;android-30" \
        "system-images;android-30;google_apis;x86_64" && \
    echo "no" | avdmanager create avd -n test -k "system-images;android-30;google_apis;x86_64" --force

# Supervisord.conf embutido via HEREDOC
RUN echo '[supervisord]
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
' > /etc/supervisor/conf.d/supervisord.conf

EXPOSE 6080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
