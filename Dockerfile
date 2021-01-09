FROM litespeedtech/openlitespeed:1.6.18-lsphp74

#install SSH
RUN apt-get update; \
     apt-get install --yes --no-install-recommends openssh-server; \
     echo "root:Docker!" | chpasswd; \
     rm -f /etc/ssh/sshd_config

COPY sshd_config /etc/ssh/
COPY ssh_setup.sh /etc/ssh/
RUN chmod -R +x /etc/ssh/ssh_setup.sh; \
   (sleep 1;. /etc/ssh/ssh_setup.sh 2>&1 > /dev/null); \
   rm -rf /etc/ssh/ssh_setup.sh

COPY phpsite.conf /usr/local/lsws/conf/templates/
COPY httpd_config.conf /usr/local/lsws/conf/
RUN chown 999:999 /usr/local/lsws/conf -R

COPY hostingstart.html /home/site/wwwroot/
RUN mkdir -p /home/LogFiles; \
    mkdir -p /home/certs
RUN chown 1000:1000 /home/site/ -R

RUN ln -sf /dev/stderr /usr/local/lsws/logs/access.log; \
    ln -sf /dev/stderr /usr/local/lsws/logs/error.log; \
    ln -sf /dev/stderr /usr/local/lsws/logs/stderr.log

# VOLUME /home/site/wwwroot

EXPOSE 2222 80 
# 7080

ENV WEBSITE_ROLE_INSTANCE_ID localRoleInstance
ENV WEBSITE_INSTANCE_ID localInstance

WORKDIR /home/site/wwwroot

CMD ["service ssh start"]