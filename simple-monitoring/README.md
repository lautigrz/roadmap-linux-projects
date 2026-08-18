# Monitorización del Sistema con Netdata

Este proyecto implementa una solución de monitorización de infraestructura en tiempo real sobre Linux utilizando **Netdata**. El objetivo principal es comprender los principios fundamentales de la observabilidad de sistemas, configurar métricas esenciales, definir reglas de alertado proactivo y automatizar el ciclo de vida del agente (instalación, prueba y desinstalación) mediante scripts en Bash.

---

## Objetivos del Proyecto

* **Observabilidad en tiempo real:** Medir y visualizar métricas críticas de hardware (CPU, memoria RAM e I/O de disco) con resolución por segundo.
* **Gestión de alertas:** Diseñar e implementar alarmas personalizadas basadas en umbrales de consumo y ventanas temporales de cálculo.
* **Automatización (DevOps mindset):** Desarrollar un flujo de scripts para provisionar el agente, estresar el sistema de forma controlada y realizar una limpieza completa sin dejar residuos en el sistema operativo.

---

## Arquitectura y Componentes

* **Motor de Métricas (Netdata Agent):** Agente ligero que recopila estadísticas del kernel de Linux a través de `/proc`, `/sys` y `cgroups`. Corre localmente en el puerto `19999`.
* **Motor de Salud (Health Management):** Subsistema interno de Netdata encargado de evaluar expresiones lógicas cada intervalo definido y emitir estados (`CLEAR`, `WARNING`, `CRITICAL`).
* **Generador de Carga (`stress`):** Herramienta de pruebas utilizada para inducir cuellos de botella sintéticos en el procesador y la memoria para validar la reacción de las alertas.

---

## Estructura del Repositorio

```text
├── setup.sh               # Instalacion automatizada de Netdata y despliegue de alertas
├── test_dashboard.sh      # Herramienta CLI para simular picos de carga (CPU y RAM)
├── cleanup.sh             # Purga total de paquetes, configuraciones, llaves GPG y repositorios
└── README.md              # Documentación del proyecto

```

---

## Implementación Paso a Paso

### 1. Instalación y Puesta en Marcha

El despliegue instala el agente y habilita el demonio en `systemd`. Una vez en ejecución, la interfaz web queda disponible de forma local:

```text
URL de acceso: http://localhost:19999

```

### 2. Configuración de Alertas Personalizadas

Se creó una regla en `/etc/netdata/health.d/cpu-alert.conf` asociada al contexto `system.cpu`. La alarma evalúa el porcentaje de uso acumulado (`user`, `system`, `softirq`, `irq`, `guest`) promediado en los últimos 2 minutos:

```ini
alarm: mi_cpu_usage
   on: system.cpu
class: Utilization
 type: System
component: CPU
   os: linux
lookup: average -2m unaligned of user,system,softirq,irq,guest
units: %
every: 10s
 warn: $this > (($status >=$WARNING)  ? (75) : (85))
 crit: $this > (($status >=$CRITICAL) ? (85) : (95))
delay: down 5m
 info: Promedio de CPU alto durante los ultimos 2 minutos
   to: sysadmin

```

* **Cálculo de histeresis:** Se utilizan operadores ternarios para evitar oscilaciones (flapping); una vez que entra en `WARNING` (85%), requiere bajar del 75% para regresar al estado normal.
* **Recarga en caliente:** Las modificaciones se cargan inmediatamente en el motor de Netdata mediante:
```bash
sudo netdatacli reload-health

```



---

## Pruebas y Validación

Para comprobar el comportamiento del panel y la activación de alarmas, se programó `test_dashboard.sh` con flags de ejecución controlada:

| Comando | Acción | Validación en Dashboard |
| --- | --- | --- |
| `./test_dashboard.sh -c` | Estresa el 100% de los núcleos detectados (`nproc`) por 60s | Subida inmediata en `system.cpu` y transición de alarma a `WARNING`/`CRITICAL` |
| `./test_dashboard.sh -m` | Reserva 2 GB de memoria de forma continua por 60s | Consumo sostenido en el gráfico `system.ram` |

---

## Ciclo de Desinstalación y Purga

Para mantener la idempotencia en entornos de desarrollo o CI/CD, el proceso de limpieza (`cleanup.sh`) ejecuta un ciclo completo de saneamiento:

1. **Detención:** Freno del proceso y deshabilitación en `systemctl`.
2. **Purga de paquetes:** Eliminación vía `apt-get purge` de `netdata` y dependencias huérfanas con `autoremove`.
3. **Limpieza del filesystem:** Eliminación explícita de `/etc/netdata`, `/var/log/netdata`, `/var/lib/netdata` y sockets en `/run`.
4. **Remoción de repositorios:** Borrado del paquete `netdata-repo`, archivos `.list` en `sources.list.d` y llaves GPG asociadas para evitar advertencias de firmas en `apt-get update`.

---
