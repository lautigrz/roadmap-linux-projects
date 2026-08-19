# Dockerized Node.js Service

Proyecto de un servicio Node.js dockerizado, publicado en **Amazon ECR** y desplegado automáticamente en una instancia **EC2** mediante **GitHub Actions**.

Ver el papeline en el [Repositorio](https://github.com/lautigrz/dockerized-service) independiente

El proyecto implementa un flujo básico 


```text
GitHub
   │
   │ Push a main
   ▼
GitHub Actions
   │
   ├── Checkout
   ├── Autenticación AWS mediante OIDC
   ├── Login en Amazon ECR
   ├── Build de imagen Docker
   ├── Push de imagen a ECR
   │
   └── SSH → EC2
             │
             ├── Pull de nueva imagen
             ├── Stop del contenedor anterior
             ├── Remove del contenedor anterior
             └── Run del nuevo contenedor
```

## Tecnologías

* Node.js 22
* Docker
* Amazon ECR
* Amazon EC2
* AWS IAM
* AWS OIDC
* GitHub Actions
* SSH

## Estructura del proyecto

```text
dockerized-service/
├── Dockerfile
├── index.js
├── package.json
└── .github/
    └── workflows/
        └── deploy.yml
```

## Aplicación Node.js

El servicio expone el puerto `3000`.

Para ejecutarlo localmente:

```bash
node index.js
```

Luego se puede probar con:

```bash
curl http://localhost:3000/
```

## Docker

### Construcción de la imagen

La imagen utiliza una base de Node.js Alpine para reducir considerablemente el tamaño de la imagen.

```bash
docker build -t node-service:alpine .
```

Ver las imágenes:

```bash
docker images node-service
```

### Ejecutar localmente

```bash
docker run -d \
  --name node-service \
  -p 3000:3000 \
  node-service:alpine
```

Probar:

```bash
curl http://localhost:3000/
```

## Amazon ECR

Se creó un repositorio de Amazon Elastic Container Registry:

```text
node-service
```

La URI del repositorio utiliza la región `us-east-2`:

```text
295392291513.dkr.ecr.us-east-2.amazonaws.com/node-service
```

### Autenticación en ECR

AWS CLI se utiliza para autenticarse con AWS.

Después se realiza el login de Docker contra ECR.

Una vez autenticado, la imagen puede etiquetarse:

```bash
docker tag node-service:alpine \
  295392291513.dkr.ecr.us-east-2.amazonaws.com/node-service:alpine
```

Y publicarse:

```bash
docker push \
  295392291513.dkr.ecr.us-east-2.amazonaws.com/node-service:alpine
```

El tag `alpine` es mutable: cada nuevo push actualiza la imagen a la que apunta ese tag.

## EC2

Se creó una instancia EC2 con Ubuntu y se le asignó un IAM Role.

El rol permite que la instancia pueda interactuar con los servicios AWS necesarios sin almacenar Access Keys dentro de la instancia.

Se verificó la identidad del rol con:

```bash
aws sts get-caller-identity
```

La imagen almacenada en ECR puede descargarse desde EC2:

```bash
docker pull \
  295392291513.dkr.ecr.us-east-2.amazonaws.com/node-service:alpine
```

Y ejecutarse:

```bash
docker run -d \
  --name node-service \
  -p 3000:3000 \
  295392291513.dkr.ecr.us-east-2.amazonaws.com/node-service:alpine
```

Comprobar el contenedor:

```bash
docker ps
```

Probar el servicio:

```bash
curl http://localhost:3000/
```

## GitHub Actions

El workflow se ejecuta automáticamente cuando se realiza un push a `main`.

```yaml
on:
  push:
    branches:
      - main
```

### Checkout

GitHub Actions descarga el contenido del repositorio mediante:

```yaml
- name: Checkout code
  uses: actions/checkout@v4
```

Esto es necesario para que el runner tenga acceso al `Dockerfile`, `index.js` y `package.json`.

### Autenticación AWS mediante OIDC

GitHub Actions utiliza OpenID Connect para asumir un IAM Role de AWS:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: us-east-2
```

Esto evita almacenar Access Keys de AWS en GitHub.

El IAM Role tiene una relación de confianza con el proveedor OIDC de GitHub:

```text
token.actions.githubusercontent.com
```

y restringe el acceso al repositorio y branch correspondientes.

### Login en ECR

```yaml
- name: Login to Amazon ECR
  id: login-ecr
  uses: aws-actions/amazon-ecr-login@v2
```

El output:

```yaml
${{ steps.login-ecr.outputs.registry }}
```

proporciona el registry completo de ECR.

Por ejemplo:

```text
295392291513.dkr.ecr.us-east-2.amazonaws.com
```

### Build

La imagen se construye utilizando:

```yaml
- name: Build Docker image
  run: |
    docker build -t node-service:alpine .
```

### Tag

Se genera el tag correspondiente al repositorio de ECR:

```yaml
- name: Tag Docker image
  run: |
    docker tag node-service:alpine \
      ${{ steps.login-ecr.outputs.registry }}/$ECR_REPOSITORY:alpine
```

`ECR_REPOSITORY` contiene:

```text
node-service
```

No es un secreto porque solamente representa el nombre del repositorio.

### Push

La imagen se publica en ECR:

```yaml
- name: Push Docker image to Amazon ECR
  run: |
    docker push \
      ${{ steps.login-ecr.outputs.registry }}/$ECR_REPOSITORY:alpine
```

## Variables y Secrets

Se separaron los valores de configuración de las credenciales.

### Secrets

Los siguientes valores se almacenan como **GitHub Repository Secrets**:

```text
AWS_ROLE_ARN
EC2_SSH_KEY
USER
PASSWORD
```

`AWS_ROLE_ARN` permite que GitHub Actions asuma el IAM Role.

`EC2_SSH_KEY` contiene la clave privada utilizada para conectarse mediante SSH al EC2.

`USER` y `PASSWORD` contienen las variables sensibles utilizadas por la aplicación.

### Configuración

El nombre del repositorio ECR no es secreto:

```yaml
env:
  ECR_REPOSITORY: node-service
```

El host y usuario de EC2 también pueden manejarse como configuración:

```text
EC2_HOST
EC2_USER
```

## Variables de entorno del contenedor

Las variables necesarias para la aplicación se transfieren desde GitHub Actions al servidor EC2.

El workflow utiliza:

```yaml
env:
  USER: ${{ secrets.USER }}
  PASSWORD: ${{ secrets.PASSWORD }}
```

y las pasa a la sesión SSH:

```yaml
envs: USER,PASSWORD
```

Finalmente se entregan al contenedor:

```bash
docker run -d \
  --name node-service \
  -e USER="$USER" \
  -e PASSWORD="$PASSWORD" \
  -p 3000:3000 \
  "$IMAGE"
```

Dentro de Node.js pueden accederse mediante:

```javascript
process.env.USER
process.env.PASSWORD
```

Los valores sensibles nunca se escriben directamente en el repositorio.

## Deploy automático en EC2

Después de publicar la imagen en ECR, GitHub Actions se conecta al EC2 mediante SSH.

El proceso de deployment es:

```bash
docker pull "$IMAGE"

docker stop node-service || true

docker rm node-service || true

docker run -d \
  --name node-service \
  -e USER="$USER" \
  -e PASSWORD="$PASSWORD" \
  -p 3000:3000 \
  "$IMAGE"
```

Los comandos `|| true` permiten continuar aunque el contenedor todavía no exista.

Por ejemplo, si es el primer deployment:

```text
docker stop node-service
→ No existe
→ continúa

docker rm node-service
→ No existe
→ continúa

docker run ...
→ crea el contenedor
```

En deployments posteriores:

```text
docker pull
    ↓
detiene contenedor anterior
    ↓
elimina contenedor anterior
    ↓
crea contenedor con nueva imagen
```

## SSH

Se creó un par de claves SSH exclusivo para GitHub Actions:

```text
github_actions_ec2
github_actions_ec2.pub
```

La clave pública se agregó al archivo:

```text
~/.ssh/authorized_keys
```

del usuario `ubuntu` en EC2.

La clave privada se almacenó como:

```text
EC2_SSH_KEY
```

en GitHub Secrets.

De esta forma GitHub Actions puede conectarse al servidor sin almacenar la clave privada dentro del repositorio.

## Flujo completo

Una vez configurado todo, solamente es necesario realizar:

```bash
git add .
git commit -m "update service"
git push origin main
```

GitHub Actions ejecutará automáticamente:

```text
1. Checkout del código
        ↓
2. Autenticación AWS mediante OIDC
        ↓
3. Login en Amazon ECR
        ↓
4. Build de Docker
        ↓
5. Tag de la imagen
        ↓
6. Push a ECR
        ↓
7. Conexión SSH al EC2
        ↓
8. Pull de la nueva imagen
        ↓
9. Stop del contenedor anterior
        ↓
10. Remove del contenedor anterior
        ↓
11. Run del nuevo contenedor
        ↓
12. Servicio actualizado
```

## Resultado

El proyecto cuenta con un pipeline de CI/CD que permite actualizar el servicio mediante un simple:

```bash
git push origin main
```

La nueva imagen Docker se construye automáticamente, se publica en Amazon ECR y posteriormente se despliega en la instancia EC2.
