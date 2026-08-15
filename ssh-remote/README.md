# Proyecto: Configuración de Servidor Linux con acceso SSH

## Objetivo

Aprender y practicar los conceptos básicos de administración de Linux configurando un servidor remoto (en este caso, una VM local con VirtualBox) accesible por SSH mediante autenticación por clave pública/privada, usando **dos pares de claves distintos**, simplificando la conexión con un alias en `~/.ssh/config`, e instalando `fail2ban` como protección contra ataques de fuerza bruta.

## Entorno utilizado

- **Servidor:** VM local con Ubuntu Server, corriendo en VirtualBox (adaptador de red en modo *Bridged*, con IP asignada en la red local).
- **Cliente:** Windows, usando PowerShell y el cliente OpenSSH incluido.

## Pasos realizados

### 1. Instalar y habilitar el servidor SSH en la VM

Ubuntu Server no siempre trae el servidor SSH instalado por defecto (solo el cliente). Se instaló el paquete correspondiente:

```bash
sudo apt update
sudo apt install openssh-server -y
sudo systemctl enable ssh
sudo systemctl status ssh
```

- `enable` asegura que el servicio arranque automáticamente con la VM.
- `status` confirma que el servicio está activo y escuchando conexiones en el puerto 22.

### 2. Obtener la IP de la VM

```bash
ip a
```

Se identificó la IP asignada en la interfaz de red (`enp0s3` o similar) dentro del rango de la red local (en este caso, `192.168.0.80`).

### 3. Generar dos pares de claves SSH (desde la máquina cliente)

```powershell
ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\id_ed25519_vm1" -C "clave-ssh-1"
ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\id_ed25519_vm2" -C "clave-ssh-2"
```

Cada comando genera un par de claves:
- Clave **privada** (sin extensión): se queda únicamente en el cliente, nunca se comparte.
- Clave **pública** (`.pub`): se copia al servidor para autorizar el acceso.

Se generaron dos pares independientes para simular un escenario real donde distintos orígenes (dispositivos, usuarios o procesos) tienen accesos separados y revocables sin afectarse entre sí.

### 4. Copiar las claves públicas al servidor

```powershell
type "$env:USERPROFILE\.ssh\id_ed25519_vm1.pub" | ssh vboxuser@192.168.0.80 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
type "$env:USERPROFILE\.ssh\id_ed25519_vm2.pub" | ssh vboxuser@192.168.0.80 "cat >> ~/.ssh/authorized_keys"
```

Esto agrega ambas claves públicas al archivo `~/.ssh/authorized_keys` del servidor, la lista de claves autorizadas para autenticarse. Se pidió la contraseña del usuario solo en este paso inicial, ya que todavía no existía ninguna clave autorizada.

### 5. Verificar la conexión sin contraseña

```powershell
ssh -i "$env:USERPROFILE\.ssh\id_ed25519_vm1" vboxuser@192.168.0.80
ssh -i "$env:USERPROFILE\.ssh\id_ed25519_vm2" vboxuser@192.168.0.80
```

Ambas conexiones funcionaron correctamente sin solicitar contraseña, confirmando que la autenticación por clave estaba operativa.

### 6. Configurar alias en `~/.ssh/config`

Se creó el archivo de configuración en el cliente:

```
Host miubuntu
    HostName 192.168.0.80
    User vboxuser
    IdentityFile ~/.ssh/id_ed25519_vm1
```

Esto permite conectarse con:

```powershell
ssh miubuntu
```

sin necesidad de especificar usuario, IP, ni ruta de la clave en cada conexión.

### 7. Instalar y configurar fail2ban (objetivo extendido)

```bash
sudo apt install fail2ban -y
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local
```

Se configuró la sección `[sshd]` con:

```
[sshd]
enabled = true
port    = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 5
bantime = 3600
findtime = 600
```

- `maxretry = 5`: banea tras 5 intentos fallidos.
- `findtime = 600`: ventana de 10 minutos para contar esos intentos.
- `bantime = 3600`: duración del baneo, 1 hora.

Se reinició y verificó el servicio:

```bash
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban
sudo fail2ban-client status sshd
```

Resultado: el jail `sshd` quedó activo y monitoreando el servicio SSH correctamente.

## Resultado final

- Servidor Linux (VM local) con SSH habilitado y funcionando.
- Acceso configurado con **dos pares de claves SSH** independientes, sin uso de contraseña en el día a día.
- Conexión simplificada mediante alias (`ssh miubuntu`) usando `~/.ssh/config`.
- Protección contra ataques de fuerza bruta mediante `fail2ban`, monitoreando el servicio SSH.

## Nota de seguridad

Las claves **privadas** (`id_ed25519_vm1` e `id_ed25519_vm2`, sin extensión `.pub`) no se incluyen en este repositorio ni se comparten en ningún medio público. Solo se documentan los pasos seguidos para completar el proyecto.
