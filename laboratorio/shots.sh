#!/bin/zsh
# Corre los ejercicios en ventanas reales de Terminal y toma una captura de cada ventana.
set -u
D=${0:A:h}; L=$D/lab; SH=$D/shots
mkdir -p $SH
typeset -A WID TTY

# win <nombre> <x> <y> <ancho> <alto>: abre una ventana en la carpeta del laboratorio
win() {
  local out
  out=$(osascript <<EOF
tell application "Terminal"
  set t to do script "cd '$L' && clear"
  set w to first window whose tabs contains t
  set current settings of w to settings set "Basic"
  set custom title of t to "$1"
  set title displays custom title of t to true
  set title displays device name of t to false
  set title displays shell path of t to false
  set title displays window size of t to false
  return (id of w as text) & " " & (tty of t)
end tell
EOF
)
  WID[$1]=${out%% *}; TTY[$1]=${${out##* }:t}
  sleep 1
}
# type <nombre> <comando>: escribe el comando en esa ventana
type_in() {
  local cmd=${2//\\/\\\\}; cmd=${cmd//\"/\\\"}
  osascript -e "tell application \"Terminal\" to do script \"$cmd\" in (first tab of window id ${WID[$1]})" >/dev/null
}
# stop <nombre>: detiene el eda de esa ventana (equivale a Ctrl+C)
stop() { docker rm -f eda-${TTY[$1]} >/dev/null 2>&1; sleep 1; }
shot() {
  osascript -e "tell application \"Terminal\" to set index of window id ${WID[$1]} to 1" >/dev/null; sleep 1
  screencapture -x -o -l ${WID[$1]} $SH/$2.png
}
closeall() {
  for n in ${(k)WID}; do stop $n; osascript -e "tell application \"Terminal\" to close (window id ${WID[$n]}) saving no" >/dev/null 2>&1; done
  WID=(); TTY=(); sleep 1
}
C="curl -s -X POST localhost:3100"
J="-H 'Content-Type: application/json' -d"

# ---------- Ejercicios 1 y 2 ----------
win "Terminal 1 · api-server" 20 40 700 230
win "Terminal 2 · consumidor A" 20 290 700 230
win "Terminal 3 · consumidor B" 730 290 700 230
win "Terminal 4 · productor (curl)" 730 40 700 230
type_in "Terminal 1 · api-server" "./eda api-server"; sleep 2
type_in "Terminal 2 · consumidor A" "./eda consumer --topic orderCreated"; sleep 2
type_in "Terminal 4 · productor (curl)" "$C/topics/orderCreated $J '{\"order_id\":123,\"total\":49.99}'; echo"; sleep 2
type_in "Terminal 3 · consumidor B" "./eda consumer --topic orderCreated"; sleep 2
type_in "Terminal 4 · productor (curl)" "$C/topics/orderCreated $J '{\"order_id\":124,\"total\":15.50}'; echo"; sleep 2
shot "Terminal 1 · api-server" ej1_api
shot "Terminal 2 · consumidor A" ej1_c1
shot "Terminal 3 · consumidor B" ej1_c2
shot "Terminal 4 · productor (curl)" ej1_curl
# Ejercicio 2: se detienen los dos y se publica
stop "Terminal 2 · consumidor A"; stop "Terminal 3 · consumidor B"
type_in "Terminal 4 · productor (curl)" "docker exec eda-redis redis-cli PUBSUB NUMSUB orderCreated"; sleep 2
type_in "Terminal 4 · productor (curl)" "$C/topics/orderCreated $J '{\"order_id\":125,\"total\":99.00}'; echo"; sleep 2
type_in "Terminal 2 · consumidor A" "clear; ./eda consumer --topic orderCreated"; sleep 4
shot "Terminal 2 · consumidor A" ej2_c1
shot "Terminal 4 · productor (curl)" ej2_curl
closeall

# ---------- Ejercicio 3 tal como viene ----------
win "Terminal 1 · api-server" 20 40 700 200
win "nuevoPedido" 20 260 470 200
win "devolucion" 500 260 470 200
win "consultaStock" 980 260 450 200
win "Productor (curl)" 730 40 700 200
type_in "Terminal 1 · api-server" "./eda api-server"; sleep 2
type_in "nuevoPedido" "./eda consumer --topic nuevoPedido"
type_in "devolucion" "./eda consumer --topic devolucion"
type_in "consultaStock" "./eda consumer --topic consultaStock"; sleep 3
type_in "Productor (curl)" "$C/topics/nuevoPedido $J '{\"pedidoId\":\"A-100\"}'; echo"; sleep 1.5
type_in "Productor (curl)" "$C/topics/devolucion $J '{\"pedidoId\":\"A-100\"}'; echo"; sleep 1.5
type_in "Productor (curl)" "$C/topics/consultaStock $J '{\"sku\":\"CAM-01\"}'; echo"; sleep 2
shot "nuevoPedido" ej3_np; shot "devolucion" ej3_dev; shot "consultaStock" ej3_cs; shot "Productor (curl)" ej3_curl
closeall

# ---------- Ejercicio 3 con la figura corregida ----------
win "Terminal 1 · api-server" 20 40 700 180
win "Inventario · pedido.creado" 20 240 470 180
win "Finanzas · pedido.creado" 500 240 470 180
win "Atención · pedido.creado" 980 240 450 180
win "Inventario · devolucion.registrada" 20 440 470 180
win "Finanzas · devolucion.registrada" 500 440 470 180
win "Productor (curl)" 730 40 700 180
type_in "Terminal 1 · api-server" "./eda api-server"; sleep 2
for n in "Inventario · pedido.creado" "Finanzas · pedido.creado" "Atención · pedido.creado"; do type_in "$n" "./eda consumer --topic pedido.creado"; done
for n in "Inventario · devolucion.registrada" "Finanzas · devolucion.registrada"; do type_in "$n" "./eda consumer --topic devolucion.registrada"; done
sleep 4
type_in "Productor (curl)" "$C/topics/pedido.creado $J '{\"pedidoId\":\"A-100\"}'; echo"; sleep 1.5
type_in "Productor (curl)" "$C/topics/devolucion.registrada $J '{\"pedidoId\":\"A-100\"}'; echo"; sleep 2
shot "Inventario · pedido.creado" ej3b_inv_p; shot "Finanzas · pedido.creado" ej3b_fin_p; shot "Atención · pedido.creado" ej3b_aten_p
shot "Inventario · devolucion.registrada" ej3b_inv_d; shot "Finanzas · devolucion.registrada" ej3b_fin_d; shot "Productor (curl)" ej3b_curl
closeall

# ---------- Ejercicio 4 ----------
docker exec eda-redis redis-cli DEL message:queue >/dev/null
win "Master · consumer -d --master" 20 40 700 260
win "Worker · consumer -d" 730 40 700 260
win "Terminal 3 · api-server" 20 320 700 200
win "Productor (curl) y Redis" 730 320 700 420
type_in "Master · consumer -d --master" "./eda consumer -d --master"; sleep 2
type_in "Worker · consumer -d" "./eda consumer -d"; sleep 2
type_in "Terminal 3 · api-server" "./eda api-server"; sleep 2
type_in "Productor (curl) y Redis" "$C/deferred-exec $J '{\"task_id\":1,\"description\":\"procesar archivos\"}'; echo"; sleep 11
shot "Worker · consumer -d" ej4_w1
stop "Worker · consumer -d"
type_in "Productor (curl) y Redis" "$C/deferred-exec $J '{\"task_id\":2,\"description\":\"generar reporte\"}'; echo"; sleep 1.5
type_in "Productor (curl) y Redis" "$C/deferred-exec $J '{\"task_id\":3,\"description\":\"enviar correo\"}'; echo"; sleep 1.5
type_in "Productor (curl) y Redis" "docker exec eda-redis redis-cli LRANGE message:queue 0 -1"; sleep 2
type_in "Worker · consumer -d" "clear; ./eda consumer -d"; sleep 14
shot "Worker · consumer -d" ej4_w2
stop "Master · consumer -d --master"
type_in "Productor (curl) y Redis" "$C/deferred-exec $J '{\"task_id\":4,\"description\":\"tarea sin master\"}'; echo"; sleep 1.5
type_in "Productor (curl) y Redis" "docker exec eda-redis redis-cli PUBSUB NUMSUB master"; sleep 2
type_in "Productor (curl) y Redis" "docker exec eda-redis redis-cli LRANGE message:queue 0 -1"; sleep 2
shot "Master · consumer -d --master" ej4_master
shot "Productor (curl) y Redis" ej4_curl
closeall
echo listo
