FROM python:3.11-slim

# Métadonnées
LABEL maintainer="christophe.merle@gmail.com"
LABEL description="Application Django avec PostgreSQL"
LABEL version="2.0"

# Variables d'environnement
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Installation des dépendances système nécessaires pour PostgreSQL
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    libpq-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Créer un utilisateur non-root pour exécuter l'application
RUN useradd -m -u 1000 django && mkdir /code && chown django:django /code

# Définir le répertoire de travail
WORKDIR /code

# Copier d'abord requirements.txt pour tirer parti du cache Docker
COPY --chown=django:django requirements.txt .

# Mise à jour de pip et installation des dépendances Python
RUN pip install --upgrade pip setuptools wheel && \
    pip install -r requirements.txt

# Copier le code de l'application
COPY --chown=django:django . .

# Changer vers l'utilisateur non-root
USER django

# Exposer le port de l'application
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000')" || exit 1

# Commande par défaut
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
