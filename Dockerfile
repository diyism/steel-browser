FROM debian:bookworm-slim
RUN apt update -y -qq; apt install -y curl wget python3-venv git sudo sshpass rsync lsyncd xvfb
RUN echo 'Asia/Shanghai' > /etc/timezone
RUN python3 -m venv v1
ENV PATH="/v1/bin:$PATH"
RUN pip install jupyterlab
RUN touch /etc/rc.local; chmod 777 /etc/rc.local

#custom building begin------>
RUN wget -qO- https://golang.org/dl/go1.18.1.linux-amd64.tar.gz | tar -xvz -C /usr/local
RUN mv /usr/local/go /usr/local/go.golang
RUN git clone --depth 1 --recursive https://github.com/gofork-org/goFork.git
RUN cp -r ./goFork/ /usr/local/go/
RUN cd /usr/local/go/src; export GOROOT_BOOTSTRAP=/usr/local/go.golang; ./all.bash
RUN sed -i 's|PATH="|PATH="/usr/local/go/bin:/usr/sbin:|' /etc/profile
#RUN /usr/local/go/bin/go install github.com/playwright-community/playwright-go/cmd/playwright@v0.2000.2-0.20221022152247-2586b3829688
RUN echo "deb http://ftp.us.debian.org/debian buster main non-free" >> /etc/apt/sources.list.d/fonts.list
#RUN /root/go/bin/playwright install --with-deps chromium

RUN echo 'while true; do nohup Xvfb :10 -screen 0 1920x1080x8 -ac > /dev/null 2>&1; sleep 1; done &' >>/etc/rc.local


#<-----custom building end

RUN useradd -m -u 1000 user_cmd
RUN echo "user_cmd ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER user_cmd
RUN jupyter lab --generate-config
RUN echo "c.PasswordIdentityProvider.password_required=True">>/home/user_cmd/.jupyter/jupyter_lab_config.py
RUN echo "c.PasswordIdentityProvider.hashed_password='argon2:\$argon2id\$v=19\$m=10240,t=10,p=8\$ADVOtoQgkVyBkD2MAacNdg\$RwMBZJA+LsqnMQXxNElfTuUzHUOu1MvaRZ1kypvec9g'">>/home/user_cmd/.jupyter/jupyter_lab_config.py
RUN /usr/local/go/bin/go install github.com/playwright-community/playwright-go/cmd/playwright@v0.2000.2-0.20221022152247-2586b3829688
RUN /home/user_cmd/go/bin/playwright install --with-deps chromium
ENV SHELL=/bin/bash
WORKDIR /home/user_cmd/
ENV DISPLAY=:10
ENV DBUS_SESSION_BUS_ADDRESS=autolaunch:
CMD /etc/rc.local; jupyter lab --ip=0.0.0.0 --port=7860 --no-browser --allow-root
