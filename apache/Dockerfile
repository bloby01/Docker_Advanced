FROM alpine
LABEL MAINTAINER christophe@cmconsulting.online
LABEL DESCRIPTION "Serveur web apache2 sur alpine avec php et index.php"
LABEL VERSION 2.0
RUN apk add   apache2
RUN ln -s /dev/stdout /var/log/apache2/access_log
RUN ln -s /dev/stderr /var/log/apache2/error_log
EXPOSE 80 443
COPY httpd-foreground /usr/sbin/httpd-foreground
ENTRYPOINT /usr/sbin/httpd-foreground
