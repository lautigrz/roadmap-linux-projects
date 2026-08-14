# Log Archive Tool

Script Bash para **comprimir y archivar logs** en formato `.tar.gz`, agregando automáticamente la fecha y hora al nombre del archivo.

Proyecto de [Roadmap.sh](https://roadmap.sh/projects/log-archive-tool)

## Uso

Dar permisos de ejecución:

```bash
chmod +x log-archive.sh
```

### Archivar logs

```bash
./log-archive.sh -a <directorio>
```

Ejemplo:

```bash
./log-archive.sh -a logs
```

Por defecto, el archivo se guarda en:

```text
logs-archives/
```

Con un nombre como:

```text
logs_archive_20260814_165307.tar.gz
```

También se puede indicar un directorio de destino:

```bash
./log-archive.sh -a logs /tmp/archives
```

### Extraer un archivo

```bash
./log-archive.sh -e <archivo.tar.gz>
```

Por defecto, se extrae en:

```text
logs_archives_extract/
```

También se puede indicar un destino:

```bash
./log-archive.sh -e archivo.tar.gz /tmp/logs
```

## Opciones

| Opción | Descripción                  |
| ------ | ---------------------------- |
| `-a`   | Archivar y comprimir logs    |
| `-e`   | Extraer un archivo `.tar.gz` |

## Tecnologías

* Bash
* `tar`
* `gzip`
* `date`
* `mkdir`

## Objetivo

Proyecto de práctica para trabajar con **Bash, argumentos, funciones, estructuras condicionales, `case` y manejo de archivos y directorios**.
