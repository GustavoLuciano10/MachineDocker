FROM ubuntu:22.04

# 1. Instala dependências necessárias
RUN apt-get update && apt-get install -y \
    openjdk-11-jdk wget unzip git curl \
    x11vnc xvfb supervisor \
    libgl1-mesa-dev libglu1-mesa \
    novnc net-tools python3-pip \
    && rm -rf /var/lib/apt/lists/*

# 2. Define variáveis de ambiente
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator

# 3. Instala SDK e cria o AVD
RUN mkdir -p $ANDROID_HOME && cd $ANDROID_HOME && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip && \
    unzip commandlinetools-linux-*.zip -d cmdline-tools && \
    mv cmdline-tools cmdline-tools/tools && \
    yes | cmdline-tools/tools/bin/sdkmanager --licenses && \
    cmdline-tools/tools/bin/sdkmanager "platform-tools" "emulator" "platforms;android-30" "system-images;android-30;default;x86_64" && \
    echo "no" | cmdline-tools/tools/bin/avdmanager create avd -n test -k "system-images;android-30;default;x86_64" --force

# 4. Cria o supervisord.conf embutido
RUN echo "[supervisord]\n\
nodaemon=true\n\
user=root\n\
\n\
[program:xvfb]\n\
command=Xvfb :0 -screen 0 1280x720x16\n\
environment=DISPLAY=\":0\"\n\
autostart=true\n\
autorestart=true\n\
\n\
[program:x11vnc]\n\
command=x11vnc -display :0 -nopw -forever -shared\n\
autostart=true\n\
autorestart=true\n\
\n\
[program:novnc]\n\
command=/usr/bin/websockify --web=/opt/novnc 80 localhost:5900\n\
autostart=true\n\
autorestart=true\n\
\n\
[program:emulator]\n\
command=/opt/android-sdk/emulator/emulator -avd test -noaudio -no-boot-anim -gpu swiftshader_indirect -no-snapshot -netdelay none -netspeed full -verbose -qemu -m 2048\n\
environment=DISPLAY=\":0\"\n\
autostart=true\n\
autorestart=true" > /etc/supervisor/conf.d/supervisord.conf

# 5. Expor porta HTTP para noVNC
EXPOSE 80

# 6. Entrypoint
CMD ["/usr/bin/supervisord", "-n"]
