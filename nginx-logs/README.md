
# nginx-analyser

Analiza un access log de nginx y muestra:
- Top 5 IPs con más requests
- Top 5 paths más solicitados
- Top 5 códigos de status HTTP
- Top 5 user agents
- Cantidad de requests no-HTTP (tráfico sospechoso/escaneos)

## Uso
```bash
bash nginx-analyser.sh access.log
```

## Requisitos
- Formato de log "combined" estándar de nginx

  
## Requisitos
- Formato de log "combined" estándar de nginx

![Ejemplo de salida del script](nginx-logs/result.png)
*Ejemplo de salida del script*
