#!/bin/zsh
# Corre los ejercicios 1-4 del laboratorio y guarda la evidencia en ev/.
# Cada proceso eda corre en un contenedor que comparte la red de eda-redis,
# así ve Redis en localhost:6379 y su puerto 3000 sale al host como 3100.
set -u
D=${0:A:h}
EV=$D/ev
mkdir -p $EV
API=http://localhost:3100

start() { # start <nombre> <args de eda...>
  local n=$1; shift
  docker rm -f $n >/dev/null 2>&1
  docker run -d --name $n --network container:eda-redis -v $D/bin:/eda:ro alpine:3.20 /eda/eda "$@" >/dev/null
  echo "\$ ./eda $*        # terminal: $n" >> $OUT
  sleep 1.5
}
stop() { docker rm -f $1 >/dev/null 2>&1; echo "# Ctrl+C en la terminal $1 (proceso detenido)" >> $OUT; sleep 0.5; }
pub() { # pub <ruta> <json>
  echo "\$ curl -s -X POST localhost:3000$1 -H 'Content-Type: application/json' -d '$2'" >> $OUT
  curl -s -X POST $API$1 -H 'Content-Type: application/json' -d "$2" >> $OUT
  echo >> $OUT
  sleep 1
}
show() { # show <nombre>
  echo "--- salida de la terminal $1 ---" >> $OUT
  docker logs $1 2>&1 | grep -v -e '^ *$' -e '┌' -e '│' -e '└' >> $OUT
  echo "---" >> $OUT
}
note() { echo "# $*" >> $OUT; }

docker rm -f api c1 c2 inv fin aten master worker >/dev/null 2>&1

# ---------- Ejercicios 1 y 2 ----------
OUT=$EV/ej1_2.txt; : > $OUT
note "Ejercicio 1: un consumidor recibe"
start api api-server
start c1 consumer --topic orderCreated
pub /topics/orderCreated '{"order_id":123,"total":49.99}'
show c1
note "Paso 1: segundo consumidor y se publica de nuevo"
start c2 consumer --topic orderCreated
pub /topics/orderCreated '{"order_id":124,"total":15.50}'
show c1; show c2
note "Paso 2: se detienen ambos consumidores y se publica"
stop c1; stop c2
echo '$ docker exec eda-redis redis-cli PUBSUB NUMSUB orderCreated' >> $OUT
docker exec eda-redis redis-cli PUBSUB NUMSUB orderCreated >> $OUT
pub /topics/orderCreated '{"order_id":125,"total":99.00}'
note "Paso 3: se reinicia un consumidor"
start c1 consumer --topic orderCreated
sleep 3
show c1
note "El pedido 125 no aparece: Redis Pub/Sub no lo guardó"

# ---------- Ejercicio 3 ----------
OUT=$EV/ej3.txt; : > $OUT
start inv consumer --topic nuevoPedido
start fin consumer --topic devolucion
start aten consumer --topic consultaStock
pub /topics/nuevoPedido '{"pedidoId":"A-100"}'
pub /topics/devolucion '{"pedidoId":"A-100"}'
pub /topics/consultaStock '{"sku":"CAM-01"}'
show inv; show fin; show aten
docker rm -f inv fin aten c1 >/dev/null 2>&1

# ---------- Ejercicio 4 ----------
OUT=$EV/ej4.txt; : > $OUT
docker exec eda-redis redis-cli DEL message:queue >/dev/null
docker rm -f api >/dev/null 2>&1
note "En este orden: master, worker, api"
start master consumer -d --master
start worker consumer -d
start api api-server
pub /deferred-exec '{"task_id":1,"description":"procesar archivos"}'
sleep 11
show worker
note "Paso 1: se detiene solo el worker y se publica"
stop worker
pub /deferred-exec '{"task_id":2,"description":"generar reporte"}'
pub /deferred-exec '{"task_id":3,"description":"enviar correo"}'
echo '$ docker exec eda-redis redis-cli LRANGE message:queue 0 -1' >> $OUT
docker exec eda-redis redis-cli LRANGE message:queue 0 -1 >> $OUT
show master
note "Paso 2: se reinicia el worker"
start worker consumer -d
sleep 13
show worker
echo '$ docker exec eda-redis redis-cli LRANGE message:queue 0 -1' >> $OUT
docker exec eda-redis redis-cli LRANGE message:queue 0 -1 >> $OUT
note "Paso 3: se detiene el master y se publica"
stop master
pub /deferred-exec '{"task_id":4,"description":"tarea sin master"}'
echo '$ docker exec eda-redis redis-cli PUBSUB NUMSUB master' >> $OUT
docker exec eda-redis redis-cli PUBSUB NUMSUB master >> $OUT
sleep 11
echo '$ docker exec eda-redis redis-cli LRANGE message:queue 0 -1' >> $OUT
docker exec eda-redis redis-cli LRANGE message:queue 0 -1 >> $OUT
show worker
note "La tarea 4 no llegó a la lista: se perdió en Pub/Sub"

docker rm -f api worker master >/dev/null 2>&1
echo listo
