#!/bin/bash

allrc() {
  oc get rc -o jsonpath='{range .items[*]}{.metadata.name} {.status.replicas} {.status.readyReplicas}{"\n"}{end}' 2>&1
}

fail() {
  return 12
}

LAST="===GARBAGE==="
different() {
  local this="$1"
  if [[ "$this" != "$LAST" ]]; then
    LAST="$this"
    return 0
  fi
  return 1
}

allReady() {
  local raw output retval=0
  raw=$(allrc)
  if [[ $? -ne 0 ]]; then
    output=$raw
    retval=2
  else
    while read name expected ready; do
      if [[ -z $ready ]]; then
        ready=0
      fi
      line=$(printf "%s has %s/%s" "$name" "$ready" "$expected")
      if [[ -z $output ]]; then
        output=$line
      else
        output=$(printf "%s\n%s" "$output" "$line")
      fi
      if [[ $ready -lt $expected ]]; then
        retval=1
      fi
    done <<<$raw
  fi
  if different "$output"; then
    echo "--------------------------"
    date
    echo "$output"
  fi
  return $retval
}

echo "Waiting for replicas to go offline..."
time (while allReady; do
  sleep 10
done)
echo
echo "Waiting for replicas to come back..."
time (while ! allReady; do
  sleep 10
done)
echo
echo "Double-checking that they're really back..."
time (sleep 30
while ! allReady; do
  sleep 10
done)
echo
echo "Done!"
