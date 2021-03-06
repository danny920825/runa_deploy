#!/bin/bash

MANAGER=1
WORKER=1
TIPO="t2.micro"
AMI="ami-0bbe28eb2173f6167"
SALIDA="instancias.txt"
TIME=100

#Funciones
countdown() {
  secs=${1#0}
  while [ $secs -gt 0 ]; do
    sleep 1 &
    printf "\r%02i" $secs
    secs=$(expr $secs - 1 )
    wait
  done
  echo
}



#Creacion del lider
aws ec2 run-instances --image-id ${AMI} --count 1 --instance-type ${TIPO} --key-name ALD --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Lider}]" --user-data "file://lider.txt" --security-group-ids sg-1d736579 | jq -r '.Instances[] | .InstanceId ' | tee -a ${SALIDA}
#Tiempo prudencial para que se cree El Lider y el Swarm
echo "Esperando a que el lider y el Swarm se creen con exito" 
countdown $TIME




#Creacion de los managers
for c in $(seq 1 ${MANAGER}); do
aws ec2 run-instances  --image-id $AMI  --count 1  --instance-type $TIPO  --key-name ALD  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Manager${c}}]" --user-data "file://manager.txt" --security-group-ids sg-1d736579 | jq -r '.Instances[] | .InstanceId ' | tee -a $SALIDA
echo "Tiempo prudencial para que se cree Manager${c}"
countdown $TIME
done


#Creacion de los Workers
for c in $(seq 1 ${WORKER}); do
aws ec2 run-instances  --image-id $AMI  --count 1  --instance-type $TIPO  --key-name ALD  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=WORKER${c}}]" --user-data "file://workers.txt" --security-group-ids sg-1d736579 | jq -r '.Instances[] | .InstanceId '  | tee -a $SALIDA
echo "Tiempo prudencial para que se cree Worker${c}"
countdown $TIME
done
clear




#Proceso de descripcion de instancias y subida del archivo con los ID al Lider para el crontab
echo "Buscando IP de las Instancias..."
while read p; do
 echo $(aws ec2 describe-instances --instance-ids $p | \
 jq -r '.Reservations[].Instances[].Tags[].Value, .Reservations[].Instances[].PublicIpAddress') $p >> data.txt
done < $SALIDA



retry() {
  local cnt=0
  until "${@}"; do
    cnt=$(expr ${cnt} + 1)
    echo "Intento: ${cnt}"
    sleep 1
  done
  echo "Comando completado exitosamente, al intento # ${cnt}."
  echo
}
echo "Subiendo los archivos..."

HOST=$(grep -i lider data.txt | cut -d " " -f2)
#OPTS='-i "ALD.pem" -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no"'
retry scp -i "ALD.pem" -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" data.txt run-stop.sh ubuntu@${HOST}:/home/ubuntu/
CMD="sudo cp /home/ubuntu/run-stop.sh /data/tools/ && sudo crontab -l 2> /dev/null | tee /var/tmp/cron > /dev/null && echo '30 7 * * * bash /data/tools/run-stop.sh start' | sudo tee -a /var/tmp/cron > /dev/null && echo '00 13 * * * bash /data/tools/run-stop.sh stop' | sudo tee -a /var/tmp/cron > /dev/null && cat /var/tmp/cron | sudo crontab - && rm /var/tmp/cron"
retry ssh -i "ALD.pem" -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" ubuntu@${HOST} "${CMD}"
if [ $? -eq 0 ]; then
  echo "Listo. Terminado con exito"
else
  echo "Ocurrieron errores al ejecutar los comandos remotos."
fi
