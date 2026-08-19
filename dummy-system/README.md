# Servicio systemd de prueba — Dummy Service

## Descripción

Este ejercicio muestra cómo crear, configurar, iniciar y administrar un servicio propio utilizando **systemd** en Linux.

El servicio creado se llama `dummy.service` y ejecuta un script Bash llamado `dummy.sh`.

---

## 1. Script del servicio

El script se encuentra en:

```bash
/home/user/dummy.sh
```

El script imprime un mensaje y mantiene el proceso activo durante un período determinado mediante `sleep`.

Ejemplo:

```bash
#!/bin/bash

echo "Dummy service is running..."

sleep 10
```

Para que el script pueda ejecutarse directamente:

```bash
chmod +x /home/user/dummy.sh
```

---

## 2. Archivo `.service`

Los servicios personalizados de systemd se pueden crear en:

```bash
/etc/systemd/system/
```

Creamos:

```bash
sudo nano /etc/systemd/system/dummy.service
```

El contenido utilizado fue:

```ini
[Unit]
Description=Creacion de prueba de servicio

[Service]
WorkingDirectory=/home/lautaro_gerez
ExecStart=/bin/bash /home/lautaro_gerez/dummy.sh
Restart=always

[Install]
WantedBy=multi-user.target
```

---

## 3. Anatomía del archivo `.service`

### `[Unit]`

Contiene información general del servicio y sus relaciones con otras unidades.

```ini
[Unit]
Description=Creacion de prueba de servicio
```

### `Description`

Es una descripción del servicio.

Aparece, por ejemplo, cuando ejecutamos:

```bash
systemctl status dummy
```

---

### `[Service]`

Define cómo se ejecuta el proceso.

```ini
[Service]
WorkingDirectory=/home/lautaro_gerez
ExecStart=/bin/bash /home/lautaro_gerez/dummy.sh
Restart=always
```

### `WorkingDirectory`

Define el directorio de trabajo del proceso:

```ini
WorkingDirectory=/home/lautaro_gerez
```

Es equivalente conceptualmente a ejecutar el proceso desde ese directorio.

Es importante diferenciarlo de `ExecStart`:

```text
WorkingDirectory → ¿Desde dónde se ejecuta?
ExecStart        → ¿Qué programa se ejecuta?
```

---

### `ExecStart`

Define el programa que systemd debe ejecutar:

```ini
ExecStart=/bin/bash /home/lautaro_gerez/dummy.sh
```

En este caso:

```text
/bin/bash
    ↓
ejecuta
    ↓
/home/lautaro_gerez/dummy.sh
```

Se utilizó una ruta absoluta porque `systemd` no utiliza el directorio actual de la terminal para resolver `ExecStart`.

---

### `Restart`

Define qué hacer cuando termina el proceso:

```ini
Restart=always
```

Con `always`, systemd vuelve a iniciar el servicio cuando el proceso termina.

Por ejemplo:

```text
dummy.sh
   ↓
sleep 10
   ↓
termina
   ↓
systemd detecta que terminó
   ↓
Restart=always
   ↓
dummy.sh vuelve a ejecutarse
```

---

### `[Install]`

Define cómo se integra el servicio cuando se habilita.

```ini
[Install]
WantedBy=multi-user.target
```

Esto permite habilitar el servicio para que se inicie automáticamente durante el arranque del sistema.

---

# 4. Recargar la configuración

Después de crear o modificar un archivo `.service`, hay que hacer:

```bash
sudo systemctl daemon-reload
```

Esto hace que systemd vuelva a leer las configuraciones de las unidades.

---

# 5. Iniciar el servicio

Para iniciarlo manualmente:

```bash
sudo systemctl start dummy
```

---

# 6. Reiniciar el servicio

Para detenerlo y volver a iniciarlo:

```bash
sudo systemctl restart dummy
```

---

# 7. Consultar el estado

Para comprobar si está funcionando:

```bash
sudo systemctl status dummy
```

Cuando funciona correctamente aparece:

```text
Active: active (running)
```

Durante la práctica se obtuvo:

```text
Active: active (running)
Main PID: 3569 (dummy.sh)
```

También se pudo observar el proceso secundario:

```text
├─3569 /bin/bash /home/lautaro_gerez/dummy.sh
└─3570 sleep 10
```

Esto muestra la relación entre el proceso principal del servicio y el comando `sleep` ejecutado por el script.

---

# 8. Logs del servicio

Los mensajes escritos por el programa en `stdout`/`stderr` pueden ser recopilados por systemd mediante el journal.

Para consultar los logs:

```bash
journalctl -u dummy
```

Para seguirlos en tiempo real:

```bash
journalctl -u dummy -f
```

Por ejemplo, el mensaje:

```text
Dummy service is running...
```

apareció en:

```text
dummy.sh[3569]: Dummy service is running...
```

Esto demuestra que systemd está capturando la salida del script.

---

# 9. Habilitar el servicio al arrancar Linux

`start` y `enable` tienen funciones diferentes.

### Iniciar ahora

```bash
sudo systemctl start dummy
```

### Iniciar automáticamente durante el arranque

```bash
sudo systemctl enable dummy
```

### Hacer ambas cosas

```bash
sudo systemctl enable --now dummy
```

---

# 10. Detener y deshabilitar

Detener el servicio:

```bash
sudo systemctl stop dummy
```

Evitar que se inicie automáticamente:

```bash
sudo systemctl disable dummy
```

---

# 11. Error `203/EXEC`

Durante la práctica apareció:

```text
status=203/EXEC
```

Este código indica que systemd **no pudo ejecutar el programa indicado en `ExecStart`**.

Inicialmente se utilizó:

```ini
ExecStart=/dummy.sh
```

Pero `/dummy.sh` significa:

```text
/dummy.sh
```

es decir, un archivo llamado `dummy.sh` directamente en la raíz del sistema.

El archivo realmente estaba en:

```text
/home/user/dummy.sh
```

Por eso se corrigió a:

```ini
ExecStart=/bin/bash /home/user/dummy.sh
```

También es importante comprobar que un script tenga:

* una ruta correcta;
* permisos de ejecución cuando corresponda;
* un `shebang` válido, por ejemplo:

```bash
#!/bin/bash
```

---

# 12. Diferencia entre ruta absoluta y relativa

Una ruta absoluta comienza desde `/`:

```text
/home/user/dummy.sh
```

Una ruta relativa depende del directorio de trabajo:

```text
./dummy.sh
```

En systemd, `ExecStart` debe utilizar una ruta absoluta al ejecutable o un ejecutable que systemd pueda resolver de acuerdo con sus reglas. Por eso, para evitar problemas, se utilizó:

```ini
ExecStart=/bin/bash /home/user/dummy.sh
```

Mientras que `WorkingDirectory` se utilizó para definir el directorio desde el cual trabaja el proceso:

```ini
WorkingDirectory=/home/user
```

---

# 13. Flujo completo

El proceso realizado fue:

```text
Crear script
    ↓
/home/user/dummy.sh
    ↓
Crear unidad systemd
    ↓
/etc/systemd/system/dummy.service
    ↓
daemon-reload
    ↓
start / restart
    ↓
systemctl status
    ↓
journalctl
```

Los comandos principales utilizados fueron:

```bash
sudo nano /etc/systemd/system/dummy.service

sudo systemctl daemon-reload

sudo systemctl start dummy
sudo systemctl restart dummy

sudo systemctl status dummy

sudo systemctl enable dummy
sudo systemctl disable dummy

sudo systemctl stop dummy

journalctl -u dummy
journalctl -u dummy -f
```

## Conceptos clave

```text
.service
    ↓
Archivo de configuración de una unidad systemd

[Unit]
    ↓
Información general y relaciones

[Service]
    ↓
Cómo ejecutar y administrar el proceso

[Install]
    ↓
Cómo habilitarlo/integrarlo al arranque

ExecStart
    ↓
Qué ejecutar

WorkingDirectory
    ↓
Desde dónde trabaja el proceso

Restart
    ↓
Qué hacer cuando termina

systemctl
    ↓
Administrar servicios

journalctl
    ↓
Consultar los logs
```

La idea fundamental es que **systemd actúa como administrador del proceso**: recibe la configuración del `.service`, ejecuta el programa indicado, controla su estado, puede reiniciarlo y recopila sus logs.
