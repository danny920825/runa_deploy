#!/bin/bash

#Ubicacion del archivo que contiene las instancias
file=data.txt

#Cantidad maxima de instancias a mantener durante el periodo bajo
max=4

#Archivo del Log
registro="/var/log/swarm/monitor.log"

stop() {
  echo " Horario de Apagado de instancias por ahorro de recursos" >> $registro
  printf -v WRK_EXP 'worker[1-%i]' "${max}"
  while read -rs INST; do
    aws ec2 stop-instances --instance-ids ${INST}
    echo "Apagando instancia: ${INST} por horario" >> $registro
  done < <(grep -i "worker" ${file} | grep -Eiv "${WRK_EXP}" | cut -d " " -f3)
}

start() {
  echo " Horario de Encendido de instancias por ahorro de recursos" >> $registro
  printf -v WRK_EXP 'worker[%i-%i]' "$(expr ${max} + 1)" "$(grep -ci worker ${file})"
  while read -rs INST; do
    aws ec2 start-instances  --instance-ids ${INST}
    echo "Encendiendo instancia: ${INST} por horario" >> $registro
  done < <(grep -i "worker" ${file} | grep -Eiv "${WRK_EXP}" | cut -d " " -f3)
}

case $1 in
  start|stop)
    $1
    ;;
  *)
    echo "Argumentos Validos: start|stop"
    exit 1
    ;;
esac
