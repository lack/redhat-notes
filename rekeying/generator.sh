#!/bin/bash

log() {
  echo "$@" >&2
}

declare -A tang_servers
if [[ $TANG_SERVERS ]]; then
  servers=($TANG_SERVERS)
  i=0
  while [[ $i -lt ${#servers[*]} ]]; do
    url=${servers[((i++))]}
    thp=${servers[((i++))]}
    tang_servers[$url]="$thp"
    log "Added tang server $url ($thp)"
  done
else
  log "Using example servers"
  log 'To specify others, export TANG_SERVERS="http://tangserver01:7500 thumbprint1 ..."'
  tang_servers['http://tangserver01:7500']='tang-thumbprint-1'
  tang_servers['http://tangserver02:7500']='tang-thumbprint-2'
  tang_servers['http://tangserver03:7500']='tang-thumbprint-3'
fi

indented_list() {
  if [[ $# -le 1 ]]; then
    printf "%s" "$1"
    return 0
  fi

  printf "\n"
  local first=1
  for item in "$@"; do
    if [[ $first ]]; then
      unset first
    else
      printf ',\n'
    fi
    local indented=$(pr -to 2 <<<"$item")
    printf "%s" "$indented"
  done
  printf '\n'
}

tang_config() {
  local url=$1
  local thp=$2
  printf '{"url":"%s","thp":"%s"}\n' $url $thp
}

tang_pin() {
  local tang_configs=()
  for server in "${!tang_servers[@]}"; do
    tang_configs+=("$(tang_config "$server" "${tang_servers[$server]}")")
  done
  printf '"tang":['
  indented_list "${tang_configs[@]}"
  printf ']\n'
}

tpm2_pin() {
  printf '"tpm2":[{}]\n'
}

sss_config() {
  local t=$1; shift

  printf '{"t":%s,"pins":{' $t
  indented_list "$@"
  printf '}}\n'
}

sss_pin() {
  local t=$1; shift
  printf '"sss":[%s]' "$(sss_config $t "$@")"
}

generate_yaml() {
  local type="$1"
  local pin_name="$2"
  local pin="$3"
  NAME="rekey-$pin_name" PIN="$pin" bash $type-template.sh
}

write_yaml() {
  local type="$1"
  local pin_name="$2"
  local pin="$3"
  generate_yaml "$type" "$pin_name" "$pin" > $type-$pin_name.yaml
  log "Generated $type-$pin_name.yaml"
}

declare -A pins
pins[tang]="$(sss_config 1 "$(tang_pin)")"
pins[tpm2]="$(sss_config 1 "$(tpm2_pin)")"
pins[tpm2-plus-tang]="$(sss_config 2 "$(tpm2_pin)" "$(sss_pin 1 "$(tang_pin)")")"

for t in "daemonset" "job"; do
  for p in "${!pins[@]}"; do
    write_yaml "$t" "$p" "${pins[$p]}"
  done
done
