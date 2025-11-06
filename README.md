# Docker Advanced

Outils et exemples pour le cours Docker Advanced

## Description

Ce repository contient des exemples pratiques et des configurations pour travailler avec Docker dans un contexte avancé. Il couvre plusieurs technologies et cas d'usage:

- **Apache/PHP**: Serveur web Apache avec PHP sur RockyLinux
- **Django**: Application Django avec PostgreSQL
- **Traefik**: Reverse proxy et load balancer moderne

## Structure du projet

```
.
├── apache/           # Configuration Apache + PHP
│   ├── Dockerfile    # Image personnalisée Apache/PHP
│   ├── index.php     # Page de test PHP
│   └── httpd-foreground  # Script de démarrage
├── django/           # Application Django
│   ├── Dockerfile    # Image Django
│   ├── docker-compose.yml  # Stack Django + PostgreSQL
│   ├── requirements.txt    # Dépendances Python
│   └── settings.py   # Configuration Django
├── traefik/          # Configuration Traefik pour Docker Swarm
│   └── docker-compose.yaml
└── traefik2.yml      # Configuration Traefik pour Kubernetes
```

## Utilisation

### Apache/PHP

Construire et lancer le conteneur Apache:

```bash
cd apache
docker build -t mon-apache:latest .
docker run -d -p 8080:80 mon-apache:latest
```

Accéder à: http://localhost:8080

### Django avec PostgreSQL

Lancer la stack Django + PostgreSQL:

```bash
cd django
docker-compose up -d
```

L'application sera disponible sur: http://localhost:8000

### Traefik (Docker Swarm)

Déployer Traefik en mode Swarm:

```bash
cd traefik
docker stack deploy -c docker-compose.yaml traefik-stack
```

### Traefik (Kubernetes)

Appliquer la configuration Kubernetes:

```bash
kubectl apply -f traefik2.yml
```

## Prérequis

- Docker Engine 20.10+
- Docker Compose v2+
- Pour Swarm: Cluster Docker Swarm initialisé
- Pour Kubernetes: Cluster Kubernetes 1.20+

## Notes de sécurité

⚠️ **Important**: Les configurations fournies sont à des fins éducatives. Pour un environnement de production:

- Ne pas exposer les secrets en clair
- Utiliser des variables d'environnement ou des secrets managers
- Activer HTTPS/TLS
- Désactiver le mode DEBUG
- Utiliser des mots de passe forts

## Licence

Voir le fichier LICENSE

## Auteur

Christophe Merle - christophe.merle@gmail.com
