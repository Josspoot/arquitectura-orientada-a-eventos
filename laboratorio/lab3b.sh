#!/bin/zsh
# Ejercicio 3 corregido: cada servicio se suscribe a los hechos que le importan.
set -u
D=${0:A:h}; OUT=$D/ev/ej3b.txt; : > $OUT
run() { local n=$1; shift; docker run -d --name $n --network container:eda-redis -v $D/bin:/eda:ro alpine:3.20 /eda/eda "$@" >/dev/null; echo "\$ ./eda $*        # terminal: $n" >> $OUT; sleep 1.2; }
pub() { echo "\$ curl -s -X POST localhost:3000$1 -H 'Content-Type: application/json' -d '$2'" >> $OUT; curl -s -X POST http://localhost:3100$1 -H 'Content-Type: application/json' -d "$2" >> $OUT; echo >> $OUT; sleep 1; }
docker rm -f api inv-p fin-p aten-p inv-d fin-d >/dev/null 2>&1
run api api-server
run inv-p consumer --topic pedido.creado
run fin-p consumer --topic pedido.creado
run aten-p consumer --topic pedido.creado
run inv-d consumer --topic devolucion.registrada
run fin-d consumer --topic devolucion.registrada
pub /topics/pedido.creado '{"pedidoId":"A-100"}'
pub /topics/devolucion.registrada '{"pedidoId":"A-100"}'
for n in inv-p fin-p aten-p inv-d fin-d; do echo "--- salida de la terminal $n ---" >> $OUT; docker logs $n 2>&1 >> $OUT; done
docker rm -f api inv-p fin-p aten-p inv-d fin-d >/dev/null 2>&1
