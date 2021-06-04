#!/bin/bash

declare -A TANG_SERVERS
TANG_SERVERS['http://10.46.55.192:7500']='aweILXiRhPQoVUP37pwUA5RFThM'
TANG_SERVERS['http://10.46.55.192:7501']='I5Ynh2JefoAO3tNH9TgI4obIaXI'
TANG_SERVERS['http://10.46.55.192:7502']='38qWZVeDKzCPG9pHLqKzs6k1ons'

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
  for server in "${!TANG_SERVERS[@]}"; do
    tang_configs+=("$(tang_config "$server" "${TANG_SERVERS[$server]}")")
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
