# 使用基于Ubuntu 22.04的基础映像
FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV VNC_PASSWD=vncpasswd

# 安装必要的软件包
RUN apt-get update
RUN apt-get install -y \
    openbox \
    curl \
    unzip \
    x11vnc \
    xvfb \
    fluxbox \
    supervisor \
    libnotify4 \
    libnss3 \
    xdg-utils \
    libsecret-1-0 \
    libgbm1 \
    libasound2 \
    fonts-wqy-zenhei \
    git \
    gnutls-bin \    
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 安装novnc
RUN git config --global http.sslVerify false && git config --global http.postBuffer 1048576000
RUN cd /opt && git clone https://github.com/novnc/noVNC.git
RUN cd opt/noVNC/utils && git clone https://github.com/novnc/websockify.git
RUN cp /opt/noVNC/vnc.html /opt/noVNC/index.html     

# 安装Linux QQ
RUN curl -o /root/QQ_3.2.5_240305_arm64_01.deb https://dldir1.qq.com/qqfile/qq/QQNT/Linux/QQ_3.2.5_240305_arm64_01.deb
RUN dpkg -i /root/QQ_3.2.5_240305_arm64_01.deb && apt-get -f install -y && rm /root/QQ_3.2.5_240305_arm64_01.deb

# 安装LiteLoader
RUN curl -L -o /tmp/LiteLoaderQQNT.zip https://mirror.ghproxy.com/https://github.com/LiteLoaderQQNT/LiteLoaderQQNT/releases/download/1.0.3/LiteLoaderQQNT.zip \
    && unzip /tmp/LiteLoaderQQNT.zip -d /opt/QQ/resources/app/ \
    && rm /tmp/LiteLoaderQQNT.zip
# 修改/opt/QQ/resources/app/package.json文件
RUN sed -i 's/"main": ".\/app_launcher\/index.js"/"main": ".\/LiteLoader"/' /opt/QQ/resources/app/package.json

# 安装chronocat  
RUN mkdir -p /root/LiteLoaderQQNT/plugins
RUN curl -L -o /tmp/chronocat-llqqnt-engine-chronocat-api.zip https://github.com/chrononeko/chronocat/releases/download/v0.2.6/chronocat-llqqnt-engine-chronocat-api-v0.2.6.zip
RUN curl -L -o /tmp/chronocat-llqqnt-engine-chronocat-event.zip https://github.com/chrononeko/chronocat/releases/download/v0.2.6/chronocat-llqqnt-engine-chronocat-event-v0.2.6.zip
RUN curl -L -o /tmp/chronocat-llqqnt-engine-poke.zip https://github.com/chrononeko/LiteLoaderQQNT-Plugin-Chronocat-Engine-Poke/archive/refs/heads/master.zip
RUN curl -L -o /tmp/chronocat-llqqnt.zip https://github.com/chrononeko/chronocat/releases/download/v0.2.6/chronocat-llqqnt-v0.2.6.zip
RUN unzip /tmp/chronocat-llqqnt.zip -d /root/LiteLoaderQQNT/plugins/
RUN unzip /tmp/chronocat-llqqnt-engine-chronocat-api.zip  -d /opt/QQ/resources/app/LiteLoader/plugins/
RUN unzip /tmp/chronocat-llqqnt-engine-chronocat-event.zip  -d /opt/QQ/resources/app/LiteLoader/plugins/
RUN unzip /tmp/chronocat-llqqnt-engine-poke.zip -d /opt/QQ/resources/app/LiteLoader/plugins/
RUN unzip /tmp/chronocat-llqqnt.zip -d /opt/QQ/resources/app/LiteLoader/plugins/
RUN rm /tmp/chronocat-llqqnt.zip
RUN rm /tmp/chronocat-llqqnt-engine-chronocat-api.zip
RUN rm /tmp/chronocat-llqqnt-engine-chronocat-event.zip
RUN rm /tmp/chronocat-llqqnt-engine-poke.zip

# 安装LLWebUiApi
RUN mkdir -p /opt/QQ/resources/app/LiteLoader/plugins/LLWebUiApi
RUN curl -L -o /tmp/LLWebUiApi.zip https://mirror.ghproxy.com/https://github.com/LLOneBot/LLWebUiApi/releases/download/v0.0.31/LLWebUiApi.zip
RUN unzip /tmp/LLWebUiApi.zip -d /opt/QQ/resources/app/LiteLoader/plugins/LLWebUiApi
RUN mkdir -p /opt/QQ/resources/app/LiteLoader/data/LLWebUiApi
RUN echo '{"Server":{"Port":6099},"AutoLogin":true,"BootMode":3,"Debug":false}' > /opt/QQ/resources/app/LiteLoader/data/LLWebUiApi/config.json
RUN rm /tmp/LLWebUiApi.zip

# 创建必要的目录
RUN mkdir -p ~/.vnc

# 创建启动脚本
RUN echo "#!/bin/bash" > ~/start.sh
RUN echo "rm /tmp/.X1-lock" >> ~/start.sh
RUN echo "Xvfb :1 -screen 0 1280x1024x16 &" >> ~/start.sh
RUN echo "export DISPLAY=:1" >> ~/start.sh
RUN echo "fluxbox &" >> ~/start.sh
RUN echo "x11vnc -display :1 -noxrecord -noxfixes -noxdamage -forever -rfbauth ~/.vnc/passwd &" >> ~/start.sh
RUN echo "nohup /opt/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 6081 --file-only &" >> ~/start.sh
RUN echo "x11vnc -storepasswd \$VNC_PASSWD ~/.vnc/passwd" >> ~/start.sh
RUN echo "su -c 'qq' root" >> ~/start.sh
RUN chmod +x ~/start.sh

# 配置supervisor
RUN echo "[supervisord]" > /etc/supervisor/supervisord.conf
RUN echo "nodaemon=true" >> /etc/supervisor/supervisord.conf
RUN echo "[program:x11vnc]" >> /etc/supervisor/supervisord.conf
RUN echo "command=/usr/bin/x11vnc -display :1 -noxrecord -noxfixes -noxdamage -forever -rfbauth ~/.vnc/passwd" >> /etc/supervisor/supervisord.conf

# 设置容器启动时运行的命令
CMD ["/bin/bash", "-c", "/root/start.sh"]
