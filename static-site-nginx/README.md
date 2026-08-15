# Proyecto: Sitio Web Estático con Nginx y Deploy vía rsync

## Objetivo

Aprender a configurar un servidor web básico usando Nginx para servir un sitio estático (HTML, CSS, JS), y automatizar el despliegue de cambios locales al servidor remoto mediante `rsync`.

## Entorno utilizado

- **Servidor:** VM local con Ubuntu Server (VirtualBox, modo Bridged, IP `192.168.0.80`).
- **Edición del sitio:** Windows (editor de código).
- **Ejecución del deploy:** WSL (Windows Subsystem for Linux) con Ubuntu, ya que `rsync` es una herramienta nativa de Linux.

## Pasos realizados

### 1. Instalar Nginx en el servidor

```bash
ssh miubuntu
sudo apt update
sudo apt install nginx -y
```

Nginx se habilita automáticamente al instalarse (a diferencia de `openssh-server`, que requirió `systemctl enable` manualmente en el proyecto anterior). Se verificó con:

```bash
sudo systemctl status nginx
```

Por defecto, Nginx sirve archivos desde `/var/www/html/`, mostrando inicialmente la página de bienvenida (`index.nginx-debian.html`). Se confirmó el acceso desde el navegador de Windows entrando a `http://192.168.0.80`.

### 2. Configurar WSL como entorno de deploy

Se instaló WSL para tener un entorno Linux nativo dentro de Windows, con acceso a herramientas como `rsync` y `bash`, necesarias para correr el script de deploy.

```powershell
wsl --install
```

Se verificó que `rsync` ya venía incluido en la instalación de Ubuntu de WSL.

### 3. Generar una clave SSH nueva, específica para WSL

Como WSL es un entorno aislado, con su propio sistema de archivos, separado del de Windows (aunque corran en la misma máquina física), se generó un tercer par de claves SSH, distinto a los usados desde PowerShell:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_wsl -C "clave-wsl"
```

Se copió la clave pública al servidor:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519_wsl.pub vboxuser@192.168.0.80
```

Se configuró un alias en el `~/.ssh/config` propio de WSL (archivo independiente del `config` de Windows):

```
Host server-ubuntu
    HostName 192.168.0.80
    User vboxuser
    IdentityFile ~/.ssh/id_ed25519_wsl
```

Se verificó la conexión sin contraseña:

```bash
ssh server-ubuntu
```

### 4. Crear el sitio estático

Se armó un sitio simple en Windows, compuesto por:
- `index.html`
- `style.css`
- `script.js`

El sitio consume la API pública de The Simpsons, mostrando personajes con una barra de búsqueda dinámica del lado del cliente (filtrado en JavaScript, sin recargar la página).

### 5. Ajustar permisos en el servidor

Por defecto, `/var/www/html/` pertenece a `root`, por lo que `vboxuser` no tenía permisos de escritura directa. En vez de usar `sudo` dentro del script (lo cual rompería el flujo de autenticación solo por clave, pidiendo contraseña en cada deploy), se optó por cambiar el dueño de la carpeta una única vez:

```bash
sudo chown -R vboxuser:vboxuser /var/www/html/
```

### 6. Script de deploy (`deploy.sh`)

Se creó un script en WSL para sincronizar el sitio local con el servidor remoto usando `rsync`:

```bash
#!/bin/bash
echo "Comenzando deploy"
rsync -av "$1/" server-ubuntu:/var/www/html/
```

Puntos clave del script:
- `-a` (archive mode): preserva permisos, timestamps, y copia subdirectorios recursivamente.
- `-v` (verbose): muestra en pantalla qué archivos se están transfiriendo.
- **La barra `/` forzada al final de `"$1/"`** es fundamental: sincroniza el *contenido* de la carpeta de origen, no la carpeta como entidad. Sin la barra, `rsync` habría copiado la carpeta completa dentro de `/var/www/html/` (por ejemplo `/var/www/html/web-basic/index.html`), y Nginx no habría encontrado el `index.html` en la raíz esperada.
- El alias `server-ubuntu` (definido en el `~/.ssh/config` de WSL) resuelve automáticamente el usuario, IP y clave SSH a usar, sin necesidad de especificarlos en el comando.

Se le dieron permisos de ejecución:

```bash
chmod +x deploy.sh
```

### 7. Ejecutar el deploy

```bash
bash deploy.sh /mnt/f/web-basic
```

La ruta de origen se pasa como parámetro, accedida desde WSL vía el punto de montaje `/mnt/f/...` (equivalente a la unidad de Windows donde vive el proyecto).

Se comprobó el comportamiento incremental característico de `rsync`: en la primera ejecución transfiere todos los archivos; en ejecuciones posteriores sin cambios, solo transfiere metadata (unos pocos bytes), y si se modifica un archivo, transfiere únicamente ese archivo (o incluso solo las partes que cambiaron dentro de él, gracias al algoritmo de delta-transfer).

### 8. Verificación final

Se accedió a `http://192.168.0.80` desde el navegador de Windows, confirmando que el sitio de los Simpsons se sirve correctamente desde Nginx, con la búsqueda dinámica funcionando del lado del cliente.

## Resultado final

- Servidor Nginx sirviendo un sitio estático desde `/var/www/html/`, accesible vía la IP local de la VM.
- Flujo de trabajo completo: edición en Windows → deploy con un solo comando desde WSL (`bash deploy.sh <ruta>`) → cambios reflejados en el servidor mediante sincronización eficiente con `rsync`.
- Script `deploy.sh` robusto ante errores comunes (barra faltante en la ruta de origen).

## Nota de seguridad

Las claves SSH privadas (incluida `id_ed25519_wsl`, generada específicamente para este entorno) no se incluyen en este repositorio ni se comparten en ningún medio público.


## La web en cuestión siendo accedida desde http://192.168.0.80

![Web](static-site-nginx/web.png)
