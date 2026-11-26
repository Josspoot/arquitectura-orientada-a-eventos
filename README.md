# Arquitectura orientada a eventos · Laboratorio eda + Redis

Sistemas backend · Equipo 4 · 25 de noviembre de 2026

**Asignatura:** Fundamentos de Arquitectura de Software y Desarrollo Backend
**Docente:** Gimer Amilcar Cervera Evia

| Integrante | Matrícula |
|---|---|
| Angel Abraham Lugo Saenz | SW2409052 |
| Juan Jose Zapata Buenfil | SW2509044 |
| Josue Enmanuel Poot Mateo | SW2509033 |
| Sergio Orion Huerta Martinez | SW2509012 |
| Diego Ramirez Magaña | SW2509051 |

## Entregables

| Archivo | Qué es |
|---|---|
| `equipo4_eda_laboratorio.docx` | Respuestas a las 5 preguntas de la entrega, con evidencia de la terminal |
| `evidencia/capturas/` | Capturas de Terminal de cada ejercicio (las mismas del Word) |
| `evidencia/*.txt` | Salida completa de los ejercicios 1 a 4, y del 3 con la figura corregida (`ej3b.txt`) |
| `laboratorio/` | Scripts con los que se corrieron los ejercicios (`lab.sh`, `lab3b.sh`) y se tomaron las capturas (`shots.sh`, `compose.py`, `eda`) |

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
