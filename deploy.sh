#!/bin/bash

# Script de Inicialización y Despliegue de ERPNext en GCP VM (Ubuntu/Debian)
# Ejecutar este script dentro de la máquina virtual de Compute Engine.

set -e

echo "=========================================="
echo " Inicializando Servidor ERPNext en GCP VM "
echo "=========================================="

# 1. Actualizar el sistema e instalar dependencias básicas
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y curl git apt-transport-https ca-certificates gnupg lsb-release

# 2. Instalar Docker
if ! [ -x "$(command -v docker)" ]; then
    echo "Instalando Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    sudo usermod -aG docker $USER
fi

# 3. Instalar Docker Compose (v2)
echo "Instalando Docker Compose..."
sudo apt-get install -y docker-compose-plugin

# 4. Clonar el repositorio del proyecto
# Reemplazar con el repositorio si no se ha clonado
if [ ! -d "erp-repo" ]; then
    echo "Clonando repositorio..."
    git clone https://github.com/juls-dspro/ERP.git erp-repo
fi

cd erp-repo

# 5. Compilar la imagen de Docker de producción
echo "Compilando la imagen de Docker..."
sudo docker compose -f docker-compose.prod.yml build

# 6. Levantar la base de datos y Redis primero
echo "Iniciando base de datos y servicios de apoyo..."
sudo docker compose -f docker-compose.prod.yml up -d db redis-cache redis-queue redis-socketio

echo "Esperando 10 segundos a que la base de datos inicie..."
sleep 10

# 7. Levantar el backend y workers
echo "Levantando el backend y workers..."
sudo docker compose -f docker-compose.prod.yml up -d backend worker-default worker-short worker-long scheduler nginx

echo "============================================================"
echo " ¡Stack desplegado correctamente en la máquina virtual! "
echo "============================================================"
echo "Ahora puedes inicializar tu sitio de ERP ejecutando:"
echo "sudo docker compose -f docker-compose.prod.yml exec backend bench new-site erp.local --db-host db --mariadb-root-password admin --admin-password admin --mariadb-user-host-login-scope='%'"
echo "============================================================"
echo "Para instalar la aplicación ERPNext:"
echo "sudo docker compose -f docker-compose.prod.yml exec backend bench --site erp.local install-app erpnext"
echo "============================================================"
echo "Para instalar la aplicación Laboratorio:"
echo "sudo docker compose -f docker-compose.prod.yml exec backend bench --site erp.local install-app laboratorio"
echo "============================================================"
