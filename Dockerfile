FROM debian:stretch-slim
LABEL maintainer "Logan Dzwonkowski logan.dzwonkowski@envisionhealth.com"

# Install required packages
RUN apt-get update \
    && apt-get -q -y dist-upgrade \
    && apt-get install -y --no-install-recommends \
         ca-certificates \
         curl \
         build-essential

# Install nodejs repo and nodejs
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - \
    && apt-get install -y nodejs
#    && apt-get clean \
#    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*	 

# Install AZcopy
RUN set -ex \
    && curl -L -o azcopy.tar.gz https://azcopyvnext.azureedge.net/release20190703/azcopy_linux_amd64_10.2.1.tar.gz \
    && tar -xzf azcopy.tar.gz && rm -f azcopy.tar.gz \
    && cp ./azcopy_linux_amd64_10.2.1/azcopy /usr/local/bin/. \
    && chmod +x /usr/local/bin/azcopy \
    && rm -rf azcopy_linux_amd64_10.2.1

# Entrypoint
ADD entrypoint.sh /entrypoint.sh
#ENTRYPOINT ["sh", "/entrypoint.sh"]

RUN apt-get -q -y install --no-install-recommends openssh-server \
	    && apt-get clean \
	    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /var/run/sshd

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# not secure !
# not for production use
# use this only for experiments 
# TODO: rework to public keys and regular user
RUN echo "root:docker" | chpasswd
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
