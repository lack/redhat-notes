#!/bin/bash

interruption="hardreset"
iterations=20

interrupt() {
  local how=$1
  echo "----------------------------------------------"
  echo "Interrupting via $how"
  case $how in
    reboot)
      ssh core@$NODEIP sudo systemctl reboot
      ;;
    hardreset)
      sudo /opt/dell/srvadmin/sbin/racadm -r $RACIP -u root -p $RACPASSWORD serveraction hardreset
      ;;
    *)
      exit 0
  esac
  echo "----------------------------------------------"
}

iterate() {
  local how=$1; shift
  local log=$how/$1.log
  echo "=============================================="
  echo "Running iteration $log"
  (./waitForReplicas.sh |& tee $log)&
  waitpid=$!
  sleep 5
  interrupt $how
  wait $waitpid
  echo "=============================================="
}

i=0
while [[ $((i++)) -lt $iterations ]]; do
  iterate $interruption $i
done
