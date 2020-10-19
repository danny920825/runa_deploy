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
OPT="UserKnownHostsFile=/dev/null,StrictHostKeyChecking=no"
retry scp -vo "${OPT}" data.txt run-stop.sh ubuntu@${HOST}:/home/ubuntu/
retry ssh -vo "${OPT}" ubuntu@${HOST} "sudo cp /home/ubuntu/run-stop.sh /data/tools/"
echo "Listo. Terminado con exito"
