#! /bin/sh
servicio="runa_runacode"
multiplicador=5
registro="/var/log/swarm/monitor.log"

valor=$(docker service ls --filter "name=${servicio}" --format "{{.Replicas}}" | cut -d / -f2)

dimension=$(expr $(docker node ls --filter "role=worker" --format "{{.Status}}" | grep -ci "Ready") \* ${multiplicador})

if [ ${dimension} -ne ${valor} ]; then
  docker service scale "${servicio}=${dimension}"
  if [ $? -eq 0 ]; then
    echo "$(date +%F_%H%M-%S) Dimensionado a ${dimension} exitoso." | tee -a "${registro}"
  else
    echo "$(date +%F_%H%M-%S) Ocurrió un error grave en el dimensionamiento. Revisa." | tee -a "${registro}"
  fi
  else
    echo "$(date +%F_%H%M-%S) Workers: $(docker node ls --filter 'role=worker' --format '{{.Status}}' | grep -ci 'Ready'). Dimension: ${dimension}" | tee -a "${registro}"
fi

exit
