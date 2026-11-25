# Arquitectura orientada a eventos · Laboratorio eda + Redis

Sistemas backend · Equipo 4 · 25 de noviembre de 2026

**Equipo 4:** Josue Enmanuel Poot Mateo, Juan Jose Zapata Buenfil, Sergio Orion Huerta Martinez, Diego Ramirez Magaña y Angel Lugo.

## Entregables

| Archivo | Qué es |
|---|---|
| `equipo4_eda_laboratorio.docx` | Respuestas a las 5 preguntas de la entrega, con evidencia de la terminal |
| `evidencia/` | Salida completa de los ejercicios 1 a 4, y del 3 con la figura corregida (`ej3b.txt`) |
| `laboratorio/` | Scripts con los que se corrieron los ejercicios |

## Cómo reproducirlo

Compilamos [eda](https://github.com/jim-junior/eda) desde la etiqueta `0.0.8` en lugar de usar el binario publicado, que no tiene checksums. Cada terminal del tutorial corre en un contenedor que comparte la red de Redis. La API sale por el puerto 3100 porque el 3000 estaba ocupado.

```sh
cd laboratorio
git clone --depth 1 --branch 0.0.8 https://github.com/jim-junior/eda.git src
mkdir -p bin
docker run --rm -v "$PWD/src":/src:ro -v "$PWD/bin":/out -w /src -e CGO_ENABLED=0 golang:1.23-alpine go build -o /out/eda .
docker run -d --name eda-redis -p 6379:6379 -p 3100:3000 redis:7
zsh lab.sh      # ejercicios 1 a 4, la salida queda en ev/
zsh lab3b.sh    # ejercicio 3 con la figura corregida
docker rm -f eda-redis
```
