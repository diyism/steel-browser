#FROM debian:bookworm-slim
FROM ghcr.io/steel-dev/steel-browser:latest
RUN chmod -R 777 /var/lib/nginx
RUN chmod -R 777 /var/log/nginx
RUN touch /run/nginx.pid; chmod 777 /run/nginx.pid
USER root
WORKDIR /

RUN apt update -y -qq; apt install -y curl wget python3-venv git sudo sshpass nfs-common libcap2-bin rsync lsyncd python3-pip
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
RUN echo "deb http://ftp.us.debian.org/debian buster main non-free" >> /etc/apt/sources.list.d/fonts.list

RUN echo 'while true; do nohup jupyter lab --ip=0.0.0.0 --port=7860 --no-browser --allow-root >/dev/null 2>&1; sleep 1; done &' >>/etc/rc.local
#<-----custom building end

RUN getent passwd 1000
#RUN useradd -m -u 1000 user_cmd
RUN echo "node ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER node
RUN jupyter lab --generate-config
RUN echo "c.PasswordIdentityProvider.password_required=True">>/home/node/.jupyter/jupyter_lab_config.py
RUN echo "c.PasswordIdentityProvider.hashed_password='argon2:\$argon2id\$v=19\$m=10240,t=10,p=8\$ADVOtoQgkVyBkD2MAacNdg\$RwMBZJA+LsqnMQXxNElfTuUzHUOu1MvaRZ1kypvec9g'">>/home/node/.jupyter/jupyter_lab_config.py
RUN /usr/local/go/bin/go install github.com/playwright-community/playwright-go/cmd/playwright@latest
RUN /home/node/go/bin/playwright install --with-deps chromium
ENV SHELL=/bin/bash
WORKDIR /home/node/
EXPOSE 7860
CMD jupyter lab --ip=0.0.0.0 --port=7860 --no-browser --allow-root; /etc/rc.local; cd /app; ./entrypoint.sh
