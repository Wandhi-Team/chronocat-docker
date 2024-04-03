# 使用基于Ubuntu 22.04的基础映像
FROM maxzhang666/ubuntu_chronocat:latest

# 安装Linux QQ
RUN curl -o /root/QQ_3.2.5_240305_amd64_01.deb https://dldir1.qq.com/qqfile/qq/QQNT/Linux/QQ_3.2.5_240305_amd64_01.deb \
    && dpkg -i /root/QQ_3.2.5_240305_amd64_01.deb && apt-get -f install -y && rm /root/QQ_3.2.5_240305_amd64_01.deb

# 安装LiteLoader
RUN curl -L -o /tmp/LiteLoaderQQNT.zip https://github.com/LiteLoaderQQNT/LiteLoaderQQNT/releases/download/1.0.3/LiteLoaderQQNT.zip \
     && mkdir -p /opt/QQ/resources/app/LiteLoader \
     && unzip /tmp/LiteLoaderQQNT.zip -d /opt/QQ/resources/app/LiteLoader \
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
RUN echo "#!/bin/bash" > ~/start.sh \
    && echo "rm /tmp/.X1-lock" >> ~/start.sh \
    && echo "Xvfb :1 -screen 0 1280x1024x16 &" >> ~/start.sh \
    && echo "export DISPLAY=:1" >> ~/start.sh \
    && echo "fluxbox &" >> ~/start.sh \
    && echo "x11vnc -display :1 -noxrecord -noxfixes -noxdamage -forever -rfbauth ~/.vnc/passwd &" >> ~/start.sh \
    && echo "/opt/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 6081 --file-only &" >> ~/start.sh \
    && echo "x11vnc -storepasswd \$VNC_PASSWD ~/.vnc/passwd" >> ~/start.sh \
    #&& #echo "su -c 'qq' root" >> ~/start.sh \
    && echo "exec supervisord" >> ~/start.sh
RUN chmod +x ~/start.sh

# 配置supervisor
RUN echo "[supervisord]" > /etc/supervisor/supervisord.conf \
&& echo "nodaemon=true" >> /etc/supervisor/supervisord.conf \
&& echo "[program:x11vnc]" >> /etc/supervisor/supervisord.conf \
&& echo "command=/usr/bin/x11vnc -display :1 -noxrecord -noxfixes -noxdamage -forever -rfbauth ~/.vnc/passwd" >> /etc/supervisor/supervisord.conf \
&& echo "[program:qq]" >> /etc/supervisor/supervisord.conf \
&& echo "command=qq --no-sandbox" >> /etc/supervisor/supervisord.conf \
&& echo 'environment=DISPLAY=":1"' >> /etc/supervisor/supervisord.conf

# 设置容器启动时运行的命令
CMD ["/bin/bash", "-c", "/root/start.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
