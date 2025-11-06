FROM rockylinux:9

# Métadonnées
LABEL maintainer="christophe.merle@gmail.com"
LABEL description="Serveur web Apache2 sur RockyLinux avec PHP et PHP-FPM"
LABEL version="4.0"

# Installation des paquets en une seule couche pour optimiser l'image
RUN dnf install -y \
    httpd \
    php \
    php-fpm \
    php-opcache \
    php-json \
    php-mbstring \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Configuration des logs pour Docker (redirection vers stdout/stderr)
RUN ln -sf /dev/stdout /var/log/httpd/access_log \
    && ln -sf /dev/stderr /var/log/httpd/error_log

# Créer le répertoire pour PHP-FPM s'il n'existe pas
RUN mkdir -p /run/php-fpm && chown root:apache /run/php-fpm

# Définir le répertoire de travail
WORKDIR /var/www/html/

# Copier les fichiers de l'application
COPY index.php .

# Copier le script de démarrage
COPY httpd-foreground /usr/sbin/httpd-foreground
RUN chmod +x /usr/sbin/httpd-foreground

# Exposition du port HTTP
EXPOSE 80

# Utiliser un utilisateur non-root pour plus de sécurité (optionnel, commenté car Apache nécessite root pour le port 80)
# USER apache

# Point d'entrée
ENTRYPOINT ["/usr/sbin/httpd-foreground"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1 
