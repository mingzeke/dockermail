FROM ubuntu:14.10

ENV DEBIAN_FRONTEND noninteractive
RUN locale-gen en_GB en_GB.UTF-8 && dpkg-reconfigure locales
RUN echo "Asia/Taipei" > /etc/timezone
RUN dpkg-reconfigure tzdata

# Prerequisites
RUN apt-get update && apt-get install -y \
    ssl-cert \
    postfix \
    dovecot-pop3d && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/* /var/log/* /.bash_history

# postfix configuration
ADD ./config/postfix.main.cf /etc/postfix/main.cf
ADD ./config/postfix.master.cf.append /etc/postfix/master-additional.cf
RUN cat /etc/postfix/master-additional.cf >> /etc/postfix/master.cf

# configure settings script
VOLUME ["/mail_settings"]
COPY process_settings /process_settings
RUN chmod 755 /process_settings

# add user vmail who own all mail folders
VOLUME ["/vmail"]
RUN groupadd -g 5000 vmail
RUN useradd -g vmail -u 5000 vmail -d /vmail -m

# dovecot configuration
ADD ./config/dovecot.mail /etc/dovecot/conf.d/10-mail.conf
ADD ./config/dovecot.ssl /etc/dovecot/conf.d/10-ssl.conf
ADD ./config/dovecot.auth /etc/dovecot/conf.d/10-auth.conf
ADD ./config/dovecot.master /etc/dovecot/conf.d/10-master.conf
ADD ./config/dovecot.lda /etc/dovecot/conf.d/15-lda.conf
ADD ./config/dovecot.imap /etc/dovecot/conf.d/20-imap.conf
# add verbose logging
#ADD ./config/dovecot.logging /etc/dovecot/conf.d/10-logging.conf

EXPOSE 25 587 995
# todo: enable port 587 for outgoing mail, separate ports 25 and 587
# http://www.synology-wiki.de/index.php/Zusaetzliche_Ports_fuer_Postfix

# start necessary services for operation (dovecot -F starts dovecot in the foreground to prevent container exit)
ENTRYPOINT /process_settings; service rsyslog start; service postfix start; dovecot -F
