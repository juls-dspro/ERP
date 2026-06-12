# Guía de Instalación de Frappe Bench y ERPNext 🚀

Esta guía está diseñada para que el equipo de desarrollo pueda preparar su entorno local para trabajar con **Frappe Framework** y **ERPNext** (versión 15). Cubre las tres alternativas principales de instalación:

1. **macOS** (Instalación nativa con Homebrew)
2. **Windows con WSL** (Windows Subsystem for Linux - *Recomendado para Windows*)
3. **Windows con Docker** (Contenedores y Dev Containers)

---

## 📋 Requisitos Previos Generales

Antes de comenzar, es importante saber que Frappe requiere versiones específicas de su pila tecnológica. Para la **versión 15**, usaremos:
*   **Python**: `3.10` o `3.11`
*   **Node.js**: `18.x` o `20.x` (con `yarn` instalado globalmente)
*   **MariaDB**: `10.6` o superior
*   **Redis**: `6.x` o superior
*   **wkhtmltopdf**: `0.12.6-1` (con qt patch, para generación de PDFs)

---

## 🍎 Opción 1: Instalación en macOS

Para macOS realizamos una instalación nativa utilizando el gestor de paquetes **Homebrew**.

### Paso 1: Instalar Xcode Command Line Tools
Abre la terminal y ejecuta:
```bash
xcode-select --install
```

### Paso 2: Instalar Dependencias con Homebrew
Instala los servicios y lenguajes necesarios:
```bash
brew install git python@3.11 node@18 redis mariadb
```
*Si usas una versión de Node diferente, puedes enlazarla con `brew link --overwrite node@18`.*

### Paso 3: Configurar e Iniciar Servicios
1. **Configurar MariaDB (Crítico)**:
   Frappe requiere que MariaDB utilice la codificación `utf8mb4`. Abre el archivo de configuración de MariaDB (usualmente en `/opt/homebrew/etc/my.cnf` o `/opt/homebrew/etc/my.cnf.d/mariadb-server.cnf` en Apple Silicon, o `/usr/local/etc/my.cnf` en Intel):
   
   Añade o edita las siguientes secciones:
   ```ini
   [mysqld]
   character-set-server = utf8mb4
   collation-server = utf8mb4_unicode_ci

   [mysql]
   default-character-set = utf8mb4
   ```

2. **Iniciar servicios**:
   ```bash
   brew services start mariadb
   brew services start redis
   ```

3. **Establecer Contraseña Root de MariaDB**:
   Ejecuta el asistente de seguridad o entra directamente a mysql:
   ```bash
   mysql -u root
   ```
   Dentro de la consola de MariaDB, establece la contraseña para el usuario `root` (la necesitarás al crear sitios de Frappe):
   ```sql
   ALTER USER 'root'@'localhost' IDENTIFIED BY 'tu_contraseña_root';
   FLUSH PRIVILEGES;
   EXIT;
   ```

### Paso 4: Instalar Frappe Bench
1. Instala `pip` y `virtualenv` si no los tienes:
   ```bash
   python3 -m pip install --user virtualenv
   ```
2. Instala `frappe-bench` de forma global:
   ```bash
   pip3 install frappe-bench
   ```
3. Instala `yarn` de forma global (necesario para compilar los assets del frontend):
   ```bash
   npm install -g yarn
   ```

### Paso 5: Inicializar el Bench y crear tu Sitio
1. Inicializa un nuevo bench (entorno de trabajo) descargando la versión de Frappe deseada:
   ```bash
   bench init --frappe-branch version-15 mi-erp-bench
   cd mi-erp-bench
   ```
2. Crea un nuevo sitio local (te pedirá la contraseña root de MariaDB que creaste antes):
   ```bash
   bench new-site erp.local
   ```
3. Descarga e instala ERPNext en el sitio:
   ```bash
   bench get-app erpnext --branch version-15
   bench --site erp.local install-app erpnext
   ```
4. Levanta el servidor de desarrollo:
   ```bash
   bench start
   ```

---

## 💻 Opción 2: Instalación en Windows con WSL (Recomendado)

Esta es la forma estándar y recomendada para desarrollar en Windows, ya que Frappe está optimizado para entornos basados en Unix. Usaremos **WSL 2** con **Ubuntu 22.04 LTS**.

### Paso 1: Instalar WSL 2
1. Abre PowerShell como Administrador y ejecuta:
   ```powershell
   wsl --install -d Ubuntu
   ```
2. Reinicia la computadora si el instalador lo solicita.
3. Al iniciar Ubuntu por primera vez, define tu usuario y contraseña de Linux.

### Paso 2: Actualizar el Sistema
Dentro de tu terminal de Ubuntu:
```bash
sudo apt update && sudo apt upgrade -y
```

### Paso 3: Instalar Dependencias Básicas
Instala herramientas de compilación, Git, Python y Redis:
```bash
sudo apt install -y git python3-dev python3-pip python3-setuptools python3-venv mariadb-server redis-server curl software-properties-common
```

### Paso 4: Instalar Node.js y Yarn
Instala Node.js v18 usando el repositorio de NodeSource:
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g yarn
```

### Paso 5: Configurar MariaDB en WSL
1. **Configuración de caracteres**:
   Abre el archivo de configuración del servidor MariaDB:
   ```bash
   sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
   ```
   Asegúrate de agregar o modificar estas líneas bajo la sección `[mysqld]`:
   ```ini
   [mysqld]
   character-set-server = utf8mb4
   collation-server = utf8mb4_unicode_ci
   ```
   Guarda y sal (en nano: `Ctrl+O`, `Enter`, `Ctrl+X`).

2. **Activar e Iniciar los Servicios**:
   Dado que WSL no usa systemd por defecto en versiones antiguas (o requiere habilitarlo), inicia los servicios manualmente:
   ```bash
   sudo service mysql start
   sudo service redis-server start
   ```
   > [!TIP]
   > Puedes configurar WSL para iniciar systemd agregando estas líneas a `/etc/wsl.conf`:
   > ```ini
   > [boot]
   > systemd=true
   > ```

3. **Configurar Autenticación del usuario Root**:
   Por defecto, en Ubuntu MariaDB usa el plugin `auth_socket` para el root. Debes cambiarlo a autenticación por contraseña para que Frappe pueda conectarse:
   ```bash
   sudo mysql -u root
   ```
   Ejecuta los siguientes comandos:
   ```sql
   ALTER USER 'root'@'localhost' IDENTIFIED BY 'tu_contraseña_root';
   FLUSH PRIVILEGES;
   EXIT;
   ```

### Paso 6: Instalar wkhtmltopdf (Requerido para PDF)
```bash
sudo apt install -y xvfb libfontconfig wkhtmltopdf
```

### Paso 7: Instalar Bench e inicializar el entorno
1. Instala `frappe-bench` mediante pip:
   ```bash
   pip3 install frappe-bench
   ```
2. Inicializa tu Bench en la carpeta que desees (ej. tu home de usuario):
   ```bash
   cd ~
   bench init --frappe-branch version-15 mi-erp-bench
   cd mi-erp-bench
   ```
3. Crea tu sitio e instala ERPNext:
   ```bash
   bench new-site erp.local
   bench get-app erpnext --branch version-15
   bench --site erp.local install-app erpnext
   ```
4. Inicia el entorno de desarrollo:
   ```bash
   bench start
   ```

---

## 🐳 Opción 3: Instalación en Windows con Docker

Esta opción es ideal si no deseas configurar manualmente todas las dependencias en tu sistema o si quieres usar **VS Code Dev Containers** para un entorno de desarrollo aislado y pre-configurado.

### Requisito previo: Instalar Docker Desktop
1. Descarga e instala **Docker Desktop** para Windows.
2. Asegúrate de activar la opción **WSL 2 backend** en los ajustes de Docker Desktop.

---

### Método A: Usar VS Code Dev Containers (Recomendado para Desarrolladores)
Frappe proporciona soporte oficial para abrir proyectos directamente dentro de un contenedor de Docker usando VS Code.

1. Instala las siguientes extensiones en **VS Code**:
   *   *WSL* (de Microsoft)
   *   *Dev Containers* (de Microsoft)
2. Clona el repositorio oficial de desarrollo de Frappe Docker:
   ```bash
   git clone https://github.com/frappe/frappe_docker.git
   cd frappe_docker
   ```
3. Renombra o copia la carpeta `.devcontainer` de ejemplo:
   *   El repositorio contiene un entorno de desarrollo de ejemplo listo para usar.
4. Abre la carpeta en VS Code:
   ```bash
   code .
   ```
5. Cuando VS Code detecte el archivo de configuración del contenedor, te mostrará un aviso en la esquina inferior derecha: **"Reopen in Container"** (Reabrir en contenedor). Haz clic en él.
6. Docker descargará la imagen con todas las dependencias pre-instaladas (Python, Node.js, MariaDB, Redis, Bench, etc.). Este proceso puede tardar unos minutos en la primera ejecución.
7. Una vez dentro de la terminal del contenedor en VS Code, puedes inicializar tu sitio de desarrollo de inmediato:
   ```bash
   bench new-site erp.local --mariadb-root-password mariadb --admin-password admin
   bench --site erp.local install-app erpnext
   bench start
   ```

---

### Método B: Despliegue con Docker Compose (Para Entornos Locales Multi-Contenedor)
Si deseas levantar un entorno completo con Docker Compose de manera rápida para pruebas o demostraciones locales.

1. Clona el repositorio `frappe_docker`:
   ```bash
   git clone https://github.com/frappe/frappe_docker.git
   cd frappe_docker
   ```
2. Prepara las variables de entorno para desarrollo local:
   ```bash
   cp devcontainer-example/.env.example .env
   ```
3. Levanta el stack de desarrollo:
   ```bash
   docker compose -f devcontainer-example/docker-compose.yml up -d
   ```
4. Accede al contenedor principal (`development` o `backend`) para ejecutar comandos de bench:
   ```bash
   docker compose exec -it -u frappe backend bash
   ```
5. Una vez dentro del contenedor, puedes operar con comandos `bench` habituales.

---

## 🛠️ Resolución de Problemas Comunes (Troubleshooting)

### 1. Error: `Access denied for user 'root'@'localhost'` al crear el sitio
*   **Causa**: La contraseña de root de MariaDB ingresada en `bench new-site` es incorrecta, o el plugin de autenticación en la base de datos sigue configurado como `auth_socket`.
*   **Solución**: Vuelve a correr los comandos de configuración de base de datos de los pasos anteriores para asegurar que el usuario root de MariaDB use contraseña (`mysql_native_password` o `caching_sha2_password`).

### 2. Error al renderizar PDF (Formatos rotos o sin estilos)
*   **Causa**: Falta la configuración de `wkhtmltopdf` con parches qt o el puerto de tu sitio no está mapeado correctamente en la red interna.
*   **Solución**:
    *   Asegúrate de agregar la clave `"host_name": "http://localhost:8000"` (o la IP correspondiente) en el archivo `site_config.json` de tu sitio.
    *   Verifica que `wkhtmltopdf --version` responda correctamente.

### 3. Acceder a tu sitio local con un dominio personalizado (`erp.local`)
*   **Causa**: Tu navegador no sabe dónde encontrar el dominio ficticio `erp.local`.
*   **Solución**:
    *   **En Windows**: Abre el Bloc de notas como Administrador y edita el archivo `C:\Windows\System32\drivers\etc\hosts`. Añade la línea:
        ```text
        127.0.0.1 erp.local
        ```
    *   **En macOS / Linux**: Edita `/etc/hosts` con sudo:
        ```bash
        sudo nano /etc/hosts
        ```
        Añade la misma línea:
        ```text
        127.0.0.1 erp.local
        ```

---

> [!IMPORTANT]
> Recuerda que una vez instalado tu entorno de desarrollo, debes activar el **Modo Desarrollador** en tu sitio de pruebas para poder crear o editar DocTypes localmente y conservar el código generado en el sistema de archivos:
> ```bash
> bench --site erp.local set-config developer_mode 1
> ```

---

## 👥 Colaboración y Flujo de Trabajo en Equipo

Para que otro desarrollador de tu equipo se conecte y trabaje en este proyecto, debe seguir estos pasos en su entorno local recién configurado:

### Paso 1: Clonar el Repositorio de Configuración
Tu compañero debe clonar este repositorio principal (que contiene las guías y configuraciones del bench):
```bash
git clone https://github.com/juls-dspro/ERP.git mi-erp-bench
cd mi-erp-bench
```

### Paso 2: Inicializar el Bench Local
Debe inicializar la estructura del bench (que creará la carpeta virtual `env` localmente):
```bash
bench init --frappe-branch version-15 .
```

### Paso 3: Clonar tu Aplicación Personalizada (Laboratorio)
Para integrar la app `laboratorio`, debe ejecutar:
```bash
bench get-app laboratorio https://github.com/juls-dspro/Laboratorio.git
```

### Paso 4: Crear su Sitio Local e Instalar las Apps
Cada desarrollador maneja su propio sitio de pruebas y base de datos:
```bash
# Crear un sitio nuevo local (ej. erp.local)
bench new-site erp.local

# Instalar ERPNext
bench --site erp.local install-app erpnext

# Instalar la aplicación Laboratorio
bench --site erp.local install-app laboratorio
```

### Paso 5: Sincronizar Cambios de Base de Datos
Cada vez que bajes cambios de Git (`git pull`) que contengan nuevos DocTypes o campos creados por otros compañeros, debes sincronizar tu base de datos local ejecutando:
```bash
bench --site erp.local migrate
bench --site erp.local clear-cache
```
Esto creará y modificará las tablas de MariaDB localmente basándose en los archivos JSON de los DocTypes.
