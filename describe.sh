#!/bin/bash
SALIDA="./instancias.txt"



while read p; do
 echo $(aws ec2 describe-instances --instance-ids $p | \
 jq -r '.Reservations[].Instances[].Tags[].Value, .Reservations[].Instances[].PublicIpAddress') $p 
 done < $SALIDA
